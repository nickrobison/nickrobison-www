open! Core_kernel
open! Incr_dom

module Model : sig
  type t [@@deriving compare, sexp]

  val cutoff: t -> t -> bool
end

module Action : sig
  type t = UpdateGraph of (float * float) list [@@deriving sexp]
end

val apply_action : Action.t -> Model.t -> Model.t

val view: Model.t Incr.t
  -> Vdom.Node.t Incr.t

val create: string -> Model.t
