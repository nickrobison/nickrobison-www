open Lwt.Infix
open Cow.Html

type t = Cowabloga.Blog.Entry.t

let not_found ~domain x =
  let uri = Site_config.uri domain ("blog" :: x) in
  `Not_found uri

let make ?title ~read ~domain content =
  let uri = Uri.of_string "/blog/atom.xml" in
  let headers =
    link ~attrs:[
      "rel", "alternate";
      "type", "application/atom+xml";
      "href", Uri.to_string uri;
    ] empty
  in
  let title = "Blog" ^ match title with None -> "" | Some x -> " :: " ^ x
  in
  Pages.Global.t ~title ~headers ~content ~domain ~read
    (**
let copyright f = match f.rights with None -> [] | Some r -> [`Data r]
     *)
(** TODO: Get the real copyright *)
let copyright _ = []

let blog_index ~feed ~entries ~read ~domain =
  let recent_posts = Cowabloga.Blog.recent_posts feed entries in
  let copyright = copyright feed in
  let sidebar =
    Cowabloga.Foundation.Sidebar.t ~title:"Recent Posts" ~content:recent_posts
  in
  Cowabloga.Blog.to_html ?sep:None ~feed ~entries >>= fun posts ->
  (** let { title; subtitle; _ } = feed in *)
  let content =
    Cowabloga.Foundation.Blog.t ~title:"" ~subtitle:None ~sidebar ~posts ~copyright ()
  in
  make ~domain ~read content

let blog_entry ~feed ~entries ~read ~domain entry =
  let recent_posts = Cowabloga.Blog.recent_posts feed entries in
  let copyright = copyright feed in
  let sidebar = Cowabloga.Foundation.Sidebar.t ~title:"Recent Posts" ~content:recent_posts
  in
  Cowabloga.Blog.Entry.to_html ~feed ~entry >>= fun posts ->
  (**  let { title; subtitle; _ } = feed in *)
  let content = Cowabloga.Foundation.Blog.t ~title:"hello" ~subtitle:None ~sidebar ~posts ~copyright ()
  in
  let title = entry.Cowabloga.Blog.Entry.subject in
  make ~domain ~read ~title content >>= fun content ->
  Lwt.return (entry.Cowabloga.Blog.Entry.permalink, content)

let blog_entries ~feed ~entries ~read ~domain =
  Lwt_list.map_s (blog_entry ~domain ~read ~feed ~entries) entries

let atom_feed ~feed ~entries =
  let headers = Cowabloga.Headers.atom in
  let feed =
    Cowabloga.Blog.to_atom ~feed ~entries
    >|= Cow.Atom.xml_of_feed
    >|= Cow.Xml.to_string
  in
  Lwt.return (`Page (headers, feed))

(** Construct an HTTP dispatch funciton for the blog. *)
let dispatch ~feed ~entries ~read ~domain =
  atom_feed ~feed ~entries >>= fun atom_feed ->
  blog_index ~domain ~feed ~entries ~read >>= fun blog_index ->
  blog_entries ~domain ~read ~feed ~entries >>= fun blog_entries ->
  let blog_entry x =
    try List.assoc x blog_entries
    with Not_found -> not_found ~domain [x]
  in
  let f = function
    | ["index.html"]
    | [""] | [] -> blog_index
    | [x] -> blog_entry x
    | x -> not_found ~domain x
  in
  Lwt.return f
