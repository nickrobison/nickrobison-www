open Lwt.Infix
open Js_of_ocaml_lwt

let do_get ~uri =
  let open XmlHttpRequest  in
  let uri = Uri.to_string uri in
  get uri >>= fun (frame) ->
  print_endline frame.content;
  Lwt.return frame.content
