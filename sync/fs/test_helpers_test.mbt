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
fn cleanup_dir(path : String) -> Unit {
  @fs.rmdir(path, recursive=true) catch {
    _ => ()
  }
}

///|
fn make_walk_fixture(prefix : String) -> String raise {
  let root = @fs.tmpdir(prefix~)
  @fs.mkdir("\{root}/inner1/inner2", recursive=true)
  @fs.write_file("\{root}/file", "", create_mode=CreateNew)
  @fs.write_file("\{root}/inner1/file", "", create_mode=CreateNew)
  @fs.write_file("\{root}/inner1/inner2/file", "", create_mode=CreateNew)
  root
}
