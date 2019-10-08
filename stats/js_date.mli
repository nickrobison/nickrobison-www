type t = private Ojs.t
val t_of_js: Ojs.t -> t
val t_to_js: t -> Ojs.t

val now: unit -> t [@@js.new "Date"]

val to_string: t -> string [@@js.call]
