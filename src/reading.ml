open Lwt.Infix
open Ezxmlm
open Book_types

module Make
(Client: Cohttp_lwt.S.Client) = struct

  type t = {
    api_key: string;
    user_id: string;
    ctx: Client.ctx;
  }

  let create ~key ~id ctx =
    {
      api_key = key;
      user_id = id;
      ctx = ctx;
    }

  let string_of_data child nodes =
    data_to_string (member child nodes)

  let extract_image_uri book =
    members_with_attr "image_url" book
    |> List.hd
    |> snd
    |> data_to_string
    |> Uri.of_string

  let fst_book_author book =
    member "authors" book
    |> member "author"
    |> string_of_data "name"

  let build_review review =
    let id = data_to_string (member "id" review) in
    let book = member "book" review in
    let (b: book) =
      {
        title = string_of_data "title" book;
        author = fst_book_author book;
        image_url = extract_image_uri book;
        link = Uri.of_string (string_of_data "link" book);
      } in
    ({
      id = int_of_string id;
      book = b;
    }: review)

  let reviews_of_xml (_dtd, xml) =
    member "GoodreadsResponse" xml
    |> member "reviews"
    |> members "review"
    |> List.map build_review


  let build_uri t action =
    let uri = Uri.make
        ~scheme:"https"
        ~host:"www.goodreads.com"
        ~path: (match action with
            | PROFILE -> "/user/show/" ^ t.user_id
            | READING _ -> "/review/list/" ^ t.user_id ^ ".xml"
          )
        ~query: ["key", [t.api_key];]
        () in
    (* Add any additional query params that we might need*)
    match action with
    | PROFILE -> uri
    | READING s -> Uri.add_query_params uri
                     [
                       "v", ["2"];
                       "shelf", [s];]

  let fetch t req =
    Client.get ~ctx:t.ctx req >>= fun (_resp, body) ->
    body
    |> Cohttp_lwt.Body.to_string >>= fun xml ->
    from_string xml
    |> Lwt.return

  let fetch_books t _shelf =
    match t.api_key with
    | "" -> Lwt.return None
    |_ ->
    let req = build_uri t (READING "currently-reading") in
    fetch t req >>= fun (dtd, xml) ->
    let reviews = reviews_of_xml (dtd, xml) in
    let books = List.map (fun (rev: review) -> rev.book) reviews in
    Lwt.return (Some books)
end

