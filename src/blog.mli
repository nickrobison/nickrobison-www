
type t = Cowabloga.Blog.Entry.t
(** The type for blog entries. *)

val dispatch:
  feed:Cowabloga.Atom_feed.t ->
  entries:t list ->
  read:string Www_types.read ->
  Www_types.dispatch
