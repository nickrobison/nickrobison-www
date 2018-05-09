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

  exception YAML_EXCEPTION of string

  (** Simple helper function to get an array from a Yaml.value. *)
  let get_array yaml =
    match yaml with
    | `A obj -> obj
    | _ -> raise (YAML_EXCEPTION "Nope")


  let log_src = Logs.Src.create "blog" ~doc:"Web server"
  module Log = (val Logs.src_log log_src: Logs.LOG)
  type t = Cowabloga.Blog.Entry.t
  open People

  let entries yaml_file =
    let open Cowabloga.Date in
    let open Cowabloga.Blog.Entry in
    let yaml = Yaml.of_string_exn yaml_file in
    let entries = ref [] in
    let posts = Ezjsonm.(get_array (find yaml ["posts"])) in
    List.iter (fun p ->
        let post = {
        updated = date(2018, 05, 04, 17, 00);
        authors = [nick];
        subject = Ezjsonm.(get_string (find p ["title"]));
        body = "2018-test-blog.md";
        permalink = "2018-test-blog";
      } in
        entries := post :: !entries
      ) posts;
    !entries
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

