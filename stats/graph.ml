open! Core_kernel
open! Incr_dom
open Incr.Let_syntax

module Model = struct
  type t = {
    title: string
  } [@@deriving compare, fields, sexp]

end

module Action = struct
  type t = unit [@@deriving sexp]
end

let view
    (m: Model.t Incr.t) =
  let open Vdom in
  let%map title = m >>| Model.title in
  Node.div [] [
    Node.text title
  ]

let create title: Model.t =
  {title}

