// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "read EOF" {
  let dir = @fs.tmpdir(prefix="sync-eof")
  defer cleanup_dir(dir)
  let path = "\{dir}/read_eof_test"
  let buf = FixedArray::make(16, b'0')
  {
    let w = @fs.create(path, permission=0o644, sync=Full)
    defer w.close()
    w.write(b"abcd")
  }
  let n = {
    let r = @fs.open(path, mode=ReadOnly)
    defer r.close()
    r.read(buf)
  }
  assert_eq(n, 4)
  inspect(@utf8.decode(buf.unsafe_reinterpret_as_bytes()[0:n]), content="abcd")
}
