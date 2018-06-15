open Mirage

let get ~default name =
  try String.lowercase_ascii @@ Sys.getenv name
  with Not_found -> default

let image = get "KVMIMG" ~default:"nickrobison-www"

let build_id =
  let doc = Key.Arg.info
      ~doc: "Build number"
      ~docv: "BUILD" ["build-id"]
  in
  Key.(create "build-id" Arg.(opt string (string_of_float (Unix.time ())) doc))

let tls_key =
  let doc = Key.Arg.info
      ~doc:"Enable serving the website over https. Do not forget to put certificates in tls/"
      ~docv:"BOOL" ~env:"TLS" ["tls"]
  in
  Key.(create "tls" Arg.(opt ~stage:`Configure bool false doc))

let http_port =
  let doc = Key.Arg.info
      ~doc: "Port to listen on for plain HTTP connections"
      ~docv: "PORT" ["http-port"]
  in
  Key.(create "http-port" Arg.(opt ~stage: `Both int 8080 doc))

let https_port =
  let doc = Key.Arg.info
      ~doc:"Port to listen in for HTTPS connections"
      ~docv:"PORT" ["https-port"]
  in
  Key.(create "https-port" Arg.(opt ~stage:`Both int 443 doc))

let host_key =
  let doc = Key.Arg.info
      ~doc: "Hostname of the unikernel"
      ~docv:"URL" ~env:"HOST" ["host"]
  in
  Key.(create "host" Arg.(opt string "localhost" doc))

let redirect_key  =
  let doc = Key.Arg.info
      ~doc:"Where to send the redirects. Must start with http:// or https://. \
            When tls is enabled, the default is https://$HOST."
      ~docv:"URL" ~env:"REDIRECT" ["redirect"]
  in
  Key.(create "redirect" Arg.(opt (some string) None doc))

let keys = Key.([abstract host_key; abstract redirect_key;
                 abstract http_port; abstract https_port;
                 abstract build_id])

let fs_key = Key.(value @@ kv_ro ())
let filesfs = generic_kv_ro ~key:fs_key "../files"
let tmplfs = generic_kv_ro ~key:fs_key "../tmpl"

let secrets_key = Key.(value @@ kv_ro ~group:"secrets" ())
let secrets = generic_kv_ro ~key:secrets_key "../tls"

let stack = generic_stackv4 default_network

let http =
  foreign ~keys "Dispatch.Make"
    (http @-> kv_ro @-> kv_ro @-> pclock @-> job)

let https =
  let packages = [package ~sublibs:["mirage"] "tls"; package "mirage-http"] in
  foreign ~packages ~keys "Dispatch_tls.Make"
    ~deps:[abstract nocrypto]
    (stackv4 @-> kv_ro @-> kv_ro @-> kv_ro @-> pclock @-> job)

let dispatch = if_impl (Key.value tls_key)
    (** With TLS *)
    (https $ stack $ secrets)
    (** HTTP only *)
    (http $ http_server (conduit_direct stack))

let packages = [package "cow"; package "cowabloga"; package "astring";
               package "ezjsonm"; package "re";
               package "duration"; package "ptime";]

let () =
  let tracing = None in
  register ?tracing ~packages image [
    dispatch $ filesfs $ tmplfs $default_posix_clock
  ]
