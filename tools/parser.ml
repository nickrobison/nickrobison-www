open Core


let string_replace = [
  Re.replace_string (Re.compile (Re.alt [
      (Re.str "&#8216;");
      (Re.str "&#8217;");
    ])) ~by:"'";
  Re.replace_string (Re.compile (Re.str "&nbsp;")) ~by:"";
  Re.replace_string (Re.compile (Re.str "&#8211;")) ~by:"-";
  Re.replace_string (Re.compile (Re.seq [
      (Re.str "/ref=");
      (Re.rep (Re.compl [Re.char '"']));
    ])) ~by:"/replaced";
  Re.replace_string (Re.compile (Re.seq [
      (Re.str "/?");
      (Re.rep (Re.compl [Re.char '"']));
    ])) ~by:"replaced";
  String.lstrip;
]

let process_line (line: string) =
  List.fold string_replace ~init:line ~f:(fun l f -> f l)

(** Regex for skipping lines in the markdown, that we don't need*)
let skip_regex = Re.compile (Re.alt [
    Re.str "kcite";
    Re.seq [
      Re.char '<';
      Re.opt (Re.char '/');
      Re.str "p";
    ];
    Re.str "</div>";
  ])

(** Creates the directory, prints a warning if the directory already exists.
    * This doesn't handle any special cases for not being able to create dir.
*)
let create_dir directory =
  try
    Unix.mkdir directory
  with
    Unix.Unix_error(_,_,_) -> print_endline "Cannot create directory"

(** Since YAMl doesn't allow for tabs as indentation, we use double spaces
    * This function simply adds double spaces for the appropriate indentation level.
    * Which avoids having empty '  ' strings everywhere.
*)
let add_padding pad_amount =
  let rec aux n acc =
    if n = 0 then acc else aux (n-1) ("  " ^ acc) in
  aux pad_amount ""

(** Filters out anything that isn't a markdown file. *)
let filter_extension file =
  let extension = Filename.split_extension file in
  match (snd extension) with
  | None -> false
  | Some ext -> match ext with
    | "md" -> true
    | _ -> false

(** Process markdown file to extract YAML header and filtered markdown.
    * This function writes the markdown to the [out_dir] and returns the YAML as a list.
*)
let process_file in_dir file out_dir =
  print_endline ("Processing file: " ^ file);
  let yaml_lines = ref [] in
  let md_lines = ref [] in
  let in_comment = ref false in
  let input_file = Filename.concat in_dir file in
  let file_chan = In_channel.create input_file in
  (** Read the file and parse out the yaml and markdown *)
  protect ~f:(fun () ->
      try
        while true; do
          let line = In_channel.input_line_exn file_chan in
        if (String.is_prefix line "---") then begin
          in_comment := (not !in_comment);
        end
        else if !in_comment then yaml_lines := line :: !yaml_lines
          (** Now, filter out lines that we don't want*)
        else begin
          let matches = Re.matches skip_regex line in
          if phys_equal (List.length matches) 0 then md_lines := process_line line :: !md_lines
        end
        done
             (** If we're in the comment, output to the yaml list*)
      with End_of_file ->
        print_endline "Done with file";
    )
    ~finally:(fun () -> In_channel.close file_chan);
  (** Now, write the md and return the yaml*)
  let output_file = Filename.concat out_dir file in
  Out_channel.write_all output_file ~data:(String.concat ?sep:(Some "\n") (List.rev !md_lines));
  (** We need to append the '-' to the head of the first element in the list*)
  let yaml_ordered = List.rev !yaml_lines in
  ( "-\n" ^ (add_padding 2) ^ (List.hd_exn yaml_ordered)) :: (List.tl_exn yaml_ordered |>
                                                              List.map ~f:(fun f -> (add_padding 1) ^ f))

(** Run parser over input directory. *)
let parse input_dir output_dir () =
  print_endline ("Parsing: " ^ input_dir);
  create_dir output_dir;
  let yaml_init =
    ["posts:"]
    in
  (** Get a list of all the files in the directory*)
  Sys.readdir input_dir |>
  Array.filter ~f:filter_extension |>
  Array.fold ~init:yaml_init ~f:(fun acc f ->
      let yaml = process_file input_dir f output_dir in
      acc @ yaml) |>
  (fun yaml_lines ->
     let yaml_file = Filename.concat output_dir "posts.yml" in
     Out_channel.write_all yaml_file ~data:(String.concat ?sep:(Some ("\n" ^ (add_padding 1))) yaml_lines)
  )


let command =
  Command.basic
    ~summary: "Parse Hugo output from Wordpress"
    ~readme:(fun () -> "More details about the parser")
    Command.Spec.(
      empty
      +> anon ("directory" %: file)
        +> anon ("output" %: file)
    )
    parse

let () =
  Command.run ~version:"0.0.1" command


