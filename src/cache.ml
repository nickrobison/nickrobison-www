open Lwt.Infix

module Make
    (S: Cohttp_lwt.S.Server)
    (FS: Mirage_kv.RO)
    (TMPL: Mirage_kv.RO)
    (PClock: Mirage_clock.PCLOCK)
= struct
  open Www_types

  let log_src = Logs.Src.create "cache" ~doc:"Page cache"
  module Log = (val Logs.src_log log_src: Logs.LOG)

  type value = {
    html: cowabloga;
    expires: Ptime.t;
  }

  type t = {
    table: (domain, value) Hashtbl.t;
    lifespan: Ptime.Span.t;
  }

  let create duration =
    let table = Hashtbl.create 2 in
    {
      table = table;
      lifespan = Ptime.Span.of_int_s (Duration.to_sec duration);
    }


  let fetch_if_not_expired cache loc =
    match (Hashtbl.find_opt cache.table loc) with
    | None -> None
    | Some html ->
      Log.info (fun f -> f "Found in cache, expired?");
      let now = PClock.now_d_ps () |> Ptime.v in
      if (Ptime.is_earlier now ~than:html.expires) then (Some html.html) else None


  let fetch cache loc tmpl f =
    Log.info (fun f -> f "Fetching from cache");
    match (fetch_if_not_expired cache loc) with
    | Some l ->
      Log.info (fun f -> f "Has in cache");
      Lwt.return l
    | None ->
      Log.info (fun f -> f "Cache miss, building.");
      f loc tmpl >>= fun cow ->
      let now = PClock.now_d_ps () |> Ptime.v in
      match (Ptime.add_span now cache.lifespan) with
      | Some s ->
        let value = {
          html = cow;
          expires = s;
        } in
        Hashtbl.add cache.table loc value;
        Lwt.return cow
      | None -> raise (Invalid_argument "Cannot create span value")
end
