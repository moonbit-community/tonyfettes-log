///|
pub(open) trait Handler {
  fn handle(Self, Entry) -> Unit raise
}

///|
pub(all) enum Format {
  Text
  Jsonl
}

///|
struct Stdout {
  format : Format
}

///|
pub fn Stdout::Stdout(format? : Format = Text) -> Stdout {
  Stdout::{ format, }
}

///|
pub impl Handler for Stdout with fn handle(self : Stdout, entry : Entry) -> Unit {
  match self.format {
    Text => println(entry.to_string())
    Jsonl => println(entry.to_json().stringify())
  }
}

///|
pub(all) suberror MultiError {
  MultiError(Array[Error])
}

///|
pub(all) struct Multi(Array[&Handler])

///|
pub impl Handler for Multi with fn handle(self : Multi, entry : Entry) -> Unit {
  let errors = []
  for handler in self.0 {
    handler.handle(entry) catch {
      error => errors.push(error)
    }
  }
  if !errors.is_empty() {
    raise MultiError(errors)
  }
}

///|
struct File {
  format : Format
  file : @fs.File
}

///|
pub fn File::File(
  path : String,
  format? : Format = Jsonl,
) -> File raise @fs.IOError {
  let file = @fs.File::open_append(path)
  File::{ format, file }
}

///|
fn File::write_entry(self : File, entry : Entry) -> Unit raise @fs.IOError {
  let sb = StringBuilder::new()
  match self.format {
    Text => sb.write_string(entry.to_string())
    Jsonl => sb.write_string(entry.to_json().stringify())
  }
  sb.write_char('\n')
  @fs.File::write_string(self.file, sb.to_string())
  @fs.File::flush(self.file)
}

///|
pub fn File::close(self : File) -> Unit {
  @fs.File::close(self.file)
}

///|
pub impl Handler for File with fn handle(self : File, entry : Entry) -> Unit raise {
  self.write_entry(entry)
}
