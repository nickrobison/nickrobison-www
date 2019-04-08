open Lwt.Infix
open Ezxmlm

module Make
    (RES: Resolver_lwt.S)
    (CON: Conduit_mirage.S)
= struct

  type book = {
    title: string;
    image_url: Uri.t;
  }


  type review = {
    id: int;
    book: book;
  }

  type action = PROFILE
              | READING of string

  type t = {
    api_key: string;
    user_id: string;
    ctx: Cohttp_mirage.Client.ctx;
  }

  let create ~key ~id res ctx =
    let ctx = Cohttp_mirage.Client.ctx res ctx in
    {
      api_key = key;
      user_id = id;
      ctx = ctx;
    }

  let build_review review =
    let id = data_to_string (member "id" review) in
    let book = member "book" review in
    let b =
      {
        title = data_to_string (member "title" book);
        image_url = Uri.of_string (data_to_string (member "image_url" book))
      } in
    {
      id = int_of_string id;
      book = b;
    }

  let reviews_of_xml (dtd, xml) =
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
    (** Add any additional query params that we might need*)
    match action with
    | PROFILE -> uri
    | READING s -> Uri.add_query_params uri
                     [
                       "v", ["2"];
                       "shelf", [s];]

  let fetch t req =
    Cohttp_mirage.Client.get ~ctx:t.ctx req >>= fun (resp, body) ->
    body
    |> Cohttp_lwt.Body.to_string >>= fun xml ->
    from_string xml
    |> Lwt.return

  let fetch_books t shelf =
    let req = build_uri t (READING "currently-reading") in
    fetch t req >>= fun (dtd, xml) ->
    reviews_of_xml (dtd, xml)
    |> List.map (fun rev -> rev.book)
    |> Lwt.return


end
