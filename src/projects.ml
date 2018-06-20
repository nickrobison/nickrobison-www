open Printf
open Lwt.Infix
open Cow.Html
open Www_types
open Data.Projects

type t = read:string read -> domain:domain -> contents Lwt.t

let build_project project =
  div (list [
      tag "hr" empty;
      div ~cls:"grid-x" (list [
          div ~cls:"cell small-10 medium-11" (list [
              h4 ~cls:"project-title" (string project.title);
              project.description;
            ]);
          Location.mk_link project.location ?cls:(Some "project-location cell auto") ?sizing:(Some Location.XL) ();
        ]);
    ])

let t ~read ~domain =
  let content = div (list [
      h1 (string "Projects");
      p (string "A list of interesting projects I've been working on.\nEither things that I've started, or heavily contribute to.");
      list (List.map (fun proj -> build_project proj) entries);
    ])
  in
  Pages.Global.t ~title:"Projects" ~headers:[] ~content:(Utils.Style.centered_content content ?spacing:(Some "medium-8 medium-offset-2") ()) ~domain ~read
