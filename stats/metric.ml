open Core_kernel
open Incr_dom

module Model = struct
  type t = {
    name: string;
    chart: C3.Line.t;
  } [@@deriving fields, sexp, compare]

  let create name =
    let chart = C3.Line.make ~kind:`Timeseries ~x_format:"%m/%d" () in
    {name; chart}
end

module Action = struct
  type t = unit

end


let view
    (m: Model.t Incr.t)
    name
  =
  let open Vdom in
  let open Incr.Let_syntax in
  let%map chart = m >>| Model.chart in
  let _chart = C3.Line.render chart ~bindto:("chart-" ^ name) in
  Node.div []
    [
      Node.h3 [] [Node.text ("Metric: " ^ name)];
      Node.div [Attr.id ("chart-" ^ name)] [];
    ]

