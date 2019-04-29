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

let do_get ~uri f =
  let uri = Uri.to_string uri in
  let open XmlHttpRequest in
  get uri >>= fun (frame) ->
  match frame.code with
  | 200 -> Lwt.return_ok (f frame.content)
  | _ -> Lwt.return_error "Error!"

let fetch_rrd_updates () =
  let jsn_from_string content =
    match rrd_update_of_yojson (Yojson.Safe.from_string content) with
    | Error _e -> raise (Failure "Cannot decode json")
    | Ok rrd -> rrd
  in
  do_get ~uri:(Uri.make ~path:"/rrd_updates" ()) jsn_from_string
