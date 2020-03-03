open Www_types

module Make
    (S: Cohttp_lwt.S.Server)
    (FS: Mirage_kv.RO)
    (TMPL: Mirage_kv.RO)
    (PClock: Mirage_clock.PCLOCK):
sig

  type t

  val create: Duration.t -> t

  val fetch: t -> domain -> TMPL.t -> (domain -> TMPL.t -> cowabloga Lwt.t) -> cowabloga Lwt.t
end
