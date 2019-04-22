open Core_kernel
open Async_kernel
open Incr_dom
open !Incr.Let_syntax

module Model = struct
  type t = unit

  let cutoff _ _ = true

  (**
      XmlHttpRequest.get uri >>= fun frame ->
      if frame.code == 200
      then return frame.content
      else print_endline "Fail"
  *)


  let fetch_data model =
    let open Lwt.Infix in
    let _ = Fetch.do_get ~uri:(Uri.make ~path:"/stats/ok" ()) >>= fun text -> print_endline text; Lwt.return_unit in
    model

end

module State = struct
  type t = unit
end

module Action = struct
  type t = Refresh [@@deriving sexp_of]
end

let apply_action model action _ ~schedule_action:_ =
  match (action: Action.t) with
  | Refresh -> Model.fetch_data model

let initial_model: Model.t =
  ()




let on_startup ~schedule_action _model =
  every (Time_ns.Span.of_sec 1.) (fun () -> schedule_action Action.Refresh);
  Deferred.unit

let create model ~old_model:_ ~inject:_ =
  let open Incr.Let_syntax in
  let%map model = model in
  let apply_action = apply_action model in
  let view =
    let open Vdom in
    Node.div
      []
      [ Node.h3 [] [Node.text "Hello from Ocaml"]]
  in
  Component.create ~apply_action model view


(*
  let open Vdom in
  let%map model = model in
  let apply_action action _ ~schedule_action:_ = Nothing.unreachable_code action in
  let view = 
    Node.body
      []
      [ Node.h3 [] [Node.text "Hello from Incr dom"]] in
  Component.create ~apply_action model view
*)
