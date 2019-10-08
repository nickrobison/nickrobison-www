open Core_kernel
open Async_kernel
open Incr_dom

module Graphs = Map.Make(String)


module Model = struct
  type t = {
    hello: string;
    start_time: string option;
    metrics: Graph.Model.t Graphs.t;
  } [@@deriving sexp, fields, compare]

  let cutoff m1 m2 = compare m1 m2 = 0

  let set_hello model new_hello =
    {model with hello = new_hello}

  let add_graph map title =
    Graphs.add_exn map ~key:title ~data:(Graph.create title)

  let initialize_model model (stats_init: Api.stats_init) =
    let start = Time_ns.Span.of_int_sec (int_of_float stats_init.start) in
    let metrics = List.fold
        stats_init.metrics
        ~init:model.metrics
        ~f:(fun acc m -> add_graph acc m)
    in
    let st = Time_ns.of_span_since_epoch start in
    {model with start_time = (Some (Time_ns.to_string st)); metrics = metrics}

end


module Action = struct
  type t = SetHello of string
         | Initialize of Api.stats_init
  [@@deriving sexp]
end

module State = struct
  type t = unit
end

let apply_action model action _ ~schedule_action:_ =
  match (action: Action.t) with
  | SetHello hello -> Model.set_hello model hello
  | Initialize init -> Model.initialize_model model init

let on_startup ~schedule_action _model =
  schedule_action (Action.SetHello "Started up");
  Api.fetch_stats_init ()
  >>| fun stats -> schedule_action (Action.SetHello "Done fetching");
  match stats with
  | Some s -> print_endline (string_of_float s.start);
    schedule_action (Action.Initialize s)
  | None -> print_endline "Nothing"

let view (model: Model.t Incr.t) ~inject:_ =
  let open Vdom in
  let open Incr.Let_syntax in
  let%map hello = model >>| Model.hello
  and start = model >>| Model.start_time
  and metrics =
    Incr.Map.mapi' (model >>| Model.metrics)
      ~f:(fun ~key:_ ~data ->
          let%map view = Graph.view data
          in view)
  in
  let since = match start with
    | Some s -> Node.text s
    | None -> Node.text ""
  in
  let now = Luxon.local () in
  let main_div = [
    Node.h3 [] [Node.text "Blog stats"];
    Node.div[] [Node.text hello];
    Node.div [] [since];
    Node.div [][Node.text (Luxon.to_string now)]
  ] @ (Graphs.data metrics)
  in
  Node.body [] main_div

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
    start_time = None;
    metrics = Graphs.empty
  }
