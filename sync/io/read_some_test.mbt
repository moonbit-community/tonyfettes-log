// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "read_some basic" {
  let (r, w) = @io.pipe()
  defer r.close()
  write_three_chunks(w)
  let log = StringBuilder::new()
  while r.read_some() is Some(chunk) {
    log.write_string("received chunk: \{@utf8.decode(chunk)}\n")
  }
  inspect(
    log,
    content=(
      #|received chunk: abcd
      #|received chunk: efgh
      #|received chunk: ijkl
      #|
    ),
  )
}

///|
test "read_some length limit 1" {
  let (r, w) = @io.pipe()
  defer r.close()
  write_three_chunks(w)
  let log = StringBuilder::new()
  while r.read_some(max_len=2) is Some(chunk) {
    log.write_string("received chunk: \{@utf8.decode(chunk)}\n")
  }
  inspect(
    log,
    content=(
      #|received chunk: ab
      #|received chunk: cd
      #|received chunk: ef
      #|received chunk: gh
      #|received chunk: ij
      #|received chunk: kl
      #|
    ),
  )
}

///|
test "read_some length limit 2" {
  let (r, w) = @io.pipe()
  defer r.close()
  write_three_chunks(w)
  let log = StringBuilder::new()
  for max_len = 2; ; max_len = max_len * 2 {
    guard r.read_some(max_len~) is Some(chunk) else { break }
    log.write_string("received chunk: \{@utf8.decode(chunk)}\n")
  }
  inspect(
    log,
    content=(
      #|received chunk: ab
      #|received chunk: cd
      #|received chunk: efgh
      #|received chunk: ijkl
      #|
    ),
  )
}

///|
test "read_some length limit 3" {
  let (r, w) = @io.pipe()
  defer r.close()
  w.write("abcdefghijkl")
  w.close()
  let log = StringBuilder::new()
  for max_len = 2; ; max_len = max_len * 2 {
    guard r.read_some(max_len~) is Some(chunk) else { break }
    log.write_string("received chunk: \{@utf8.decode(chunk)}\n")
  }
  inspect(
    log,
    content=(
      #|received chunk: ab
      #|received chunk: cdef
      #|received chunk: ghijkl
      #|
    ),
  )
}
