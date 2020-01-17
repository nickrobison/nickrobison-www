module Make
    (S: Mirage_stack_lwt.V4)
    (KEYS: Mirage_kv.RO)
    (FS: Mirage_kv.RO)
    (TMPL: Mirage_kv.RO)
    (Clock: Mirage_clock.PCLOCK)
    (RES: Resolver_lwt.S)
    (CON: Conduit_mirage.S):
sig

  val start:
    S.t -> KEYS.t ->
    FS.t -> TMPL.t -> unit -> Resolver_lwt.t -> CON.t -> unit -> unit Lwt.t
      (** Start function of the HTTP server*)
end
