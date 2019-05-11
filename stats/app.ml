open Core_kernel
open Async_kernel
open Incr_dom

module Model = struct
  type t = {
    timescales: string list;
    selected_scale: string;
    metrics: string list;
    (**
       rrds: Rrd_updates.t String.Map.t;**)
  } [@@deriving sexp, fields, compare]

  let cutoff m1 m2 = compare m1 m2 = 0

  (**let update_data model (data: Rrd_updates.t) =

     let t = List.foldi data ~init:model.rrds ~f:(fun _ map rrd -> String.Map.set map ~key:"hello" ~data:rrd)
     in
       {model with rrds = t}
      model**)

  let set_timescales model scales =
    {model with timescales = scales}

  let select_timescale model scale =
    {model with selected_scale = scale}
end

module State = struct
  type t = unit
end

module Action = struct
  type t = SetTimescales of string list
         | SelectTimescale of string [@@deriving sexp]
end

let apply_action model action _ ~schedule_action:_ =
  match (action: Action.t) with
  (**| Refresh data -> Model.update_data model data**)
  | SetTimescales scales -> Model.set_timescales model scales
  | SelectTimescale scale -> Model.select_timescale model scale


let on_startup ~schedule_action _model =
  every (Time_ns.Span.of_sec 10.) (fun () ->
      print_endline "Fetching again";
      let open Lwt.Infix in
      let _ = Fetch.fetch_rrd_updates () >>= fun res ->
        Lwt.return (match res with
            | Ok _r -> print_endline ("Printing: " ^ "hello");
              (**schedule_action (Action.SetTimescales ["test"; "from"; "other"])*)
            | Error e -> print_endline "Error"; print_endline e)
      in
      ());

     let open Lwt.Infix in
     let _ = Fetch.fetch_timescales () >>= fun res ->
       Lwt.return (match res with
           | Ok r -> print_endline ("Named: ");
             schedule_action
               (Action.SetTimescales (List.map r ~f:(fun ts -> ts.name)))
           | Error e -> print_endline "Error"; print_endline e)
     in
     ();


  Deferred.unit

let view (model: Model.t Incr.t) ~inject:_ =
  let open Vdom in
  let open Incr.Let_syntax in
  let%map scales = model >>| Model.timescales in
  print_endline "Updating";
  let selections = Node.select []
      (List.map scales ~f:(fun name ->
           Node.option
             [Attr.value name]
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
    metrics = ["something"; "basic"];
    selected_scale = "minute";
    timescales = [];
  }

