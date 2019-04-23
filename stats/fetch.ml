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

let do_get ~uri =
  let open XmlHttpRequest  in
  let uri = Uri.to_string uri in
  get uri >>= fun (frame) ->
  let jsn = Yojson.Safe.from_string frame.content in
  print_endline (Yojson.Safe.pretty_to_string jsn);
  match rrd_update_of_yojson jsn with
  | Error e -> Lwt.return ("Error: " ^ e)
  | Ok rrd ->
    print_endline ("End value " ^(string_of_int rrd.meta.en));
    Lwt.return frame.content
