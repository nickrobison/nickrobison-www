
type t = private Ojs.t

type units =
  | Minutes
  | Seconds
  | Days
  | Years
[@@js.enum]


module Duration: sig

  type t

  val from_millis: float -> t [@@js.new "luxon.Duration.fromMillis"]

  val as_it: t -> units -> float [@@js.call "as"]

end

module DateTime: sig
  type t

  val t_of_js: Ojs.t -> t
  val t_to_js: t -> Ojs.t

  val local: unit -> t [@@js.new "luxon.DateTime.local"]

  val to_string: t -> string [@@js.call]
  val to_relative: t -> string [@@js.call]
  val plus: t -> Duration.t -> t [@@js.call]
  val minus: t -> Duration.t -> t [@@js.call]
end




