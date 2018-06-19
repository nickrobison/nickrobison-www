let foldi t ~init ~f =
  snd (List.fold_left (fun (i, acc) v -> (i + 1, f i acc v)) (0, init) t)

let sub l ~pos ~len =
  if pos < 0 || len < 0 || pos > List.length l - len then raise (Invalid_argument "Utils.sub");
  List.rev
    (foldi l ~init: [] ~f:(fun i acc el ->
         if i >= pos && i < (pos + len)
         then el :: acc
         else acc))

let take offset amount list =
  let sub_list = sub list offset ((List.length list) - 1)
  in
  let rec take_rec amount list =
    match amount with
    | 0 -> []
    | x -> match list with
      | [] -> []
      | hd :: tl -> hd :: take_rec (amount - 1) tl
  in
  take_rec amount sub_list

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


module Style = struct
  open Cow.Html

  let centered_content content ?spacing () =
  let grid_cls = match spacing with
    | None -> "cell"
    | Some e -> "cell " ^ e
  in
   list [
        div ~cls:"grid-x grid-margin-x" (list [
            (div ~cls:grid_cls content);
          ]);
      ]

end
