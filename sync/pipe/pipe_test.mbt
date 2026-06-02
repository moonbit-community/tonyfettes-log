// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
fn[T, E : Error] capture_result(f : () -> T raise E) -> Result[T, E] noraise {
  try f() catch {
    err => Err(err)
  } noraise {
    value => Ok(value)
  }
}

///|
test "pipe read write" {
  let (r, w) = @pipe.pipe()
  defer r.close()
  w.write("abcdef")
  w.close()
  inspect(@utf8.decode(r.read_exactly(3)), content="abc")
  inspect(r.read_all().text(), content="def")
}

///|
test "pipe EOF" {
  let (r, w) = @pipe.pipe()
  defer r.close()
  w.close()
  assert_true(r.read_some() is None)
}

///|
test "read_exactly buffers chunks" {
  let (r, w) = @pipe.pipe()
  defer r.close()
  w.write("abcdef")
  w.write("ghijkl")
  w.close()
  inspect(@utf8.decode(r.read_exactly(4)), content="abcd")
  inspect(@utf8.decode(r.read_exactly(4)), content="efgh")
  inspect(@utf8.decode(r.read_exactly(4)), content="ijkl")
}

///|
test "read_exactly failure" {
  let (r, w) = @pipe.pipe()
  defer r.close()
  w.write("abcdef")
  w.close()
  inspect(@utf8.decode(r.read_exactly(4)), content="abcd")
  assert_true(capture_result(() => r.read_exactly(4)) is Err(_))
}

///|
test "reader closed" {
  let (r, w) = @pipe.pipe()
  defer w.close()
  r.close()
  assert_true(capture_result(() => w.write("abcd")) is Err(_))
}
