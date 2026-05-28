// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "write_at" {
  let dir = @fs.tmpdir(prefix="sync-write-at")
  defer cleanup_dir(dir)
  let path = "\{dir}/write_at_test"
  @fs.write_file(path, "abcdef", create_mode=CreateOrTruncate, sync=Full)
  inspect(@fs.read_file(path).text(), content="abcdef")
  {
    let w = @fs.open(path, mode=WriteOnly)
    defer w.close()
    w.write_at(b"56", position=w.size() - 2L)
    w.write_at(b"34", position=2L)
    w.write("12")
  }
  let r = @fs.open(path, mode=ReadOnly)
  defer r.close()
  inspect(r.read_all().text(), content="123456")
}

///|
test "read_at" {
  let dir = @fs.tmpdir(prefix="sync-read-at")
  defer cleanup_dir(dir)
  let path = "\{dir}/read_at_test"
  @fs.write_file(path, "abcdef", create_mode=CreateOrTruncate, sync=Full)
  let r = @fs.open(path, mode=ReadOnly)
  defer r.close()
  json_inspect(r.read_exactly_at(2, position=r.size() - 2L), content="ef")
  json_inspect(r.read_exactly_at(2, position=2L), content="cd")
  json_inspect(r.read_exactly(2), content="ab")
  let buf = FixedArray::make(2, b'\x00')
  let n = r.read_at(buf, position=5L)
  inspect(n, content="1")
  json_inspect(buf.unsafe_reinterpret_as_bytes()[:n], content="f")
}
