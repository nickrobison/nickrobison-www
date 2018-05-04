open Www_types

module Make
    (S: Cohttp_lwt.S.Server)
    (FS: Mirage_types_lwt.KV_RO)
    (TMPL: Mirage_types_lwt.KV_RO)
    (Clock: Mirage_types.PCLOCK):
sig

  type dispatch = path -> cowabloga Lwt.t
  (** The type for the dispatch functions. *)

  val create: domain -> dispatch -> S.t

  type s = Conduit_mirage.server -> S.t -> unit Lwt.t
      (** The type for HTTP callbacks. *)

  val start: s -> FS.t -> TMPL.t -> Clock.t -> unit Lwt.t
      (** The HTTP server's start function. *)

end

