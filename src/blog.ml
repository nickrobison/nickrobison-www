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

let blog_index ~feed ~entries ~read ~domain ~page_range =
  let recent_posts = Cowabloga.Blog.recent_posts feed entries in
  let copyright = copyright feed in
  let sidebar =
    Cowabloga.Foundation.Sidebar.t ~title:"Recent Posts" ~content:recent_posts
  in
  Cowabloga.Blog.to_html ?sep:None ~feed ~entries:entries >>= fun posts ->
  (** let { title; subtitle; _ } = feed in *)
  let content =
    Cowabloga.Foundation.Blog.t ~title:"" ~subtitle:None ~sidebar ~posts ~copyright ?pages:(Some(page_range)) ()
  in
  make ~domain ~read content

let make_index_pages ~feed ~entries ~read ~domain partition =
  let total_pages = List.length entries mod partition in
  let paritioned = List.sort Cowabloga.Blog.Entry.compare entries |>
                   Base.List.groupi ~break:(fun i _ _ -> i mod partition = 0)
  in
  Lwt_list.mapi_s (fun idx entries ->
      let idx_offset = idx + 1 in
      blog_index ~feed ~entries ~read ~domain ~page_range:(idx_offset, total_pages) >>= fun index_page ->
      Lwt.return(("blog/" ^ string_of_int (idx + 1)), index_page)) paritioned

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
  blog_entries ~domain ~read ~feed ~entries >>= fun blog_entries ->
  make_index_pages ~domain ~read ~feed ~entries 10 >>= fun index_pages ->
  let index_page page =
    (**blog_index_page ~domain ~feed ~entries ~read page >|= (fun f -> f)*)
    try List.assoc page index_pages
    with Not_found -> not_found ~domain [page]
  in
  let blog_entry x =
    try List.assoc x blog_entries
    with Not_found -> not_found ~domain [x]
  in
  let f = function
    | ["index.html"]
    | [""] | [] -> index_page ("blog/" ^ "1")
    | ["atom.xml"] -> atom_feed
    | "entries" :: x :: tl -> blog_entry ("entries/" ^ x)
    | hd :: [] -> index_page ("blog/" ^ hd)
    | x -> not_found ~domain x
  in
  Lwt.return f
