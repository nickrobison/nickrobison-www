module Make: sig

type t

val create: unit -> t

val fetch: t -> Uri.t -> string Lwt.t
end
