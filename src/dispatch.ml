open Lwt.Infix

let err fmt = Fmt.kstrf failwith fmt

module Make
    (S: Cohttp_lwt.S.Server)
    (FS: Mirage_types_lwt.KV_RO)
    (TMPL: Mirage_types_lwt.KV_RO)
    (Clock: Mirage_types.PCLOCK)
= struct
  open Www_types


  let log_src = Logs.Src.create "dispatch" ~doc:"Web server"
  module Log = (val Logs.src_log log_src: Logs.LOG)


  type dispatch = path -> cowabloga Lwt.t
  type s = Conduit_mirage.server -> S.t -> unit Lwt.t

  let size_then_read ~pp_error ~size ~read device name =
    size device name >>= function
    | Error e -> err "%a" pp_error e
    | Ok size ->
      read device name 0L size >>= function
      | Error e -> err "%a" pp_error e
      | Ok bufs -> Lwt.return (Cstruct.copyv bufs)

  let tmpl_read =
    size_then_read ~pp_error:TMPL.pp_error ~size:TMPL.size ~read:TMPL.read

  let cowabloga (x:contents): cowabloga = match x with
    | `Html _ | `Page _ as e -> e
    | `Not_found p -> `Not_found (Uri.to_string p)
    | `Redirect p -> `Redirect (Uri.to_string p)

  let mk f path = f >|= (fun f -> cowabloga (f path))

  let test () =
    Lwt.return (`Html (Lwt.return "Hello world"))

  let fs_read = size_then_read ~pp_error:FS.pp_error ~size:FS.size ~read:FS.read

    let not_found domain path =
    let uri = Site_config.uri domain path in
    let uri = Uri.to_string uri in
    Lwt.return (`Not_found uri)

  let asset domain fs path =
    let path_s = String.concat "/" path in
    let asset () = Lwt.return (`Asset (fs_read fs path_s)) in
    Lwt.catch asset (fun e ->
        Log.warn (fun f ->
            f "got error while getting %s: %s" path_s (Printexc.to_string e));
        not_found domain path)

  let read_entry tmpl name = tmpl_read tmpl name >|= Cow.Markdown.of_string

  let respond_ok ?(headers=[]) body =
    body >>= fun body ->
    let status = `OK in
    let headers = Cohttp.Header.of_list headers in
    S.respond_string ~headers ~status ~body ()

  (** Page feeds. *)

  let blog_feed domain tmpl =
    Data.Feed.blog domain (fun n -> read_entry tmpl ("/blog/"^n))

  let updates_feed domain tmpl =
    Data.Feed.updates domain (read_entry tmpl)

  let updates_feeds domain tmpl =
    tmpl_read tmpl "posts.json" >>= fun posts ->
    let entries = Data.Blog.entries posts in
    Lwt.return([
      `Blog (blog_feed domain tmpl, entries);
    ])

  (** Page types *)

  let updates domain tmpl =
    let feed = updates_feed domain tmpl in
    let read = tmpl_read tmpl in
    updates_feeds domain tmpl >>= fun feeds ->
    Pages.Updates.dispatch ~domain ~feed ~feeds ~read

  let index domain tmpl =
    let read = tmpl_read tmpl in
    updates_feeds domain tmpl >>= fun feeds ->
    Pages.Index.t ~domain ~feeds ~read >|= cowabloga

  let blog domain tmpl =
    let feed = blog_feed domain tmpl in
    tmpl_read tmpl "posts.json" >>= fun posts ->
    let entries = Data.Blog.entries posts in
    let read = tmpl_read tmpl in
    Blog.dispatch ~domain ~feed ~entries ~read

  let dispatch domain fs tmpl =
    let index = index domain tmpl in
    let blog = blog domain tmpl in
    let updates = updates domain tmpl in
    function
    | ["index.html"]
    | [""] | [] -> index
    | "blog" :: tl -> mk blog tl
    | "updates" :: tl -> mk updates tl
    | path -> asset domain fs path

  let not_found ~uri () =
    S.respond_not_found ~uri ()

  let moved_permanently ~uri () =
    let headers = Cohttp.Header.init_with "location" (Uri.to_string uri) in
    S.respond ~headers ~status:`Moved_permanently ~body:`Empty ()

  let create domain dispatch =
    let hdr = match fst domain with `Http -> "HTTP" | `Https -> "HTTPS" in
    let callback (_, conn_id) request _body =
      let uri = Cohttp.Request.uri request in
      let cid = Cohttp.Connection.to_string conn_id in
      let io = {
        Cowabloga.Dispatch.log = (fun ~msg -> Log.debug (fun f -> f "[%s %s] %s" hdr cid msg));
          ok = respond_ok;
          notfound = (fun ~uri -> not_found ~uri ());
          redirect = (fun ~uri -> moved_permanently ~uri ());
        } in
      Cowabloga.Dispatch.f io dispatch uri
    in
    let conn_closed (_, conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      Log.debug (fun f -> f "[%s %s] OK, closing" hdr cid)
    in
    S.make ~callback ~conn_closed ()


  let start http fs tmpl clock =
    let host = Key_gen.host () in
    let http_port = Key_gen.http_port () in
    let host = host ^ ":" ^ (string_of_int http_port) in
    let domain = `Http, host in
    let dispatch = dispatch domain fs tmpl in
    let callback = create domain dispatch in
    let build_id = Key_gen.build_id () in
    Log.info (fun f -> f "Build version: %s" build_id);
    Log.info (fun f -> f "Listening on %s" (Site_config.base_uri domain));
      http (`TCP (Key_gen.http_port ())) callback

end

