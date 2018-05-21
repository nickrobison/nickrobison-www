open Printf
open Lwt.Infix
open Cow.Html
open Www_types

type t = read:string read -> domain:domain -> contents Lwt.t

type dispatch = feed:Cowabloga.Atom_feed.t -> read:string read -> Www_types.dispatch

let not_found ~domain section path =
  let uri = Site_config.uri domain (section :: path) in
  `Not_found uri

let get_extension filename =
  try
    let n = String.rindex filename '.' in
    Some (String.sub filename (n+1) (String.length filename - n - 1))
  with Not_found ->
    None

let read_file tmpl_read f =
  let read fn =
    Lwt.catch
      (fun () -> tmpl_read f >|= fn)
      (fun exn ->
         printf "Pages.read_file: exception %s\n!" (Printexc.to_string exn);
                 exit 1)
  in
  match get_extension f with
  | Some "md" -> read Cow.Markdown.of_string
  | Some "html" -> read (fun s -> Cow.Html.of_string s)
  | _ -> Lwt.return []

module Global = struct

  let uri = Uri.of_string

  let nav_links =
    tag "ul" ~cls:"left" (list [
        tag "li" (a ~href:(uri "/blog/") (string "Blog"));
        (**
        tag "li" (a ~href:(uri "/projects/") (string "Projects"))
        *)
      ])

  let top_nav = Cowabloga.Foundation.top_nav
      ~title:(p (string "Hello, my name is Nick"))
      ~title_uri:(uri "/")
      ~nav_links: nav_links

  let t ~title ~headers ~content ~read:_ ~domain =
    let scheme = match fst domain with `Http -> "http" | `Https -> "https" in
    let fonts =
      scheme ^ "://fonts.googleapis.com/css?family=Source+Sans+Pro:400,600,700" in
    let font =
      link ~rel: "stylesheet" (Uri.of_string "https://pro.fontawesome.com/releases/v5.0.13/css/all.css")
        ~attrs:["integrity", "sha384-oi8o31xSQq8S0RpBcb4FaLB8LJi9AT8oIdmS1QldR8Ui7KUQjNAnDlJjp55Ba8FG";
               "crossorigin", "anonymous"]
      ++
      link ~rel: "stylesheet" ~ty: "text/css" (Uri.of_string fonts)
      ++
      link ~rel: "icon" ~ty: "image/png" (Uri.of_string "/favicon.ico")
    in
    let headers = font @ headers in
    let content = top_nav @ content in
    let body =
      Cowabloga.Foundation.body ~highlight:"/css/magula.css"
        ~title ~headers ~content
        ~trailers: [] ()
    in
    let body = Cowabloga.Foundation.page ~body in
    Lwt.return (`Html (Lwt.return body))
end

module Index = struct

  let uri = Uri.of_string

  let t ~feeds ~read ~domain =
    read_file read "/intro.md" >>= fun l1 ->
    read_file read "/intro-f.html" >>= fun footer ->
    Cowabloga.Feed.to_html ~limit:12 feeds >>= fun recent ->
    let content = list [
        div ~cls:"row" (list [
            (div ~cls:"small-12 medium-6 columns" l1);
            div ~cls:"small-12 medium-6 columns front_updates"
               (h4 (list [
                    a ~href:(uri "/updates/atom.xml") (i ~cls:"fa fa-rss" empty);
                    string " Recent Updates ";
                    small (a ~href:(uri "/updates/") (string "all"))
                  ])
                ++ recent
               )
          ]);
        div ~cls:"row" (div ~cls:"small-12 columns" footer)
      ]
    in
    Global.t ~title:"Nick Robison" ~headers:[] ~content ~domain ~read
end

module Updates = struct

  let make ~read ~domain content =
    let uri = Uri.of_string "/updates/atom.xml" in
    let headers =
      link ~rel:"alternate" ~ty:"application/atom+xml" uri in
    let title = "Updates" in
    Global.t ~title ~headers ~content ~read ~domain

  let atom_feed ~feed ~feeds =
    let content_type_atom = Cowabloga.Headers.atom in
    let feed = Cowabloga.Feed.to_atom ~meta:feed ~feeds
      >|= Cow.Atom.xml_of_feed
      >|= Cow.Xml.to_string
    in
    Lwt.return (`Page (content_type_atom, feed))

  let dispatch ~feeds ~feed ~read ~domain =
    Cowabloga.Feed.to_html feeds >>= fun recent ->
    atom_feed ~feed ~feeds >>= fun atom_feed ->
    make ~domain ~read
      (div ~cls:"row" (
          div ~cls:"small-12 medium-9 large-6 front_updates" (
            h2 (string "Site Updates "
                ++ small (string "across the blog"))
            ++ recent)))
    >>= fun content ->
    let f = function
      | ["index.html"]
      | [""] | [] -> content
      | ["atom.xml"] -> atom_feed
      | x -> not_found ~domain "updates" x
    in
    Lwt.return f
end

