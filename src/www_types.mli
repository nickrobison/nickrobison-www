type domain = [`Http | `Https] * string
(** The type for the domain scheme and name. *)

type path = string list
(** The type for URL path values. *)

type headers = (string * string) list
(** The type for header values. *)

type html = [`Html of string Lwt.t]
(** The type for raw HTML pages to be included in a template. *)

type page = [`Page of headers * string Lwt.t]
(** The type for static page values, to be included in a template. *)

type contents = [
  | page | html
  | `Not_found of Uri.t
  | `Redirect of Uri.t
]
(** The type for raw contents. This will be inserted into the global page template by the template engine. *)

type dispatch = domain:domain -> (path -> contents) Lwt.t
(** The type for static dispatch functions. *)

type 'a read = string -> 'a Lwt.t
(** The type to read files on the filesystem. *)

type cowabloga = [
  | html | page
  | `Atom of string Lwt.t
  | `Asset of string Lwt.t
  | `Redirect of string
  | `Not_found of string
]
(** The type for cowabloga pages. *)
