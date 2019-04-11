type book = {
  title: string;
  image_url: Uri.t;
}

type review = {
  id: int;
  book: book;
}

type action = PROFILE
            | READING of string

