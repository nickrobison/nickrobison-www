open Cow
open Printf

module People = struct
  let nick = {
    Atom.name = "Nick Robison";
    uri = Some "http://nickrobison.com";
    email = Some "nick@nickrobison.com";
  }
end


module Blog = struct

  let log_src = Logs.Src.create "data" ~doc:"Web server"
  module Log = (val Logs.src_log log_src: Logs.LOG)
  type t = Cowabloga.Blog.Entry.t
  open People

  exception YAML_EXCEPTION of string

  (** Simple helper function to get an array from a Yaml.value. *)
  let get_array yaml =
    match yaml with
    | `A obj -> obj
    | _ -> raise (YAML_EXCEPTION "Nope")

  let padded_string_of_int int =
    let int_string = (string_of_int int) in
    if String.length int_string == 1 then "0" ^ int_string else int_string

  let int_from_list list nth =
    let inth = List.nth list nth in
    int_of_string (inth)

  let build_md_link (d: Cowabloga.Date.date) title =
    (** Filter out special characters that are causing titles to be wrong. *)
    let regexp = Re.compile (Re.alt [
      (Re.char ':');
      (Re.char '?');
      (Re.str "’");
      (Re.char ',');
      (Re.str "-");
      (Re.punct);
    ]) in
    let filtered = String.lowercase_ascii (Stringext.replace_all
                                (Re.replace_string regexp "" title)
                                " " "-")
        in
    Log.info (fun f -> f "Parsing title: [%s]" filtered);
    (string_of_int d.year) ^ "-"
    ^ (padded_string_of_int d.month) ^ "-"
    ^ (padded_string_of_int d.day) ^ "-"
    (** We also need to convert everything to lowercase and remove the spaces. *)
    ^ Re.replace_string (Re.compile (Re.str "-–-")) "-" filtered

  (** Another part of OCaml that defeats me. Regexp. *)
  let parse_date date_string =
    let split_string = String.split_on_char 'T' date_string in
    let date_string = String.split_on_char '-' (List.nth split_string 0) in
    let split_time_string  = (List.nth split_string 1) in
    let time_string = String.split_on_char ':' (String.sub split_time_string 0 (String.index split_time_string '+')) in
    Cowabloga.Date.date(int_from_list date_string 0,
                                   int_from_list date_string 1,
                                   int_from_list date_string 2,
                                   int_from_list time_string 0,
                                   int_from_list time_string 1)

  let entries yaml_file =
    let open Cowabloga.Blog.Entry in
    let yaml = Yaml.of_string_exn yaml_file in
    let posts = Ezjsonm.(get_array (find yaml ["posts"])) in
    List.fold_left (fun acc p ->
        let title =  Ezjsonm.(get_string (find p ["title"])) in
        Log.info (fun f -> f "Parsing [%s]" title);
        let draft = Ezjsonm.mem p ["draft"] in
        if draft then acc
        else begin
          let date = parse_date Ezjsonm.(get_string (find p ["date"])) in
          let link = build_md_link date title in
          Log.info (fun f -> f "Built link [%s]" link);
        {
        updated = date;
        authors = [nick];
        subject = title;
        (**
        body = link ^ ".md";
       
        permalink = link;
        *)
        body = link ^ ".md";
        permalink = link;
      } :: acc
      end
      ) [] posts
end

module Feed = struct
  open Www_types

  type t = domain -> Cow.Html.t read -> Cowabloga.Atom_feed.t

  let blog domain read_entry = {
    Cowabloga.Atom_feed.base_uri = Site_config.base_uri domain;
    id = "blog/";
    title = "Nick Robison's Blog";
    subtitle = Some "musings from my life";
    rights = None;
    author = None;
    read_entry
  }
end


let empty_feed = {
  Cowabloga.Atom_feed.base_uri = Site_config.base_uri (`Http, "localhost");
  id = "";
  title = "";
  subtitle = None;
  rights = None;
  author = None;
  read_entry = (fun _ -> Lwt.fail Not_found);
}

