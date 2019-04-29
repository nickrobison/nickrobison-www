open Core_kernel
open Async_kernel
open Incr_dom
open !Incr.Let_syntax

module Model = struct
  type t = int

  let cutoff _ _ = true

  let update_data model _data =
    print_endline "updating model";
    model

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
  type t = Refresh [@@deriving sexp_of]
end

let apply_action model action _ ~schedule_action:_ =
  match (action: Action.t) with
  | Refresh -> Model.update_data model 0

let initial_model: Model.t =
  0

let on_startup ~schedule_action _model =
  every (Time_ns.Span.of_sec 5.) (fun () ->
      let open Lwt.Infix in
      let _ = Fetch.fetch_rrd_updates () >>= fun res ->
        Lwt.return (match res with
        | Ok r -> print_endline (string_of_int r.meta.start); schedule_action Action.Refresh
        | Error e -> print_endline e)
      in
      ());
  Deferred.unit

let view () =
  let open Vdom in
  Node.div
    []
    [Node.h3 [] [Node.text "Ocaml Stats"]]

let create model ~old_model:_ ~inject:_ =
  let open Incr.Let_syntax in
  let%map model = model in
  let apply_action = apply_action model in
  let view = view ()
  in
  Component.create ~apply_action model view
