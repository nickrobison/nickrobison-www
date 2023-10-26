open Www_types

module Make
    (FS: Mirage_kv.RO)
    (TMPL: Mirage_kv.RO)
    (CLOCK: Mirage_clock.PCLOCK)
    (RES: Resolver_mirage.S)
    (CON: Conduit_mirage.S)
    (C: Cohttp_lwt.S.Client):
sig

  type dispatch = path -> cowabloga Lwt.t
  (** The type for the dispatch functions. *)

  val redirect: domain -> dispatch
  (** [redirect d path] redirects the user to [path] on domain [d]. *)

  val dispatch: domain -> FS.t -> TMPL.t -> RES.t -> C.ctx-> dispatch
  (** [dispatcher d fs tmpl path] is the object served by the HTTP
      server.

      {ul
      {- [d] is the current domain scheme and hostname;}
      {- [fs] is a read-only key/value store holding the static files such as
      images or CSS files;}
      {- [tmpl] is a read-only key/value store holding the proccessed data such
      as blog posts and wiki entries.}} *)


  val start: FS.t -> TMPL.t -> unit -> RES.t -> CON.t -> C.ctx -> unit Lwt.t
  (** The HTTP server's start function. *)
end

val domain_of_string: string -> domain
(** [domain_of_string d] parser the string [d] to build a domain. Should be of the form {i http://host} or {i https://host}. *)


