open Core_kernel
open Async_kernel
open Incr_dom

module Graphs = Map.Make(String)

module Action = struct
  type t = SetHello of string
         | Initialize of Api.stats_init
         | UpdateData of Api.rrd_update option
         | RefreshData
         | SetTimescales of Api.rrd_timescale list
         | SelectTimescale of string
  [@@deriving sexp]
end

module Model = struct
  type t = {
    hello: string;
    start_time: string option;
    metrics: Graph.Model.t Graphs.t;
    timescales: Api.rrd_timescale String.Map.t;
    selected_timescale: Api.rrd_timescale option;
  } [@@deriving sexp, fields, compare]

  let cutoff m1 m2 = compare m1 m2 = 0

  let set_hello model new_hello =
    {model with hello = new_hello}

  let set_timescales model timescales =
    let timescales' = List.fold timescales ~init:String.Map.empty ~f:(fun map (t: Api.rrd_timescale) -> Map.set map ~key:t.name ~data:t) in
    {model with timescales = timescales'}

  let select_timescale model name =
    print_endline "Selecting.";
    match (Map.find model.timescales name) with
    | Some s -> {model with selected_timescale = (Some s)}
    | None -> print_endline ("No timescale with name: " ^ name); model

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

  let update_map map key new_value =
    match (Map.find map key) with
    | Some v -> Map.set map ~key:key ~data:(new_value :: v)
    | None -> Map.set map ~key:key ~data: [new_value]

  let transform_row columns map (row: Api.rrd_data) =
    List.foldi row.values ~init:map ~f:(fun idx m value ->
        List.nth columns idx
        |> function
        | None -> m
        | Some c -> update_map m c (Float.of_int(row.t), value))

  let split_legend legend =
    let splits = Stringext.cut ~on:":" legend
                 |> function
                 | None -> raise (Invalid_argument "Nope")
                 | Some s -> s
    in
    ((fst splits), (snd splits))

  let apply_graph_action m row_id (action: Graph.Action.t) =
    let row_id = (snd (split_legend row_id)) in
    let graphs = Graphs.change m.metrics row_id ~f:(function
        | None -> None
        | Some g -> Some (Graph.apply_action action g))
    in
    {m with metrics = graphs}


  let handle_updates model updates =
    match updates with
    | None -> model
    | Some (u: Api.rrd_update) ->
      let legends = List.slice u.meta.legend 0 4 in
      List.iter legends ~f:(fun l -> print_endline l);
      let transformer = transform_row legends in
      let legend_map  = String.Map.empty in
      let values = List.fold u.data ~init:legend_map ~f:transformer in
      Map.fold values  ~init:model ~f:(fun ~key ~data graph ->
          apply_graph_action graph key (Graph.Action.UpdateGraph data))

  let refresh_data model schedule_action =
    print_endline "Fetching updates";
    let fetch = match model.selected_timescale with
      | None -> Api.fetch_updates ~start:0 ~interval:0
      | Some t -> Api.fetch_updates ~start:(-(Api.rrd_timescale_to_span t) + 1) ~interval:(Api.interval_to_span t)
    in
    Deferred.upon (fetch ()) (fun u ->
        print_endline "Fetched";
        schedule_action (Action.UpdateData u));
    model

end

module State = struct
  type t = unit
end

let apply_action model action _ ~schedule_action =
  match (action: Action.t) with
  | SetHello hello -> Model.set_hello model hello
  | Initialize init -> Model.initialize_model model init
  | RefreshData -> (Model.refresh_data model schedule_action)
  | UpdateData data -> (Model.handle_updates model data)
  | SetTimescales options -> (Model.set_timescales model options)
  | SelectTimescale name -> (Model.select_timescale model name)

let on_startup ~schedule_action _model =
  every (Time_ns.Span.of_sec 5.) (fun () ->
      schedule_action (Action.RefreshData));
  schedule_action (Action.SetHello "Started up");

  Api.fetch_stats_init ()
  >>= fun stats ->
  ( match stats with
    | Some s -> print_endline (string_of_float s.start);
      schedule_action (Action.Initialize s)
    | None -> print_endline "Nothing";
      schedule_action (Action.SetHello "Done fetching"));
  Api.fetch_timescales ()
  >>| fun resp ->
  match resp with
  | Some r -> schedule_action (Action.SetTimescales r)
  | None -> print_endline "Could not fetch timescales"

let view (model: Model.t Incr.t) ~inject =
  let open Vdom in
  let open Incr.Let_syntax in
  let%map hello = model >>| Model.hello
  and start = model >>| Model.start_time
  and timescales =
    Incr.Map.mapi (model >>| Model.timescales)
      ~f:(fun ~key:_ ~(data:Api.rrd_timescale) ->
          Node.option [Attr.id data.name] [Node.text data.name])
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
  let options = Map.data timescales in
  let select = Node.select [Attr.on_change (fun _ev value -> inject (Action.SelectTimescale value))] options in
  let now = Luxon.local () in
  (*Create the app layout*)
  let header = Node.div [Attr.classes ["row"; "expanded"; "app-dashboard-top-nav-bar"]]
      [
        Node.div [Attr.classes ["columns"; "medium-2"]] [
          Node.a [Attr.classes ["app-dashboard-logo"]] [
            Node.text "Stats Dashboard"
          ]
        ]
      ]
  in
  let sidebar = Node.div [Attr.id "app-dashboard-sidebar"; Attr.classes ["app-dashboard-sidebar"; "positiion-left"; "off-canvas"; "off-canvas-absolute"; "reveal-for-medium"]] [
      Node.div [Attr.classes ["app-dashboard-sidebar-title-area"]] [
        Node.h3 [Attr.classes ["app-dashboard-sidebar-block-title"]]
          [Node.text "Sidebar"]
      ]
    ]
  in
  let graphs = Node.div [] (Graphs.data metrics) in
  let body = Node.div [Attr.classes [
      "app-dashboard-body-content";
      "off-canvas-content"
    ];
    ] [
      Node.h3 [] [Node.text "Blog stats"];
      Node.div[] [Node.text hello];
      Node.div [] [since];
      Node.div [][Node.text (Luxon.to_string now)];
      select;
      graphs
    ]
  in
    let main_div = [
    header;
    sidebar;
    body;
  ]
  in
  Node.div [Attr.classes ["app-dashboard"; "shrink-medium"]] main_div

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
    metrics = Graphs.empty;
    timescales = String.Map.empty;
    selected_timescale = None
  }
