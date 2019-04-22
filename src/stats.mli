val dispatch:
  Www_types.dispatch

val start: sleep: (int -> unit Lwt.t) -> time: (unit -> (int * int64)) -> unit

(**
   val get_rrd_updates: Uri.t -> string Lwt.t

   val get_rrd_timescales: Uri.t -> string
   **)

val total_requests: int ref

val total_errors: int ref
