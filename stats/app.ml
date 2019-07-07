open Core_kernel
open Async_kernel
open Incr_dom

module Model = struct
  type t = {
    timescales: Fetch.rrd_timescale_resp;
    selected_scale: Fetch.rrd_timescale;
    metrics: Fetch.rrd_timescale_resp;
    legends: string list;
  } [@@deriving sexp, fields, compare]

  let cutoff m1 m2 = compare m1 m2 = 0

  let update_data model (data: Fetch.rrd_update) =
    print_endline "Updating data model";
    {model with legends = data.meta.legend}

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

module Action = struct
  type t = RefreshData of Fetch.rrd_update
         | SetTimescales of Fetch.rrd_timescale_resp
         | SelectTimescale of string [@@deriving sexp]
end

let apply_action model action _ ~schedule_action:_ =
  match (action: Action.t) with
  | RefreshData data -> Model.update_data model data
  | SetTimescales scales -> Model.set_timescales model scales
  | SelectTimescale scale -> Model.select_timescale model scale

let interval_to_span steps =
  steps * 5

let on_startup ~schedule_action model =
  let start = Time.now () in
  let start_span = Time.to_span_since_epoch start in
  every (Time_ns.Span.of_sec 10.) (fun () ->
      print_endline "Fetching updates";
      let open Lwt.Infix in
      let selected  = Model.selected_scale model in
      let span = interval_to_span selected.num_intervals in
      let _ = Fetch.fetch_rrd_updates ~start:(string_of_float (Time.Span.to_sec start_span)) ~interval:(string_of_int span) >>= fun res ->
        Lwt.return (match res with
            | Ok r -> print_endline ("Printing: " ^ (string_of_int r.meta.step));
              schedule_action (Action.RefreshData r);
            | Error e -> print_endline "Error"; print_endline e)
      in
      ());

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

let view (model: Model.t Incr.t) ~inject =
  let open Vdom in
  let open Incr.Let_syntax in
  let%map scales = model >>| Model.timescales in
  print_endline "Updating scales";
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
  Node.body [] [
    Node.h3 [] [Node.text "Blog Stats."];
    selections;
    Node.div []
      [
        Node.section [] [];
        Node.h4 [] [Node.text "Section 1"];
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
    timescales = [];
    legends = [];
  }

