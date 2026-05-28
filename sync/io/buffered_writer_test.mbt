// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "BufferedWriter" {
  let (r, w) = @io.pipe()
  defer r.close()
  let w = @io.BufferedWriter::new(w, size=4)
  w.write("ab")
  w.write("cd")
  w.write("ef")
  inspect(@utf8.decode(r.read_exactly(4)), content="abcd")
  w.flush()
  inspect(r.read_all().text(), content="ef")
}

///|
test "BufferedWriter::write_reader" {
  let (r1, w1) = @io.pipe()
  let (r2, w2) = @io.pipe()
  defer r1.close()
  defer r2.close()
  write_three_chunks(w2)
  let w1 = @io.BufferedWriter::new(w1, size=6)
  w1.write_reader(r2)
  w1.flush()
  let log = StringBuilder::new()
  while r1.read_some() is Some(data) {
    let data = @utf8.decode(data)
    log.write_string("received \{data}\n")
  }
  inspect(
    log.to_string(),
    content=(
      #|received abcdef
      #|received ghijkl
      #|
    ),
  )
}
