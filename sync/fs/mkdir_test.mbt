// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "mkdir" {
  let dir = @fs.tmpdir(prefix="sync-mkdir")
  defer cleanup_dir(dir)
  let path = "\{dir}/mkdir_test"
  @fs.mkdir(path)
  @fs.write_file("\{path}/file", "", create_mode=CreateOrTruncate)
  let result = @fs.readdir(path, sort=true)
  debug_inspect(result, content="[\"file\"]")
}

///|
#cfg(not(platform="windows"))
test "rmdir recursive" {
  let dir = @fs.tmpdir(prefix="sync-rmdir")
  defer cleanup_dir(dir)
  let path = "\{dir}/rmdir_test"
  @fs.mkdir(path, permission=0o755)
  @fs.write_file("\{path}/file", "", create_mode=CreateOrTruncate)
  @fs.mkdir("\{path}/inner")
  @fs.write_file("\{path}/inner/file", "", create_mode=CreateOrTruncate)
  @fs.symlink("\{path}/symlink", target="../../target")
  let result = try? @fs.rmdir(path)
  @fs.rmdir(path, recursive=true)
  assert_true(result is Err(_))
}

///|
test "mkdir recursive" {
  let dir = @fs.tmpdir(prefix="sync-recursive-mkdir")
  defer cleanup_dir(dir)
  let base_path = "\{dir}/recursive_mkdir"
  let path = "\{base_path}/test//directory"
  @fs.mkdir(path, recursive=true)
  json_inspect(@fs.readdir(base_path), content=["test"])
  json_inspect(@fs.readdir("\{base_path}/test"), content=["directory"])
  json_inspect(@fs.readdir("\{base_path}/test/directory"), content=[])
}
