
module Blog: sig


  type t = Cowabloga.Blog.Entry.t
(** The type for blog entries. *)

  val entries: string -> t list
end

module Projects: sig
  type t = {
    title: string;
    location: string;
    description: string;
  }

  val entries: t list
end


module Feed: sig

  type t = Www_types.domain -> Cow.Html.t Www_types.read -> Cowabloga.Atom_feed.t

  val blog: t

  val updates: t
    (** The static feed for site updates. *)
end

val empty_feed: Cowabloga.Atom_feed.t
