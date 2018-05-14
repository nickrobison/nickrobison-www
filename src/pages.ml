open Printf
open Lwt.Infix
open Cow.Html
open Www_types

type t = read:string read -> domain:domain -> contents Lwt.t

type dispatch = read:string read -> Www_types.dispatch

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
        tag "li" (a ~href:(uri "/projects/") (string "Projects"))
      ])

  let top_nav = Cowabloga.Foundation.top_nav
      ~title:(p (string "Nick Robison"))
      ~title_uri:(uri "/")
      ~nav_links: nav_links

  let t ~title ~headers ~content ~read:_ ~domain =
    let scheme = match fst domain with `Http -> "http" | `Https -> "https" in
    let fonts =
      scheme ^ "://fonts.googleapis.com/css?family=Source+Sans+Pro:400,600,700" in
    let font =
      link ~rel: "stylesheet" (Uri.of_string "/css/font-awesome.css")
      ++
      link ~rel: "stylesheet" ~ty: "text/css" (Uri.of_string fonts)
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

  let t ~read ~domain =
    read_file read "/intro.md" >>= fun l1 ->
    read_file read "/intro-f.html" >>= fun footer ->
    let content = list [
        div ~cls:"row" (div ~cls:"small-12 columns" l1);
        div ~cls:"row" (div ~cls:"small-12 columns" footer)
      ]
    in
    Global.t ~title:"Nick Robison" ~headers:[] ~content ~domain ~read
end


