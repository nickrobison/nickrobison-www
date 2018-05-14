open Lwt.Infix
open Cow.Html

type t = Cowabloga.Blog.Entry.t

let log_src = Logs.Src.create "blog" ~doc:"Web server"
module Log = (val Logs.src_log log_src: Logs.LOG)


let not_found ~domain x =
  let uri = Site_config.uri domain ("blog" :: x) in
  `Not_found uri

let make ?title ~read ~domain content =
  let uri = Uri.of_string "/blog/atom.xml" in
  let headers =
    link ~rel: "alternate" ~ty: "application/atom+xml" uri;
  in
  let title = "Blog" ^ match title with None -> "" | Some x -> " :: " ^ x
  in
  Pages.Global.t ~title ~headers ~content ~domain ~read
    (**
let copyright f = match f.rights with None -> [] | Some r -> [`Data r]
     *)
(** TODO: Get the real copyright. Looks like the feed is not being propogated correctly. *)
let copyright _ = []

let blog_index ~feed ~entries ~read ~domain offset =
  let offset_multiple = offset * 10 in
  let filtered_entries = Core_kernel.List.sub (List.sort (fun (a: Cowabloga.Blog.Entry.t) (b: Cowabloga.Blog.Entry.t) ->
    compare (Cowabloga.Date.atom_date b.updated) (Cowabloga.Date.atom_date a.updated)) entries) offset_multiple (offset_multiple + 10) in
  let recent_posts = Cowabloga.Blog.recent_posts feed filtered_entries in
  let copyright = copyright feed in
  let sidebar =
    Cowabloga.Foundation.Sidebar.t ~title:"Recent Posts" ~content:recent_posts
  in
  Cowabloga.Blog.to_html ?sep:None ~feed ~entries:filtered_entries >>= fun posts ->
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
  Log.info (fun f -> f "Building atom feed");
  let headers = Cowabloga.Headers.atom in
  Log.info (fun f -> f "Built atom headers.");
  let feed =
    Cowabloga.Blog.to_atom ~feed ~entries
    >|= Cow.Atom.xml_of_feed
    >|= Cow.Xml.to_string
  in
  Lwt.return (`Page (headers, feed))

(** Construct an HTTP dispatch funciton for the blog. *)
let dispatch ~feed ~entries ~read ~domain =
  Log.info (fun f -> f "Getting ready to dispatch");
  atom_feed ~feed ~entries >>= fun atom_feed ->
  Log.info (fun f -> f "Built atom feed");
  blog_index ~domain ~feed ~entries ~read 0 >>= fun blog_index ->
  blog_entries ~domain ~read ~feed ~entries >>= fun blog_entries ->
  let blog_entry x =
    try List.assoc x blog_entries
    with Not_found -> not_found ~domain [x]
  in
  let f = function
    | ["index.html"]
    | [""] | [] -> blog_index
    | ["atom.xml"] -> atom_feed
    | "entries" :: x :: tl -> blog_entry ("entries/" ^ x)
    | hd :: [] -> blog_index
    | x -> not_found ~domain x
  in
  Lwt.return f
