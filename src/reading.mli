module Make
    (Client: Cohttp_lwt.S.Client):
sig
  type t

  val create: key:string -> id:string -> Client.ctx -> t

  val fetch: t -> Uri.t -> (Xmlm.dtd * Ezxmlm.nodes) Lwt.t

  val fetch_books: t -> string -> Book_types.book list option Lwt.t

end


