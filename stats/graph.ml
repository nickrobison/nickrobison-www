open! Core_kernel
open! Incr_dom
open Incr.Let_syntax

module Model = struct
  type t = {
    title: string;
    graph: C3.Line.display option;
  } [@@deriving compare, fields, sexp]

  let cutoff _m1 _m2 = true

  let make_chart m =
    C3.Line.make ~kind:`Timeseries ~x_format:"%Y-%m-%d %H:%M:%S" ()
    |> C3.Line.render ~bindto:("#" ^ (m.title) ^ "-chart")

  let update_graph model update =
    print_endline ("Updating " ^ model.title);
    let chart = match model.graph with
      | None -> make_chart model
      | Some c -> c
    in
    C3.Line.update ~segments:[
      C3.Segment.make ~label:"Test" ~points:update ~kind:`Area_spline ()
    ] chart;
    {model with graph = (Some chart)}

end

module Action = struct
  type t =
      UpdateGraph of (float * float) list [@@deriving sexp]
end

let apply_action action model =
  match (action: Action.t) with
  | UpdateGraph u -> Model.update_graph model u

let view
    (m: Model.t Incr.t) =
  let open Vdom in
  let style = Css_gen.of_string_css_exn "height: 400px;" in
  let%map title = m >>| Model.title in
  Node.div [] [
    Node.h3 [] [Node.text title];
    Node.div [Attr.id (title ^ "-chart"); Attr.style style] []
  ]

let create title: Model.t =
  {
    title;
    graph = None
  }

