open Lwt.Infix

module Make
    (RES: Resolver_lwt.S)
    (CON: Conduit_mirage.S)
= struct

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

  let build_request t =
    let str = "https://www.goodreads.com/search.xml?key=" ^ t.api_key ^ "&q=Ender%27s+Game" in
    Uri.of_string str


  let fetch t =
    let req = build_request t in
    Cohttp_mirage.Client.get ~ctx:t.ctx req >>= fun (resp, body) -> Lwt.return (Sexplib.Sexp.to_string_hum (Cohttp.Response.sexp_of_t resp))




end
