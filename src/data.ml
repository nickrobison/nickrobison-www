open Cow
open Printf

module People = struct
  let nick = {
    Atom.name = "Nick Robison";
    uri = Some "http://nickrobison.com";
    email = Some "nick@nickrobison.com";
  }
end

module Projects = struct

  module Location  = struct
    open Cow.Html
    type t = [`Github of Uri.t | `Bitbucket of Uri.t]

    type size =
      | Small
      | Large
      | XL
      | XXL

    let string_of_size size =
      match size with
      | Small -> "fa-sm"
      | Large -> "fa-lg"
      | XL -> "fa-2x"
      | XXL -> "fa-3x"

    let mk icon href ?cls ?size () =
      let sz = match size with
        | Some s -> " " ^ (string_of_size s)
        | None -> ""
      in
      let icon_cls = "fab " ^ "fa-" ^ icon ^ sz
      in
      let cls2 = match cls with
        | Some c -> c
        | None -> ""
      in
      a ~cls:cls2 ~href (i ~cls:icon_cls empty)

    let mk_link loc ?cls ?sizing  () =
      match loc with
      | `Github l -> mk "github" l ?cls ?size:sizing ()
      | `Bitbucket l -> mk "bitbucket" l ?cls ?size:sizing ()
  end

  type t = {
    title: string;
    location: Location.t;
    description: string;
  }

  let fasttuple = {
    title = "FastTuple";
    location = (`Github (Uri.of_string "https://github.com/nickrobison/fasttuple"));
    description = "Fast tuple desc"
  }

  let go_cddns = {
    title = "Go-CDDNS";
    location = (`Github (Uri.of_string "https://github.com/nickrobison/else-let"));
    description = "Simple client for dynamically updating Cloudflare DNS records";
  }

  let else_let = {
    title = "Else-Let";
    location = (`Github (Uri.of_string "https://github.com/nickrobison/else-let"));
    description = "Clojure macro for conditional binding of values, in the face nils.";
  }

  let entries = [fasttuple; go_cddns; else_let]
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

  (** Get the featured image URI, if it exists. *)
  let get_featured_image yaml =
    let has_key = Ezjsonm.(mem yaml ["featured_image"]) in
    match has_key with
    | false -> None
    | true -> (Some (Uri.of_string (Ezjsonm.(get_string (find yaml ["featured_image"])))))

  let get_tags yaml =
    let has_key = Ezjsonm.(mem yaml ["tags"]) in
    match has_key with
    | false -> None
    | true -> Some(Ezjsonm.(get_list get_string (find yaml ["tags"])))

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


  let entries ~yaml_file =
    let open Cowabloga.Blog.Entry in
    (**
    I don't know when we can bring yaml back into the mix, but we'll stick with JSON for now.
    let yaml = Yaml.of_string_exn yaml_file in
    *)
    let yaml = Ezjsonm.from_string yaml_file in
    let js_first = match yaml with
      | `A a -> List.hd a
      | _ -> raise (YAML_EXCEPTION "Cannot get first array")
    in
    let posts = match Ezjsonm.find js_first ["posts"] with
    | `A p -> p
    | _ -> raise (YAML_EXCEPTION "Cannot get posts")
    in
    List.fold_left (fun acc p ->
        let title =  Ezjsonm.(get_string (find p ["title"])) in
        let url = Ezjsonm.(get_string (find p ["url"])) in
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
        body = Ezjsonm.(get_string (find p ["file"]));
        (** We have to trim off the leading / which comes by default from wordpress. *)
        permalink = String.sub url 1 ((String.length url) - 1);
        image = get_featured_image p;
        tags = get_tags p;
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

  let updates scheme read_entry = {
    Cowabloga.Atom_feed.base_uri = Site_config.base_uri scheme;
    id = "updates/";
    title = "Nick Robison updates";
    subtitle = None;
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

