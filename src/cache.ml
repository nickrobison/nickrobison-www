module Make = struct
  type t = (Uri.t, string) Hashtbl.t

  let create () =
    let table = Hashtbl.create 2 in
    table

  let fetch fetcher loc =
    match (Hashtbl.find_opt fetcher loc) with
    | Some l -> Lwt.return l
    | None -> Hashtbl.add fetcher loc "something stored";
      Lwt.return "nothing"
end
