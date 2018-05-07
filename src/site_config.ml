open Core

let string_of_scheme = function `Http -> "http" | `Https -> "https"
let base_uri (scheme, host) = string_of_scheme scheme ^ "://" ^ host ^ "/"

let uri (scheme, host) path =
  let path = String.concat ~sep:"/" path in
  let host_split = String.lsplit2 ~on:':' host in
  let host = match host_split with
    | Some x -> fst x
    | None -> host
  in
  let port = match host_split with
    | Some x -> (int_of_string (snd x))
    | None -> match scheme with
      | `Https -> 443
      | `Http -> 80
  in
  let scheme = string_of_scheme scheme in
  Uri.make ~scheme ~host ~port ~path ()
