open! Core_kernel
open! Incr_dom

module Model : sig
  type t [@@deriving compare, sexp]
end

module Action : sig
  type t [@@deriving sexp]
end


val view: Model.t Incr.t
  -> Vdom.Node.t Incr.t

val create: string -> Model.t
