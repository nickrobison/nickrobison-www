open Printf
open Lwt.Infix
open Cow.Html
open Www_types

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


let t ~projects ~read ~domain =
  Pages.Global.t ~title:"Projects" ~headers:[] ~content:(string "Hello!") ~domain ~read
  (**
  read_file read "/projects.md" >>= fun pbody ->
    let content = centered_content pbody ?spacing:(Some "medium-8 medium-offset-2") ()
    in
    Pages.Global.t ~title:"About" ~headers:[] ~content ~domain ~read
  *)
