// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "walk sequential" {
  let root = make_walk_fixture("sync-walk")
  defer cleanup_dir(root)
  let dirs = []
  @fs.walk(root, max_concurrency=1, (path, files) => {
    files.sort()
    dirs.push((path, files))
  })
  assert_eq(dirs.length(), 3)
  let (path0, files0) = dirs[0]
  let (path1, files1) = dirs[1]
  let (path2, files2) = dirs[2]
  assert_eq(path0, root)
  json_inspect(files0, content=["file", "inner1"])
  assert_eq(path1, "\{root}/inner1")
  json_inspect(files1, content=["file", "inner2"])
  assert_eq(path2, "\{root}/inner1/inner2")
  json_inspect(files2, content=["file"])
}

///|
test "walk failure" {
  let root = make_walk_fixture("sync-walk-failure")
  defer cleanup_dir(root)
  let log = []
  let result = try? @fs.walk(root, max_concurrency=1, (path, _) => {
    log.push(path)
    raise Failure::Failure("failure when handling directory")
  })
  assert_true(result is Err(_))
  assert_eq(log.length(), 1)
  assert_eq(log[0], root)
}

///|
test "walk allow_failure" {
  let root = make_walk_fixture("sync-walk-allow-failure")
  defer cleanup_dir(root)
  let log = []
  let result = try? @fs.walk(root, allow_failure=true, max_concurrency=1, (
    path,
    _,
  ) => {
    log.push(path)
    raise Failure::Failure("failure when handling directory")
  })
  assert_true(result is Ok(_))
  assert_eq(log.length(), 3)
  assert_eq(log[0], root)
  assert_eq(log[1], "\{root}/inner1")
  assert_eq(log[2], "\{root}/inner1/inner2")
}

///|
test "walk exclude 1" {
  let root = make_walk_fixture("sync-walk-exclude-1")
  defer cleanup_dir(root)
  let walked = []
  @fs.walk(root, exclude=p => p == "\{root}/inner1", (path, _) => {
    walked.push(path)
  })
  assert_eq(walked.length(), 1)
  assert_eq(walked[0], root)
}

///|
test "walk exclude 2" {
  let root = make_walk_fixture("sync-walk-exclude-2")
  defer cleanup_dir(root)
  let walked = []
  @fs.walk(root, exclude=p => p == "\{root}/inner1/inner2", (path, _) => {
    walked.push(path)
  })
  assert_eq(walked.length(), 2)
  assert_eq(walked[0], root)
  assert_eq(walked[1], "\{root}/inner1")
}
