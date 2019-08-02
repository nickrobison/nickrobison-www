open Lwt.Infix
open Js_of_ocaml_lwt
open Core_kernel

type stats_init = {
  start: float;
  metrics: string list;
} [@@deriving yojson, sexp]

type rrd_meta = {
  start: int;
  rows: int;
  columns: int;
  step: int;
  en: int [@key "end"];
  legend: string list;
} [@@deriving yojson, sexp]

type rrd_data = {
  t: int;
  values: float list;
} [@@deriving yojson, sexp]

type rrd_update = {
  meta: rrd_meta;
  data: rrd_data list;
} [@@deriving yojson {strict = false}, sexp]

type rrd_timescale = {
  name: string;
  num_intervals: int;
  interval_in_steps: int;
} [@@deriving yojson, sexp, compare]

type rrd_timescale_resp = Rrd_timescales.t list [@@deriving yojson, sexp, compare]

let rrd_from_json f content =
  let safed = Yojson.Safe.from_string content
  |> f in
  match safed with
  | Ok r -> r
  | Error e -> raise (Invalid_argument e)

let do_get ~uri f =
  let uri = Uri.to_string uri in
  let open XmlHttpRequest in
  get uri >>= fun (frame) ->
  match frame.code with
  | 200 -> Lwt.return_ok (f frame.content)
  | _ -> Lwt.return_error "Error!"

let fetch_rrd_updates ~start ~interval =
  let rrd_from_json = rrd_from_json rrd_update_of_yojson in
  let query = ["start", [start]; "interval", [interval]] in
  let uri = (Uri.make ~path:"/rrd_updates" ~query ()) in
  print_endline ("Query: " ^ Uri.to_string uri);
  do_get ~uri rrd_from_json

let fetch_timescales () =
  let scales_from_json = rrd_from_json rrd_timescale_resp_of_yojson
  in
  do_get ~uri:(Uri.make ~path:"/rrd_timescales" ()) scales_from_json

let fetch_stats_init () =
  let stats_from_json = rrd_from_json stats_init_of_yojson
  in
  do_get ~uri:(Uri.make ~path:"/stats_init" ()) stats_from_json

let test () =
  Lwt.return_ok "Hello"
