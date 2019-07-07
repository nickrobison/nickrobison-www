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
    {model with legends = data.meta.legend}

  let set_timescales model scales =
    {model with timescales = scales}

  let select_timescale model (scale: Fetch.rrd_timescale) =
    print_endline ("Selected: " ^ scale.name);
    {model with selected_scale = scale}
end

module State = struct
  type t = unit
end

module Action = struct
  type t = RefreshData of Fetch.rrd_update
         | SetTimescales of Fetch.rrd_timescale_resp
         | SelectTimescale of Fetch.rrd_timescale [@@deriving sexp]
end

let apply_action model action _ ~schedule_action:_ =
  match (action: Action.t) with
  | RefreshData data -> Model.update_data model data
  | SetTimescales scales -> Model.set_timescales model scales
  | SelectTimescale scale -> Model.select_timescale model scale

let interval_to_span steps =
  steps * 5

let to_span intervals steps =
  intervals * steps * 5

let on_startup ~schedule_action model =
  every (Time_ns.Span.of_sec 10.) (fun () ->
      print_endline "Fetching again";
      let open Lwt.Infix in
      let selected  = Model.selected_scale model in
      let start = to_span selected.num_intervals selected.interval_in_steps in
      let span = interval_to_span selected.num_intervals in
      let _ = Fetch.fetch_rrd_updates ~start:(string_of_int start) ~interval:(string_of_int span) >>= fun res ->
        Lwt.return (match res with
            | Ok r -> print_endline ("Printing: " ^ (string_of_int r.meta.step));
              schedule_action (Action.RefreshData r);
            | Error e -> print_endline "Error"; print_endline e)
      in
      ());

  let open Lwt.Infix in
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
  print_endline "Updating";
  let selections = Node.select [
    ]
      (List.map scales ~f:(fun scale ->
           let name = scale.name in
           Node.option
             [
               Attr.value name;
               Attr.on_click (fun _ev -> inject (Action.SelectTimescale scale));
             ]
             [Node.text name]
         ))
  in
  Node.body [] [
    Node.h3 [] [Node.text "Blog Stats"];
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

