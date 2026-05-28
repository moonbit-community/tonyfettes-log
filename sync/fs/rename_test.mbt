// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "rename basic" {
  let dir = @fs.tmpdir(prefix="sync-rename")
  defer cleanup_dir(dir)
  let old_path = "\{dir}/rename_basic_test_old"
  let new_path = "\{dir}/rename_basic_test_new"
  let file = @fs.open(
    old_path,
    mode=WriteOnly,
    create_mode=CreateOrTruncate,
    sync=Full,
  )
  defer file.close()
  file.write("abcd")
  inspect(@fs.read_file(old_path).text(), content="abcd")
  @fs.rename(old_path, new_path)
  inspect(@fs.read_file(new_path).text(), content="abcd")
  file.write_at(b"ABCD", position=0L)
  inspect(@fs.read_file(new_path).text(), content="ABCD")
  inspect(@fs.exists(old_path), content="false")
}

///|
test "rename replace" {
  let dir = @fs.tmpdir(prefix="sync-rename-replace")
  defer cleanup_dir(dir)
  let old_path = "\{dir}/rename_replace_test_old"
  let new_path = "\{dir}/rename_replace_test_new"
  @fs.write_file(new_path, "xyzw", create_mode=CreateOrTruncate)
  let old_file = @fs.open(
    old_path,
    mode=WriteOnly,
    create_mode=CreateOrTruncate,
    sync=Full,
  )
  defer old_file.close()
  let new_file = @fs.open(new_path, mode=ReadOnly, create_mode=OpenExisting)
  defer new_file.close()
  old_file.write("abcd")
  inspect(@fs.read_file(old_path).text(), content="abcd")
  inspect(@fs.read_file(new_path).text(), content="xyzw")
  assert_true((try? @fs.rename(old_path, new_path, replace=false)) is Err(_))
  @fs.rename(old_path, new_path, replace=true)
  inspect(@fs.read_file(new_path).text(), content="abcd")
  inspect(new_file.read_all().text(), content="xyzw")
  old_file.write_at(b"ABCD", position=0L)
  inspect(@fs.read_file(new_path).text(), content="ABCD")
  inspect(@fs.exists(old_path), content="false")
}
