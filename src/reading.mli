module Make
    (RES: Resolver_lwt.S)
    (CON: Conduit_mirage.S):
sig
  type t

  val create: key:string -> id:string -> Resolver_lwt.t -> CON.t -> t

  val fetch: t -> Uri.t -> (Xmlm.dtd * Ezxmlm.nodes) Lwt.t

  val fetch_books: t -> string -> Book_types.book list option Lwt.t

end


