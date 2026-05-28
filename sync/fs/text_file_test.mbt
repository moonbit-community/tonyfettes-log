// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "text file" {
  let dir = @fs.tmpdir(prefix="sync-text-file")
  defer cleanup_dir(dir)
  let path = "\{dir}/basic_text_file_test"
  @fs.write_file(path, "abcd", create_mode=CreateOrTruncate)
  inspect(@fs.read_file(path).text(), content="abcd")
}
