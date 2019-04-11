type book = {
  title: string;
  author: string;
  image_url: Uri.t;
  link: Uri.t;
}

type review = {
  id: int;
  book: book;
}

type action = PROFILE
            | READING of string

