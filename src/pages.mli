open Www_types

type t = read:string read -> domain:domain -> contents Lwt.t

module Global: sig
  (** Global page template. *)

  val t: title:string -> headers:Cow.Html.t -> content:Cow.Html.t -> t
end


module Index: sig
  (** The main index page. *)

  val t: t 
end
