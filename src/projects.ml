open Printf
open Lwt.Infix
open Cow.Html
open Www_types
open Data.Projects

type t = read:string read -> domain:domain -> contents Lwt.t

let build_project project =
  div (list [
       tag "hr" empty;
    h4 (string project.title);
    p (string project.description);
    ])

let t ~read ~domain =
  let content = div (list [
      h1 (string "Projects");
      p (string "A list of interesting projects I've been working on.\nEither things that I've started, or heavily contribute to.");
      list (List.map (fun proj -> build_project proj) entries);
    ])
  in
  Pages.Global.t ~title:"Projects" ~headers:[] ~content:(Utils.Style.centered_content content ?spacing:(Some "medium-8 medium-offset-2") ()) ~domain ~read
