open Incr_dom

module Model: sig
  type t [@@deriving sexp, compare]

  val create: string -> t

end

module Action : sig
  type t
end

val view : Model.t Incr.t
  -> Vdom.Node.t Incr.t

