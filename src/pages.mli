open Www_types

type t = read:string read -> domain:domain -> contents Lwt.t

type dispatch = feed:Cowabloga.Atom_feed.t -> read:string read -> Www_types.dispatch

module Global: sig
  (** Global page template. *)

  val t: title:string -> headers:Cow.Html.t -> content:Cow.Html.t -> t
end


module Index: sig
  (** The main index page. *)

  val t: books:Book_types.book list -> feeds: Cowabloga.Feed.feed list -> t
end

module Updates: sig
  (** Update pages. *)
  val dispatch: feeds:Cowabloga.Feed.feed list -> dispatch
  (** [dispatch f] is the dispatch function serving [/updates/],
    [/updates/index.html] and [/updates/atom.xml] using the contents
      extracted from [f]. *)
end

module About: sig

  val t: t
end

module Projects: sig

  val t: t
end
