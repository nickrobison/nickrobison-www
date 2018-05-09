open Core

let filter_extension file =
  let extension = Filename.split_extension file in
  match (snd extension) with
  | None -> false
  | Some ext -> match ext with
    | "md" -> true
    | _ -> false

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
          let line = input_line file_chan in
        if (String.is_prefix line "---") then begin
          in_comment := (not !in_comment);
        end
        (** If we're in the comment, output to the yaml list*)
        else if !in_comment then yaml_lines := line :: !yaml_lines
        else md_lines := line :: !md_lines
        done
      with End_of_file ->
        print_endline "Done with file";
        print_endline (String.concat ?sep:(Some "\n") (List.rev !yaml_lines));
    )
    ~finally:(fun () -> In_channel.close file_chan);
  (** Now, write the yaml*)
  let output_file = Filename.concat out_dir (Filename.chop_extension file) ^ ".yml" in
  Out_channel.write_all output_file ~data:(String.concat ?sep:(Some "\n") (List.rev !yaml_lines))


let parse input_dir output_dir () =
  print_endline ("Parsing: " ^ input_dir);
  try
    Unix.mkdir output_dir;
  with
    Unix.Unix_error(_,_,_) -> print_endline "Cannot create directory";
  (** Get a list of all the files in the directory*)
  Sys.readdir input_dir |>
  Array.filter ~f:filter_extension |>
  Array.iter ~f:(fun f -> process_file input_dir f output_dir)


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


