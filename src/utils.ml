open Core_kernel

let take offset amount list =
  let sub_list = List.sub list offset ((List.length list) - 1)
  in
  let rec take_rec amount list =
    match amount with
    | 0 -> []
    | x -> match list with
      | [] -> []
      | hd :: tl -> hd :: take_rec (amount - 1) tl
  in
  take_rec amount sub_list
