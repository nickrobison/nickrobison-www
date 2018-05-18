
(**
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
*)

let foldi t ~init ~f =
  snd (List.fold_left (fun (i, acc) v -> (i + 1, f i acc v)) (0, init) t)

let groupi l ~break =
  let groups =
    foldi l ~init:[] ~f:(fun i acc x ->
        match acc with
        | [] -> [[x]]
        | current_group :: tl ->
          if break i (List.hd current_group) x then
            [x] :: current_group :: tl (* Start new group *)
          else
            (x :: current_group) :: tl) (*Extend current group*)
  in
  match groups with
  | [] -> []
  | l -> List.rev_map List.rev l

let group l ~break = groupi l ~break:(fun _ x y -> break x y)
