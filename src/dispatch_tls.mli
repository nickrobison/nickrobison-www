module Make
    (S: Mirage_stack_lwt.V4)
    (KEYS: Mirage_types_lwt.KV_RO)
    (FS: Mirage_types_lwt.KV_RO)
    (TMPL: Mirage_types_lwt.KV_RO)
    (Clock: Mirage_types.PCLOCK) :
sig

  val start:
    S.t -> KEYS.t ->
    FS.t -> TMPL.t -> Clock.t -> unit -> unit Lwt.t
      (** Start function of the HTTP server*)
end
