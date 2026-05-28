///|
fn reset_file(path : String) -> Unit {
  if @x/fs.path_exists(path) {
    @x/fs.remove_file(path) catch {
      _ => ()
    }
  }
}

///|
test "open_append preserves existing content" {
  let path = "_build/test.internal.fs.append"
  reset_file(path)
  @x/fs.write_string_to_file(path, "first\n")
  let file = File::open_append(path)
  defer file.close()
  file.write_string("second")
  file.flush()
  inspect(@x/fs.read_file_to_string(path), content="first\nsecond")
}
