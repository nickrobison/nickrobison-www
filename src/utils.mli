(** Take [amount] of items from the given list, starting at the given [offset].
    If not enough items remain in the list, a truncated list will be returned.

val take: int -> int -> 'a list -> 'a list
*)

val foldi: 'a list -> init:'b -> f:(int -> 'b -> 'a -> 'b) -> 'b

val groupi: 'a list -> break:(int -> 'a -> 'a -> bool) -> 'a list list

val group: 'a list -> break:('a -> 'a -> bool) -> 'a list list

