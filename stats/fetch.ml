open Lwt.Infix
open Js_of_ocaml_lwt

type rrd_meta = {
  start: int;
  rows: int;
  columns: int;
  step: int;
  en: int [@key "end"];
  legend: string list;
} [@@deriving yojson]

type rrd_update = {
  meta: rrd_meta
} [@@deriving yojson {strict = false}]

type rrd_timescale = {
  name: string;
  num_intervals: int;
  interval_in_steps: int;
} [@@deriving yojson]

type rrd_timescale_resp = rrd_timescale list [@@deriving yojson]

let do_get ~uri f =
  let uri = Uri.to_string uri in
  let open XmlHttpRequest in
  get uri >>= fun (frame) ->
  match frame.code with
  | 200 -> Lwt.return_ok (f frame.content)
  | _ -> Lwt.return_error "Error!"

let fetch_rrd_updates () =
  let rrd_from_xml content =
    Rrd_updates.of_string content
  in
  do_get ~uri:(Uri.make ~path:"/rrd_updates" ()) rrd_from_xml

let fetch_timescales () =
  "hello"
