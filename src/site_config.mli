open Www_types

val base_uri: domain -> string
(** [base_uri d] is the base URI of the domain [d]. *)

val uri: domain -> path -> Uri.t
                             (** [uri d p] is the URI with the domain [d] and the path [p]. *)
