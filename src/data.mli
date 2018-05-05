
module Blog: sig

  type t = Cowabloga.Blog.Entry.t
(** The type for blog entries. *)

  val entries: t list
end

module Feed: sig

  type t = Www_types.domain -> Cow.Html.t Www_types.read -> Cowabloga.Atom_feed.t

  val blog: t
end

val empty_feed: Cowabloga.Atom_feed.t
