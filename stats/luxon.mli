

type t = private Ojs.t
val t_of_js: Ojs.t -> t
val t_to_js: t -> Ojs.t

val local: unit -> t [@@js.new "luxon.DateTime.local"]

val to_string: t -> string [@@js.call]



