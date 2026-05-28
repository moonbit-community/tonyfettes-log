// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "read_all basic" {
  let dir = @fs.tmpdir(prefix="sync-read-all")
  defer cleanup_dir(dir)
  let path = "\{dir}/read_all_test"
  @fs.write_file(path, "abcdefghijkl", create_mode=CreateNew)
  let r = @fs.open(path, mode=ReadOnly)
  defer r.close()
  inspect(r.read_all().text(), content="abcdefghijkl")
}

///|
test "read_all large data" {
  let dir = @fs.tmpdir(prefix="sync-read-all-large")
  defer cleanup_dir(dir)
  let path = "\{dir}/read_all_large_test"
  @fs.write_file(path, Bytes::make(4097, 0), create_mode=CreateNew)
  let r = @fs.open(path, mode=ReadOnly)
  defer r.close()
  inspect(r.read_all().binary().length(), content="4097")
}
