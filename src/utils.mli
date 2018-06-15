(** Custom implementation of some basic lists types, so we don't need to depend on base.
    Largely copied from: https://github.com/janestreet/base/blob/master/src/list.ml.
*)

val sub: 'a list -> pos:int -> len: int -> 'a list


(** Take [amount] of items from the given list, starting at the given [offset].
    If not enough items remain in the list, a truncated list will be returned.
*)
val take: int -> int -> 'a list -> 'a list

val foldi: 'a list -> init:'b -> f:(int -> 'b -> 'a -> 'b) -> 'b

val groupi: 'a list -> break:(int -> 'a -> 'a -> bool) -> 'a list list

val group: 'a list -> break:('a -> 'a -> bool) -> 'a list list

module Style: sig

  val centered_content: Cow.Html.t -> ?spacing: string -> unit -> Cow.Html.t
end
