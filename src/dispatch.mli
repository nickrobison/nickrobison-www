open Www_types

module Make
    (S: Cohttp_lwt.S.Server)
    (FS: Mirage_types_lwt.KV_RO)
    (TMPL: Mirage_types_lwt.KV_RO)
    (Clock: Mirage_types.PCLOCK)
    (RES: Resolver_lwt.S)
    (CON: Conduit_mirage.S):
sig

  type dispatch = path -> cowabloga Lwt.t
  (** The type for the dispatch functions. *)

  val redirect: domain -> dispatch
  (** [redirect d path] redirects the user to [path] on domain [d]. *)

  val dispatch: domain -> FS.t -> TMPL.t -> Resolver_lwt.t -> CON.t-> Clock.t -> dispatch
  (** [dispatcher d fs tmpl path] is the object served by the HTTP
      server.

      {ul
      {- [d] is the current domain scheme and hostname;}
      {- [fs] is a read-only key/value store holding the static files such as
      images or CSS files;}
      {- [tmpl] is a read-only key/value store holding the proccessed data such
      as blog posts and wiki entries.}} *)

  val create: domain -> dispatch -> S.t

  type s = Conduit_mirage.server -> S.t -> unit Lwt.t
  (** The type for HTTP callbacks. *)

  val start: s -> FS.t -> TMPL.t -> Clock.t -> Resolver_lwt.t -> CON.t -> unit Lwt.t
  (** The HTTP server's start function. *)
end

val domain_of_string: string -> domain
(** [domain_of_string d] parser the string [d] to build a domain. Should be of the form {i http://host} or {i https://host}. *)

