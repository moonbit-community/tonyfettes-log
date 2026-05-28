// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "exists" {
  assert_true(@fs.exists("moon.mod"))
  @fs.open("moon.mod", mode=ReadOnly).close()
  assert_false(@fs.exists("moon.mod.not_exist"))
  try @fs.open("moon.mod.not_exist", mode=ReadOnly) catch {
    @os_error.OSError(_) as err if err.is_ENOENT() => ()
    err => fail("incorrect error: \{err}")
  } noraise {
    file => {
      file.close()
      fail("`@fs.open` succeeded unexpectedly")
    }
  }
}

///|
test "can_read" {
  assert_true(@fs.can_read("moon.mod"))
}

///|
test "can_write" {
  assert_true(@fs.can_write("moon.mod"))
}

///|
#cfg(not(platform="windows"))
test "can_execute" {
  assert_false(@fs.can_execute("moon.mod"))
}

///|
#cfg(not(platform="windows"))
test "chmod" {
  let dir = @fs.tmpdir(prefix="sync-chmod")
  defer cleanup_dir(dir)
  let path = "\{dir}/chmod_test"
  @fs.write_file(path, "abcd", create_mode=CreateNew, permission=0o444)
  inspect(@fs.can_read(path), content="true")
  inspect(@fs.can_write(path), content="false")
  inspect(@fs.can_execute(path), content="false")
  @fs.chmod(path, 0o644)
  inspect(@fs.can_read(path), content="true")
  inspect(@fs.can_write(path), content="true")
  inspect(@fs.can_execute(path), content="false")
  @fs.chmod(path, 0o755)
  inspect(@fs.can_read(path), content="true")
  inspect(@fs.can_write(path), content="true")
  inspect(@fs.can_execute(path), content="true")
}
