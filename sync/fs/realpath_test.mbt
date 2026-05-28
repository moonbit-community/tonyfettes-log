// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "realpath absolute" {
  let rp = @fs.realpath("moon.mod").replace_all(old="\\", new="/")
  assert_true(rp.has_suffix("/moon.mod"))
}

///|
#cfg(not(platform="windows"))
test "realpath link to absolute" {
  let dir = @fs.tmpdir(prefix="sync-realpath-absolute")
  defer cleanup_dir(dir)
  let target = "\{dir}/realpath_test.mbt"
  let link_path = "\{dir}/realpath_test_link_to_absolute.test"
  @fs.write_file(target, "abcd", create_mode=CreateNew)
  @fs.symlink(link_path, target~)
  inspect(@fs.realpath(link_path), content=@fs.realpath(target))
}

///|
#cfg(not(platform="windows"))
test "realpath link to relative" {
  let dir = @fs.tmpdir(prefix="sync-realpath-relative")
  defer cleanup_dir(dir)
  let target = "\{dir}/realpath_test.mbt"
  let link_path = "\{dir}/realpath_test_link_to_relative.test"
  @fs.write_file(target, "abcd", create_mode=CreateNew)
  @fs.symlink(link_path, target="realpath_test.mbt")
  inspect(@fs.realpath(link_path), content=@fs.realpath(target))
}

///|
#cfg(not(platform="windows"))
test "realpath link to dir" {
  let dir = @fs.tmpdir(prefix="sync-realpath-dir")
  defer cleanup_dir(dir)
  let target_dir = "\{dir}/target"
  let target = "\{target_dir}/realpath_test.mbt"
  let link_path = "\{dir}/realpath_test_link_to_dir.test"
  @fs.mkdir(target_dir)
  @fs.write_file(target, "abcd", create_mode=CreateNew)
  @fs.symlink(link_path, target=target_dir)
  inspect(
    @fs.realpath("\{link_path}/realpath_test.mbt"),
    content=@fs.realpath(target),
  )
}
