open Lwt.Infix

let log_src = Logs.Src.create "stats" ~doc:"Web server statistics"
module Log = (val Logs.src_log log_src: Logs.LOG)


let not_found ~domain x =
  let uri = Site_config.uri domain ("stats" :: x) in
  `Not_found uri

(** Implement health checks*)
let check_ok ~domain =
  let headers = Cowabloga.Headers.html in
  let body = Lwt.return "Site ok" in
  `Page (headers, body)

let timescales = Rrd_timescales.([
    make ~name:"minute" ~num_intervals:120 ~interval_in_steps:1 ();
    make ~name:"hour"   ~num_intervals:120 ~interval_in_steps:12 ();
    make ~name:"day"    ~num_intervals:168 ~interval_in_steps:720 ();
    make ~name:"year"   ~num_intervals:366 ~interval_in_steps:17280 ();
  ])

let create_rras use_min_max =
  Array.of_list (List.flatten
                   (List.map (fun {Rrd_timescales.num_intervals; interval_in_steps; _} ->
                        if interval_in_steps > 1 && use_min_max then [
                          Rrd.rra_create Rrd.CF_Average num_intervals interval_in_steps 1.0;
                          Rrd.rra_create Rrd.CF_Min num_intervals interval_in_steps 1.0;
                          Rrd.rra_create Rrd.CF_Max num_intervals interval_in_steps 1.0;
                        ] else [Rrd.rra_create Rrd.CF_Average num_intervals interval_in_steps 0.5;])
                       timescales))

let step = 5

let total_requests = ref 0

let total_errors = ref 0

module Ds = struct
  type t = {
    name: string;
    description: string;
    value: Rrd.ds_value_type;
    ty: Rrd.ds_type;
    max: float;
    min: float;
    units: string;
  }

  let make ~name ~description ~value ~ty ~units
      ?(min = neg_infinity) ?(max = infinity) () = {
    name; description; value; ty; min; max; units
  }
end

let make_dss stats = [
  Ds.make ~name:"free_words" ~units:"words"
    ~description:"Number of words in the free list"
    ~value:(Rrd.VT_Int64 (Int64.of_int stats.Gc.free_words)) ~ty:Rrd.Gauge ~min:0.0 ();
  Ds.make ~name:"live_words" ~units:"words"
    ~description:"Number of words of live data in the major heap, including the header words."
    ~value:(Rrd.VT_Int64 (Int64.of_int stats.Gc.live_words)) ~ty:Rrd.Gauge ~min:0.0 ();
  Ds.make ~name:"requests_per_second" ~units:"requests/second"
    ~description:"HTTP requests received per second"
    ~value:(Rrd.VT_Int64 (Int64.of_int !total_requests)) ~ty:Rrd.Derive ~min:0.0 ();
  Ds.make ~name:"errors_per_second" ~units:"responses/second"
    ~description:"Unsuccessful HTTP responses per second"
    ~value:(Rrd.VT_Int64 (Int64.of_int !total_errors)) ~ty:Rrd.Derive ~min:0.0 ();
]

let create_fresh_rrd timestamp use_min_max dss =
  Log.info (fun f -> f "Creating fresh RRDs");
  let rras = create_rras use_min_max in
  let dss = Array.of_list (List.map (fun ds ->
      Rrd.ds_create ds.Ds.name ds.Ds.ty ~mrhb:300.0 ~max:ds.Ds.max ~min:ds.Ds.min Rrd.VT_Unknown) dss) in
  let rrd = Rrd.rrd_create dss rras (Int64.of_int step) timestamp in
  rrd

let update_rrds timestamp dss rrd =
  Rrd.ds_update_named rrd timestamp ~new_domid:false
    (List.map (fun ds -> ds.Ds.name, (ds.Ds.value, fun x -> x)) dss)


let rrd, rrd_u = Lwt.task ()
let rrd_created = ref false

let start ~sleep ~time =
  let t () =
    (if !rrd_created then rrd
     else begin
       let timestamp = time () |> Ptime.v |> Ptime.to_float_s in
       let x = create_fresh_rrd timestamp true (make_dss (Gc.stat ())) in
       rrd_created := true;
       Lwt.wakeup rrd_u x;
       rrd
     end) >>= fun rrd ->
    let rec loop () =
      Log.info(fun f -> f "Updating");
      total_requests := !total_requests + 5;
      total_errors := !total_errors + 1;
      Log.info(fun f -> f "Total errors: %d" !total_errors);
      let timestamp = time () |> Ptime.v |> Ptime.to_float_s in
      update_rrds timestamp (make_dss (Gc.stat ())) rrd;
      sleep 5 >>= fun () ->
      loop () in
    loop () in
  Lwt.async t

let page ~read =
  let headers = Cowabloga.Headers.html in
  let body = read "stats.html" in
  `Page (headers, body)

let get_rrd_updates ~uri =
  Log.info(fun f -> f "Getting updates");
  rrd >>= fun rrd ->
  let query = Uri.query uri in
  let get key =
    if List.mem_assoc key query
    then match List.assoc key query with
      | [] -> None
      | x :: _ -> Some x
    else
      None in
  let (>>=) m f = match m with
    | None -> None
    | Some x -> f x in
  let default d = function
    | None -> d
    | Some x -> x
  in
  let int64 x = try Some (Int64.of_string x) with _ -> None in
  let cf x = try Some (Rrd.cf_type_of_string x) with _ -> None in
  let start = default 0L (get "start" >>= int64) in
  let interval = default 0L (get "interval" >>= int64) in
  let cfopt = get "cf" >>= cf in
  (Lwt.return (Rrd_updates.export ~json:true ["", rrd] start interval cfopt))

let get_rrd_timescales () =
  Lwt.return (Rrd_timescales.to_json timescales)

(** Dispatch for URI handlers *)
let dispatch ~read ~domain =
  let f = function
    | [] -> page ~read
    | ["ok"] -> check_ok ~domain
    | x -> not_found ~domain x
  in
  Lwt.return f
