open Core

let replace_markdown line =
  let new_line = ref line in
  let regex = Re.compile (Re.alt [(Re.seq [
      Re.group (Re.str "[");
      Re.char '<';
      Re.rep1 Re.alpha;
      Re.char ' ';
    ]);
     Re.seq [
      Re.str "/>";
      Re.group (Re.seq [
          Re.str "][";
          Re.rep1 Re.digit;
          Re.char ']';
        ])
    ]
    ]) in
  let matches = Re.all regex !new_line in
  let left_match = List.hd matches in
  match left_match with
  | None -> !new_line
  | Some l ->
    let left_groups = Re.Group.all l in
    Array.iter left_groups ~f:(fun g -> print_endline ("Left match group: " ^ g));
    new_line := Re.replace_string (Re.compile (Re.str (Array.get left_groups 2))) ~by:"" !new_line;
    let right_match = List.nth matches 1 in
    match right_match with
    | None -> !new_line
    | Some r ->
      let right_groups = Re.Group.all r in
       Array.iter right_groups ~f:(fun g -> print_endline ("Right match group: " ^ g));
       Re.replace_string (Re.compile (Re.str (Array.get right_groups 2))) ~by:"<" !new_line

(** Regex for pulling things out of the figures. *)
let figure_reg = (Re.compile (Re.seq([
      Re.str "<figure";
      Re.rep1 Re.notnl;
      Re.group (Re.seq([
          Re.str "style=\"";
          Re.rep1 (Re.compl([
              Re.char '"';
            ]));
          Re.char '"';
        ]));
      Re.rep1 (Re.compl([
          Re.char '>';
        ]));
        Re.char '>';
    ])))

(** Fixes html figure elements by applying the following transformations.
    * Adds a double new line to fix inline elements.
    * Removes the embedded style info.
*)
let fix_figure line =
  Re.replace figure_reg ~f:(fun g ->
      let groups = Re.Group.all g in
      let full_string = (Array.get groups 0) in
      "\n\n" ^ (Re.replace_string (Re.compile
                                   (Re.str
                                      (Array.get groups 1))))
             ~by:"" full_string
    ) line

(** Partially curried functions for replacing certain occurances in lines. *)
let markdown_string_replace = [
  Re.replace_string (Re.compile (Re.str "&nbsp;")) ~by:"";
  String.lstrip;
  (** There should be a better way remove the markdown tags *)
  Re.replace_string (Re.compile (Re.str "[<")) ~by:"<";
  Re.replace_string (Re.compile (Re.seq [
      Re.str "/>][";
      Re.rep1 Re.digit;
      Re.char ']';
    ])) ~by:"/>";
  fix_figure;
]

let scheme_regex =
  (Re.seq [
           (Re.rep1 Re.alnum);
           Re.str "://";
         ])

(** Regex for extracting URIs from individual lines*)
let uri_regex =
  Re.compile (Re.seq [
      (** Scheme *)
      (Re.group scheme_regex);
      (** Hostname *)
      (Re.group (Re.rep1 (Re.compl [
           Re.char '/';
         ])));
      (** Query options*)
      (Re.group (Re.rep1 (Re.compl [
           Re.char '"';
           Re.char '\n';
           Re.char ' ';
         ])))
    ])

(** Look for any URIs that match our hostname and rewrite them*)
let rewrite_uri hostname uri =
  if String.equal hostname "www.nickrobison.com" then begin
    Re.replace_string (Re.compile (Re.seq [
        scheme_regex;
        Re.str "www.nickrobison.com/wp-content/uploads/";
      ])) ~by:"https://files.nickrobison.com/images/" uri
  end
  else begin
    uri
      end

let handle_uri line =
  let all = Re.all uri_regex line in
  if phys_equal (List.length all) 0 then line else begin
    (** Loop through all the matches and do the replace *)
    List.fold all ~f:(fun acc m ->
        let group = Re.Group.all m in
        let hostname = Array.get group 2 in
        let params = Array.get group 3 in
        (** Within the params string, replace all the equals signs and amperands, then replace the old params with the new params in the line*)
        let params_replaced = Re.replace_string (Re.compile (Re.char '=')) ~by:"&#61;"
            (Re.replace_string (Re.compile (Re.char '&')) ~by:"&#38;" params) in
        rewrite_uri hostname (Re.replace_string (Re.compile (Re.str params)) params_replaced acc)
      ) ~init:line;
  end
(** Apply the various transformations to the markdown lines. *)
let process_md_line (line: string) =
  List.fold markdown_string_replace ~init:line ~f:(fun l f -> f l)

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

let yaml_string_replace = [
  Re.replace_string (Re.compile (Re.str "/wp-content/uploads/"))
    ~by: "https://files.nickrobison.com/images/"
]

(** Apply the various transformations to the markdown lines. *)
let process_yaml_line line =
  List.fold yaml_string_replace ~init:line ~f:(fun l f -> f l)

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
        else if !in_comment then yaml_lines := (process_yaml_line line) :: !yaml_lines
          (** Now, filter out lines that we don't want*)
        else begin
          let matches = Re.matches skip_regex line in
          if phys_equal (List.length matches) 0 then md_lines := handle_uri (process_md_line line) :: !md_lines
        end
        done
      with End_of_file -> ()
    )
    ~finally:(fun () -> In_channel.close file_chan);
  (** Now, write the md and return the yaml*)
  let output_file = Filename.concat out_dir file in
  Out_channel.write_all output_file ~data:(String.concat ?sep:(Some "\n") (List.rev !md_lines));
  (** Add the file name, so we can look it up later in the Unikernel. *)
  yaml_lines := ("file: " ^ file) :: !yaml_lines;
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
     let yaml_string = String.concat ?sep:(Some ("\n" ^ (add_padding 1))) yaml_lines in
     let yaml_file = Filename.concat output_dir "posts.yml" in
     Out_channel.write_all yaml_file ~data:yaml_string;
     let json_file = Filename.concat output_dir "posts.json" in
     let json = match Yaml.yaml_of_string yaml_string with
       | Ok y -> (match Yaml.to_json y with
         | Ok j -> j
         | Error _ -> raise Not_found)
       | Error _ -> raise Not_found
     in
     Out_channel.write_all json_file ~data:Ezjsonm.(to_string (wrap json))
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


