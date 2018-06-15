open Printf
open Lwt.Infix
open Cow.Html
open Www_types
open Data.Projects

type t = read:string read -> domain:domain -> contents Lwt.t

module Entry = struct
  type t = {
    title: string;
    location: string;
    description: string;
  }
end


let centered_content content ?spacing () =
  let grid_cls = match spacing with
    | None -> "cell"
    | Some e -> "cell " ^ e
  in
   list [
        div ~cls:"grid-x" (list [
            (div ~cls:grid_cls content);
          ]);
      ]


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
  Pages.Global.t ~title:"Projects" ~headers:[] ~content:(centered_content content ()) ~domain ~read
