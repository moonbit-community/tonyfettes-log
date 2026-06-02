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
fn cleanup_os_error_dir(path : String) -> Unit {
  @fs.rmdir(path, recursive=true) catch {
    _ => ()
  }
}

///|
test "is_ENOENT" {
  let result = capture_result(() => @fs.open("does_not_exist", mode=ReadOnly))
  guard result is Err(@os_error.OSError(_) as err) else {
    fail("result is not OSError")
  }
  assert_true(err.is_ENOENT())
}

///|
test "is_EEXIST" {
  let dir = @fs.tmpdir(prefix="sync-os-error")
  defer cleanup_os_error_dir(dir)
  let existing = "\{dir}/existing"
  @fs.mkdir(existing)
  let result = capture_result(() => @fs.mkdir(existing, permission=0o755))
  guard result is Err(@os_error.OSError(_) as err) else {
    fail("result is not OSError")
  }
  assert_true(err.is_EEXIST())
}
