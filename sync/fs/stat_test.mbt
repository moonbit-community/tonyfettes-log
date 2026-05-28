// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
#cfg(not(platform="windows"))
test "stat" {
  let dir = @fs.tmpdir(prefix="sync-stat")
  defer cleanup_dir(dir)
  let target = "\{dir}/target"
  let link_path = "\{dir}/fs_stat_test"
  @fs.write_file(target, "abcd", create_mode=CreateNew)
  @fs.symlink(link_path, target~)
  debug_inspect(@fs.kind(link_path), content="Regular")
  debug_inspect(@fs.kind(link_path, follow_symlink=false), content="SymLink")
}
