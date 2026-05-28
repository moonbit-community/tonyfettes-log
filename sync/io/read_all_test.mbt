// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
fn write_three_chunks(w : @io.PipeWrite) -> Unit raise {
  defer w.close()
  w.write(b"abcd")
  w.write(b"efgh")
  w.write(b"ijkl")
}

///|
test "read_all basic" {
  let (r, w) = @io.pipe()
  defer r.close()
  write_three_chunks(w)
  inspect(r.read_all().text(), content="abcdefghijkl")
}

///|
test "read_all large data" {
  let (r, w) = @io.pipe()
  defer r.close()
  w.write(Bytes::make(4097, 0))
  w.close()
  inspect(r.read_all().binary().length(), content="4097")
}
