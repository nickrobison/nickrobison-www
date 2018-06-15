open Www_types

type t = read:string read -> domain:domain -> contents Lwt.t

val t: t
