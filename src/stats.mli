val dispatch:
  read:string Www_types.read ->
  Www_types.dispatch

val start: sleep: (int -> unit Lwt.t) -> time: (unit -> (int * int64)) -> unit

val get_rrd_updates: uri: Uri.t -> string Lwt.t

val get_rrd_timescales: unit-> string Lwt.t

val total_requests: int ref

val total_errors: int ref
