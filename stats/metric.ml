open Core_kernel
open Incr_dom

module Model = struct
  type t = {
    name: string;
  } [@@deriving fields, sexp, compare]

  let create name =
    {name}
end

module Action = struct
  type t = unit

end


let view
    (m: Model.t Incr.t)
  =
  let open Vdom in
  let open Incr.Let_syntax in
  let%map name = m >>| Model.name in
  Node.div [Attr.id ("chart-" ^ name)]
    [
      Node.h3 [] [Node.text ("Metric: " ^ name)];
    ]

