open Core_kernel
open Async_kernel
open Incr_dom


module Charts = Map.Make(String)

module Action = struct
  type t = UpdateModel of Fetch.rrd_update
         |RefreshData
         | SetTimescales of Fetch.rrd_timescale_resp
         | SelectTimescale of string [@@deriving sexp]
end


module Model = struct

  type t = {
    timescales: Fetch.rrd_timescale_resp;
    selected_scale: Fetch.rrd_timescale;
    metrics: Fetch.rrd_timescale_resp;
    charts: (float *float) list Charts.t;
    legends: string list;
  } [@@deriving sexp, fields, compare]

  let cutoff m1 m2 = compare m1 m2 = 0

  let interval_to_span steps =
    steps * 5

  let to_span interval steps =
    interval * steps * 5

  let fetch_data model ~schedule_action =
    print_endline "Updating data model";
    print_endline "Fetching updates";
    let open Lwt.Infix in
    let selected  = selected_scale model in
    let span = interval_to_span selected.num_intervals in
    let start = (-(to_span selected.num_intervals selected.interval_in_steps)) + 1 in
    let _ = Fetch.fetch_rrd_updates ~start:(string_of_int start) ~interval:(string_of_int span) >>= fun res ->
      Lwt.return (match res with
          | Ok r -> print_endline ("Printing: " ^ (string_of_int r.meta.step)); schedule_action (Action.UpdateModel r)
          | Error e -> print_endline "Error"; print_endline e)

    in
    ();
    model

  let update_map map key new_value =
    match (Charts.find map key) with
    | Some v -> Map.set map ~key:key ~data:(new_value::v)
    | None -> Map.set map ~key: key ~data:[new_value]

  let transform_row columns map (row: Fetch.rrd_data) =
    List.foldi row.values ~init:map ~f:(fun idx m value -> update_map m (List.nth_exn columns idx) (Float.of_int(row.t), value))

  let transform_data model (data: Fetch.rrd_update) =
    let legends = data.meta.legend
    in
    let transformer = transform_row legends in
    (** iterate through the rows and append the values*)
    List.fold data.data ~init:model.charts ~f:transformer



  let update_data model (data: Fetch.rrd_update) =
    print_endline "Updating model";
    {model with legends = data.meta.legend; charts = (transform_data model data)}


  let set_timescales model scales =
    print_endline "Setting timescales";
    {model with timescales = scales}

  let select_timescale model scale =
    print_endline ("Selected: " ^ scale);
    (** Find the matching scales*)
    match (List.find model.timescales ~f:(fun ts -> String.equal ts.name scale)) with
    | Some ts -> print_endline "found"; {model with selected_scale = ts}
    | None -> model

end

module State = struct
  type t = unit
end

let apply_action model action _ ~schedule_action =
  match (action: Action.t) with
  | UpdateModel data -> Model.update_data model data
  | RefreshData -> Model.fetch_data model ~schedule_action
  | SetTimescales scales -> Model.set_timescales model scales
  | SelectTimescale scale -> Model.select_timescale model scale


let on_startup ~schedule_action _model =
  every (Time_ns.Span.of_sec 10.) (fun () ->
      print_endline "Fetching updates";
      schedule_action (Action.RefreshData)
    );

  let open Lwt.Infix in
  print_endline "Initial timescale fetch";
  let _ = Fetch.fetch_timescales () >>= fun res ->
    Lwt.return (match res with
        | Ok r -> schedule_action
                    (Action.SetTimescales r)
        | Error e -> print_endline "Error"; print_endline e)
  in
  ();
  Deferred.unit



let do_update chart_values chart =
  C3.Line.update ~segments: [ C3.Segment.make ~label:"chart vals" ~points:chart_values ~kind:`Area_step ()] chart

let update_chart chart (values: (float * float) list option) =
  match values with
      | Some v -> do_update v chart
      | None -> ()

let view (model: Model.t Incr.t) ~inject =
  let open Vdom in
  let open Incr.Let_syntax in
  let%map scales = model >>| Model.timescales
  and charts = model >>| Model.charts in
  (** Create one chart, just to test*)
  let chart = C3.Line.make ~kind:`Timeseries ~x_format:"%m/%d" ()
              |> C3.Line.render ~bindto:"#timeseries" in
  let update_chart = update_chart chart in
  Charts.find charts "AVERAGE:live_words"
  |> update_chart;
let selections = Node.select [
    Attr.id "ts-select";
    Attr.on_change (fun _ev value -> inject (Action.SelectTimescale value));
  ]
    (List.map scales ~f:(fun scale ->
         let name = scale.name in
         Node.option
           [
             Attr.value name;
           ]
           [Node.text name]
       ))
in
List.iter (Map.keys charts) ~f:(fun name -> print_endline name);
Node.body [] [
  Node.h3 [] [Node.text "Blog Stats."];
  selections;
  Node.div []
    [
      Node.section [] [];
      Node.h4 [] [Node.text "Section 1"];
      Node.div [Attr.id "timeseries"] [];
      Node.section [] [];
      Node.h4 [] [Node.text "Section 2"];
    ]]

let create model ~old_model:_ ~inject =
  let open Incr.Let_syntax in
  let%map apply_action =
    let%map model = model in
    apply_action model
  and view = view model ~inject
  and model = model
  in
  Component.create ~apply_action model view

let initial_model () : Model.t =
  {
    metrics = [];
    selected_scale = {
      name = "minute";
      num_intervals = 120;
      interval_in_steps = 1;
    };
    charts = Charts.empty;
    timescales = [];
    legends = [];
  }

