let string_of_scheme = function `Http -> "http" | `Https -> "https"
let base_uri (scheme, host) = string_of_scheme scheme ^ "://" ^ host ^ "/"

let uri (scheme, host) path =
  let scheme = string_of_scheme scheme in
  let path = String.concat "/" path in
  Uri.make ~scheme ~host ~path ()
