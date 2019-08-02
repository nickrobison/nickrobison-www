open Core_kernel
open Incr_dom

module Model = struct
  type t = {
    name: string;
    chart: C3.Line.t;
    data: (float * float) list;
    created: bool;
    rendered: C3.Line.display option;
  } [@@deriving fields, sexp, compare]

  let create name =
    let chart = C3.Line.make ~kind:`Timeseries ~x_format:"%m/%d" () in
    {name; chart; data = []; created=false; rendered = None}

  let _render_chart model name =
    let display = C3.Line.render model.chart ~bindto:name
    in
    {model with rendered = (Some display)}

  let _update_data model data =
    {model with data = data}
end

module Action = struct
  type t = UpdateData of (float * float) list
         | RenderChart of string [@@deriving sexp]
end

let view
    (m: Model.t Incr.t)
  =
  let open Vdom in
  let open Incr.Let_syntax in
  let%map model = m in
  let _chart = Model.chart model
  and name = Model.name model in
  let body = Node.div []
      [
        Node.h3 [] [Node.text ("Metric: " ^ name)];
        Node.div [Attr.id ("chart-" ^ name)] [];
      ]
  in
  body
