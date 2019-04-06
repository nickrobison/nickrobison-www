open Lwt.Infix

module Make
    (S: Cohttp_lwt.S.Server)
    (FS: Mirage_types_lwt.KV_RO)
    (TMPL: Mirage_types_lwt.KV_RO)
= struct
  open Www_types

  let log_src = Logs.Src.create "cache" ~doc:"Page cache"
  module Log = (val Logs.src_log log_src: Logs.LOG)

  type t = {
    table: (domain, cowabloga) Hashtbl.t;
  }

  let create () =
    let table = Hashtbl.create 2 in
    {table}

  let fetch cache loc tmpl f =
    Log.info (fun f -> f "Fetching from cache");
    match (Hashtbl.find_opt cache.table loc) with
    | Some l -> Log.info (fun f -> f "Has in cache");
      Lwt.return l
    | None ->
      Log.info (fun f -> f "Cache miss, building.");
      f loc tmpl >>= fun cow ->
      Hashtbl.add cache.table loc cow;
      Lwt.return cow
end
