open Lwt.Infix

module Make
    (S: Mirage_stack.V4)
    (KEYS: Mirage_kv.RO)
    (FS: Mirage_kv.RO)
    (TMPL: Mirage_kv.RO)
    (Clock: Mirage_clock.PCLOCK)
    (RES: Resolver_lwt.S)
    (CON: Conduit_mirage.S)
= struct
  let log_src = Logs.Src.create "dispatch_tls" ~doc:"https-tls server"
  module Log = (val Logs.src_log log_src: Logs.LOG)

  module TCP = S.TCPV4
  module TLS = Tls_mirage.Make (TCP)
  module X509 = Tls_mirage.X509 (KEYS) (Clock)

  module Http = Cohttp_mirage.Server(TCP)
  module Https = Cohttp_mirage.Server(TLS)

  module D = Dispatch.Make(Http)(FS)(TMPL)(Clock)(RES)(CON)
  module DS = Dispatch.Make(Https)(FS)(TMPL)(Clock)(RES)(CON)

  let with_tls cfg tcp ~f =
    let peer, port = TCP.dst tcp in
    let log str=  Log.debug (fun f -> f "[%s:%d] %s" (Ipaddr.V4.to_string peer) port str) in
    let tls_server k = TLS.server_of_flow cfg tcp >>= k in
    tls_server @@ function
    | Error _ -> log "TLS failed"; TCP.close tcp
    | Ok tls -> log "TLS ok"; f tls >>= fun () -> TLS.close tls

  let with_http host flow =
    let domain = `Https, host in
    let t = D.create domain (D.redirect domain) in
     Http.listen t flow

  let tls_init kv =
    X509.certificate kv `Default >>= fun cert ->
    let conf = Tls.Config.server ~certificates:(`Single cert) () in
    Lwt.return conf

  let start stack keys fs tmpl _clock dns ctx () =
    let build_id = Key_gen.build_id () in
    let host = Key_gen.host () in
    let sleep sec = OS.Time.sleep_ns (Duration.of_sec sec) in
    Stats.start ~sleep ~time:(fun () -> Clock.now_d_ps clock);
    let https_port = Key_gen.https_port () in
    let redirect = Key_gen.redirect () in
    let host = host ^ ":" ^ (string_of_int https_port) in
    tls_init keys >>= fun cfg ->
    let domain = `Https, host in
    let dispatch = match redirect with
      | None -> DS.dispatch domain fs tmpl dns ctx
      | Some domain -> DS.redirect (Dispatch.domain_of_string domain)
    in
    let callback = Https.listen (DS.create domain dispatch) in
    let https flow = with_tls cfg flow ~f:callback in
    let http flow = with_http host flow in
    S.listen_tcpv4 stack ~port:(Key_gen.https_port ()) https;
    S.listen_tcpv4 stack ~port:(Key_gen.http_port ()) http;
    Log.info (fun f -> f "Build version: %s" build_id);
    Log.info (fun f -> f "Listening on %s" (Site_config.base_uri domain));
    S.listen stack
end
