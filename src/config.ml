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

let http_port =
  let doc = Key.Arg.info
      ~doc: "Port to listen on for plain HTTP connections"
      ~docv: "PORT" ["http-port"]
  in
  Key.(create "http-port" Arg.(opt ~stage: `Both int 8080 doc))

let host_key =
  let doc = Key.Arg.info
      ~doc: "Hostname of the unikernel"
      ~docv:"URL" ~env:"HOST" ["host"]
  in
  Key.(create "host" Arg.(opt string "localhost" doc))

let keys = Key.([abstract host_key; abstract http_port; abstract build_id])

let fs_key = Key.(value @@ kv_ro ())
let filesfs = generic_kv_ro ~key:fs_key "../files"
let tmplfs = generic_kv_ro ~key:fs_key "../tmpl"

let stack = generic_stackv4 default_network

let http =
  foreign ~keys "Dispatch.Make"
    (http @-> kv_ro @-> kv_ro @-> pclock @-> job)

let dispatch = (http $ http_server (conduit_direct stack))

let packages = [package "cow"; package "cowabloga"; package ~ocamlfind:["rrd"]
                  ~min:"1.0.1" "xapi-rrd"; package "c3"; package "astring";
                package "yaml"; package "ezjsonm"; package "re";
               package "duration"; package "ptime"; package "core_kernel"]

let () =
  let tracing = None in
  register ?tracing ~packages image [
    dispatch $ filesfs $ tmplfs $default_posix_clock
  ]
