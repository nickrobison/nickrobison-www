let not_found ~domain x =
  let uri = Site_config.uri domain ("stats" :: x) in
  `Not_found uri

(** Implement checks*)
let check_ok ~domain:_ =
  let headers = Cowabloga.Headers.html in
  let body = Lwt.return "Site ok" in
  `Page (headers, body)

let dispatch ~domain =
  let f = function
    | [] -> check_ok ~domain
    | ["ok"] -> check_ok ~domain
    | x -> not_found ~domain x
  in
  Lwt.return f
