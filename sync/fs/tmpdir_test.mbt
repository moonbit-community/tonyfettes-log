// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "tmpdir" {
  let t1 = @fs.tmpdir(prefix="tmp")
  defer cleanup_dir(t1)
  let t2 = @fs.tmpdir(prefix="tmp")
  defer cleanup_dir(t2)
  assert_not_eq(t1, t2)
  assert_true(@fs.exists(t1))
  assert_true(@fs.exists(t2))
  @fs.write_file(
    "\{t1}/file.txt",
    "abcd",
    create_mode=CreateNew,
    permission=0o600,
  )
  json_inspect(@fs.readdir(t1), content=["file.txt"])
}
