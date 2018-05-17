(** Take [amount] of items from the given list, starting at the given [offset].
    If not enough items remain in the list, a truncated list will be returned.
*)
val take: int -> int -> 'a list -> 'a list
