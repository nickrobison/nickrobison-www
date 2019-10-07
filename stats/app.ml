open Core_kernel
open Async_kernel
open Incr_dom

module Model = struct
  type t = {
    hello: string
  } [@@deriving sexp, fields, compare]

  let cutoff m1 m2 = compare m1 m2 = 0

  let set_hello _model new_hello =
    {hello = new_hello}
end


module Action = struct
  type t = SetHello of string [@@deriving sexp]
end

module State = struct
  type t = unit
end

let apply_action model action _ ~schedule_action:_ =
  match (action: Action.t) with
  | SetHello hello -> Model.set_hello model hello

let on_startup ~schedule_action _model =
  schedule_action (Action.SetHello "Started up");
  Api.fetch_stats_init () >>| fun _stats -> schedule_action (Action.SetHello "Done fetching");
  ()

let view (model: Model.t Incr.t) ~inject:_ =
  let open Vdom in
  let open Incr.Let_syntax in
  let%map hello = model >>| Model.hello in
  Node.body [] [
    Node.h3 [] [Node.text "Blog stats"];
    Node.div[] [Node.text hello]
  ]

let create model ~old_model:_ ~inject =
  let open Incr.Let_syntax in
  let%map apply_action =
    let%map model = model in
    apply_action model
  and view = view model ~inject
  and model = model
  in
  Component.create ~apply_action model view



let initial_model (): Model.t =
  {
    hello = "";
  }
