open Core_kernel
open Async_kernel
open Incr_dom

module Model = struct
  type t = {
    metrics: string list;
    rrds: Rrd_updates.t String.Map.t;
  }

  let cutoff _ _ = true

  let update_data model data =
    let t = List.foldi data model.rrds ~f:(fun i map rrd -> String.Map.set map ~key:"hello" ~data:rrd)
    in
    {model with rrds = t}

  (**
     Fetch.fetch_rrd_updates () >>= fun rrd ->
     let _tst = Lwt.return (match rrd with
      | Ok (res: Fetch.rrd_update) -> res.meta.start
      | Error e -> print_endline e; 0)
     in

     Lwt.return_unit
     in
  *)

end

module State = struct
  type t = unit
end

module Action = struct
  type t = Refresh of Rrd_updates.t list
end

let apply_action model action _ ~schedule_action:_ =
  match (action: Action.t) with
  | Refresh data -> Model.update_data model data

let initial_model: Model.t =
  {
    metrics = ["something"; "basic"];
    rrds = String.Map.empty;
  }

let on_startup ~schedule_action _model =
  every (Time_ns.Span.of_sec 10.) (fun () ->
      let open Lwt.Infix in
      let _ = Fetch.fetch_rrd_updates () >>= fun res ->
        Lwt.return (match res with
            | Ok r -> print_endline ("Printing: " ^ (Int64.to_string r.step));
              schedule_action (Action.Refresh res);
            | Error e -> print_endline "Error"; print_endline e)
      in
      ());
  Deferred.unit

let view (model: Model.t) =
  let open Vdom in
  Node.div
    []
    [
      Node.h3 [] [Node.text "Blog Stats"];
      Node.select []
        (List.map model.metrics ~f:(fun name -> Node.option [Attr.value name] [Node.text name]));
      Node.div []
        [
          Node.section [] [];
          Node.h4 [] [Node.text "Section 1"];
          Node.section [] [];
          Node.h4 [] [Node.text "Section 2"];
        ];
    ]

let create model ~old_model:_ ~inject:_ =
  let open Incr.Let_syntax in
  let%map model = model in
  let apply_action = apply_action model in
  let view = view model
  in
  Component.create ~apply_action model view
