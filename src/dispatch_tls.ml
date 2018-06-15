open Lwt.Infix

module Make
    (S: Mirage_stack_lwt.V4)
    (KEYS: Mirage_types_lwt.KV_RO)
    (FS: Mirage_types_lwt.KV_RO)
    (TMPL: Mirage_types_lwt.KV_RO)
    (Clock: Mirage_types.PCLOCK)
= struct
  let log_src = Logs.Src.create "dispatch_tls" ~doc:"https-tls server"
  module Log = (val Logs.src_log log_src: Logs.LOG)

  module TCP = S.TCPV4
  module TLS = Tls_mirage.Make (TCP)
  module X509 = Tls_mirage.X509 (KEYS) (Clock)

  module Http = Cohttp_mirage.Server(TCP)
  module Https = Cohttp_mirage.Server(TLS)

  (**module D = Dispatch.Make(Http)(FS)(TMPL)(Clock)*)
  module DS = Dispatch.Make(Https)(FS)(TMPL)(Clock)

  let log str =
    Log.debug (fun f -> f "%s" str)

  let with_tls cfg tcp ~f =
    let peer, port = TCP.dst tcp in
    let log str=  Log.debug (fun f -> f "[%s:%d] %s" (Ipaddr.V4.to_string peer) port str) in
    let tls_server k = TLS.server_of_flow cfg tcp >>= k in
    log "Starting TLS.";
    tls_server @@ function
    | Error _ -> log "TLS failed"; TCP.close tcp
    | Ok tls -> log "TLS ok"; f tls >>= fun () -> TLS.close tls

  (**let with_http host flow =
    let domain = `Https, host in
    let t = D.create domain (D.redirect domain) in
     Http.listen t flow*)

  let tls_init kv =
    X509.certificate kv `Default >>= fun cert ->
    let conf = Tls.Config.server ~certificates:(`Single cert) () in
    Lwt.return conf

  let start stack keys fs tmpl clock () =
    log "In the start";
    let host = Key_gen.host () in
    let https_port = Key_gen.https_port () in
    let redirect = Key_gen.redirect () in
    let host = host ^ ":" ^ (string_of_int https_port) in
    tls_init keys >>= fun cfg ->
    let domain = `Https, host in
    let dispatch = match redirect with
      | None -> DS.dispatch domain fs tmpl
      | Some domain -> DS.redirect (Dispatch.domain_of_string domain)
    in
    let callback = Https.listen (DS.create domain dispatch) in
    let https flow = with_tls cfg flow ~f:callback in
    (**let http flow = with_http host flow in*)
    S.listen_tcpv4 stack ~port:(Key_gen.https_port ()) https;
      (**S.listen_tcpv4 stack ~port:(Key_gen.http_port ()) http;*)
    S.listen stack
end
