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
  type t = Cowabloga.Blog.Entry.t
  open People
  let entries =
    let open Cowabloga.Date in
    let open Cowabloga.Blog.Entry in
    [
      {
        updated = date(2018, 05, 04, 17, 00);
        authors = [nick];
        subject = "Test blog entry";
        body = "2018-test-blog.md";
        permalink = "2018-test-blog";
      };
    ]
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

