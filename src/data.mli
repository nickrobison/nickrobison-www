
module Blog: sig


  type t = Cowabloga.Blog.Entry.t
(** The type for blog entries. *)

  val entries: yaml_file:string -> t list
  (** Gets the blog entries from the given index file. *)
end

module Projects: sig

  module Location: sig
    type t = [`Github of Uri.t | `Bitbucket of Uri.t]

    type size =
      | Small
      | Large
      | XL
      | XXL

    val mk_link: t -> ?cls: string -> ?sizing: size -> unit -> Cow.Html.t
  end

  type t = {
    title: string;
    location: Location.t;
    description: Cow.Markdown.t;
  }

  val entries: t list
  (** Get the list of project entires. *)
end


module Feed: sig

  type t = Www_types.domain -> Cow.Html.t Www_types.read -> Cowabloga.Atom_feed.t

  val blog: t

  val updates: t
    (** The static feed for site updates. *)
end

val empty_feed: Cowabloga.Atom_feed.t
