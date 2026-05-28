// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
fn string_array_contains(xs : Array[String], needle : String) -> Bool {
  for x in xs {
    if x == needle {
      return true
    }
  }
  false
}

///|
test "read_all" {
  let dir = @fs.tmpdir(prefix="sync-dir")
  defer cleanup_dir(dir)
  @fs.mkdir("\{dir}/sub")
  @fs.write_file("\{dir}/file.txt", "", create_mode=CreateNew)
  @fs.write_file("\{dir}/.hidden", "", create_mode=CreateNew)
  let list = @fs.readdir(
    dir,
    include_hidden=false,
    include_special=false,
    sort=true,
  )
  assert_eq(list.length(), 2)
  assert_true(string_array_contains(list, "file.txt"))
  assert_true(string_array_contains(list, "sub"))
  let all = @fs.readdir(
    dir,
    include_hidden=true,
    include_special=true,
    sort=true,
  )
  assert_true(string_array_contains(all, ".hidden"))
}

///|
test "as_dir" {
  let dir = @fs.tmpdir(prefix="sync-as-dir")
  defer cleanup_dir(dir)
  @fs.write_file("\{dir}/file.txt", "", create_mode=CreateNew)
  let dir_file = @fs.open(dir, mode=ReadOnly)
  guard dir_file.kind() is Directory
  let opened_dir = dir_file.as_dir()
  defer opened_dir.close()
  let list = opened_dir.read_all()..sort()
  json_inspect(list, content=["file.txt"])
}

///|
test "readdir clear errno" {
  let dir = @fs.tmpdir(prefix="sync-dir-errno")
  defer cleanup_dir(dir)
  @fs.write_file("\{dir}/file.txt", "", create_mode=CreateNew)
  try @fs.open("\{dir}/does-not-exist", mode=ReadOnly) catch {
    _ => ()
  } noraise {
    file => file.close()
  }
  let list = @fs.readdir(dir, sort=true)
  json_inspect(list, content=["file.txt"])
}
