open Www_types

type t = read:string read -> domain:domain -> contents Lwt.t

module Entry: sig
  type t = {
    title: string;
    location: string;
    description: string;
  }
end


val t: projects: Data.Projects.t list -> t
