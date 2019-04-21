open Core_kernel
open Async_kernel
open Incr_dom
open !Incr.Let_syntax

module Model = struct
  type t = unit

  let cutoff _ _ = true
end

module State = struct
  type t = unit
end

module Action = struct
  type t = Nothing.t [@@deriving sexp_of]
end


let initial_model: Model.t =
  ()

let on_startup ~schedule_action:_ _model =
  Deferred.unit

let create model ~old_model:_ ~inject:_ =
  let open Incr.Let_syntax in
  let%map model = model in
  let apply_action action _ ~schedule_action:_ = Nothing.unreachable_code action in
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
