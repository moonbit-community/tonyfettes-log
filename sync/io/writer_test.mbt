// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "write large data" {
  let (r, w) = @io.pipe()
  defer r.close()
  let data = Bytes::make(1024 * 16, 0)
  w.write(data)
  w.close()
  inspect(r.read_all().binary().length(), content="16384")
}

///|
test "write reader" {
  let (r1, w1) = @io.pipe()
  let (r2, w2) = @io.pipe()
  defer r1.close()
  defer r2.close()
  write_three_chunks(w2)
  w1.write_reader(r2)
  w1.close()
  let log = StringBuilder::new()
  while r1.read_some() is Some(data) {
    let data = @utf8.decode(data)
    log.write_string("received \{data}\n")
  }
  inspect(
    log.to_string(),
    content=(
      #|received abcd
      #|received efgh
      #|received ijkl
      #|
    ),
  )
}

///|
test "write_string" {
  let (r, w) = @io.pipe()
  defer r.close()
  w.write("abcd中文☺")
  w.close()
  inspect(r.read_all().text(), content="abcd中文☺")
}
