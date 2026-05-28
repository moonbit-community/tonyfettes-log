// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "write read file" {
  let dir = @fs.tmpdir(prefix="sync-fs")
  let path = "\{dir}/file.txt"
  @fs.write_file(path, "hello", create_mode=CreateOrTruncate)
  inspect(@fs.read_file(path).text(), content="hello")
  let file = @fs.open(path, mode=ReadWrite)
  defer file.close()
  file.write_at(b"Z"[:], position=1L)
  inspect(@fs.read_file(path).text(), content="hZllo")
  let buf = FixedArray::make(3, b'\x00')
  inspect(file.read_at(buf, position=1L), content="3")
  inspect(@utf8.decode(buf.unsafe_reinterpret_as_bytes()), content="Zll")
  assert_true(@fs.kind(path) == Regular)
  let _mtime = @fs.mtime(path)
  @fs.remove(path)
  @fs.rmdir(dir)
}

///|
test "directories and walk" {
  let dir = @fs.tmpdir(prefix="sync-fs-walk")
  @fs.mkdir("\{dir}/a/b", recursive=true)
  @fs.write_file("\{dir}/a/b/file.txt", "x", create_mode=CreateOrTruncate)
  let dir_file = @fs.open("\{dir}/a/b", mode=ReadOnly)
  let opened_dir = dir_file.as_dir()
  defer opened_dir.close()
  inspect(opened_dir.read_all().length(), content="1")
  let names = @fs.readdir("\{dir}/a/b", sort=true)
  inspect(names.length(), content="1")
  inspect(names[0], content="file.txt")
  let walked = []
  @fs.walk(dir, max_concurrency=1, (path, children) => {
    children.sort()
    walked.push((path, children))
  })
  assert_eq(walked.length(), 3)
  @fs.rmdir(dir, recursive=true)
  assert_false(@fs.exists(dir))
}

///|
test "create mode errors use os_error" {
  let dir = @fs.tmpdir(prefix="sync-fs-create")
  let path = "\{dir}/file.txt"
  let missing_is_os_error = try
    @fs.open(path, mode=WriteOnly, create_mode=OpenExisting)
  catch {
    @os_error.OSError(_) as err if err.is_ENOENT() => true
    _ => false
  } noraise {
    file => {
      file.close()
      false
    }
  }
  assert_true(missing_is_os_error)
  @fs.write_file(path, "x", create_mode=CreateNew)
  let exists_is_os_error = try
    @fs.open(path, mode=WriteOnly, create_mode=CreateNew)
  catch {
    @os_error.OSError(_) as err if err.is_EEXIST() => true
    _ => false
  } noraise {
    file => {
      file.close()
      false
    }
  }
  assert_true(exists_is_os_error)
  @fs.remove(path)
  @fs.rmdir(dir)
}

///|
test "rename realpath access" {
  let dir = @fs.tmpdir(prefix="sync-fs-rename")
  let path = "\{dir}/old.txt"
  let renamed = "\{dir}/new.txt"
  @fs.write_file(path, "x", create_mode=CreateOrTruncate)
  assert_true(@fs.can_read(path))
  assert_true(@fs.realpath(path) != "")
  @fs.rename(path, renamed, replace=false)
  assert_false(@fs.exists(path))
  assert_true(@fs.exists(renamed))
  @fs.remove(renamed)
  @fs.rmdir(dir)
}
