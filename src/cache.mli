open Www_types

module Make
    (S: Cohttp_lwt.S.Server)
    (FS: Mirage_types_lwt.KV_RO)
    (TMPL: Mirage_types_lwt.KV_RO)
    (PClock: Mirage_types.PCLOCK):
sig

  type t

  val create: PClock.t -> Duration.t -> t

  val fetch: t -> domain -> TMPL.t -> (domain -> TMPL.t -> cowabloga Lwt.t) -> cowabloga Lwt.t
end
