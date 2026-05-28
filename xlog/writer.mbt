///|
pub(open) trait Writer {
  fn write(Self, Entry) -> Unit
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
pub impl Writer for Stdout with fn write(self : Stdout, entry : Entry) -> Unit {
  match self.format {
    Text => println(entry.to_string())
    Jsonl => println(entry.to_json().stringify())
  }
}

///|
pub(all) struct Multi(Array[&Writer])

///|
pub impl Writer for Multi with fn write(self : Multi, entry : Entry) -> Unit {
  for w in self.0 {
    w.write(entry)
  }
}

///|
struct File {
  format : Format
  path : String
  mut file : @fs.File?
}

///|
pub fn File::File(
  path : String,
  format? : Format = Jsonl,
) -> File raise @fs.IOError {
  let file = @fs.File::open_append(path)
  File::{ format, path, file: Some(file) }
}

///|
let self_log : Array[Entry] = []

///|
fn File::write_entry(self : File, entry : Entry) -> Unit raise @fs.IOError {
  guard self.file is Some(file) else {
    raise @fs.IOError("@xlog.File::write(): file is closed")
  }
  let sb = StringBuilder::new()
  match self.format {
    Text => sb.write_string(entry.to_string())
    Jsonl => sb.write_string(entry.to_json().stringify())
  }
  sb.write_char('\n')
  @fs.File::write_string(file, sb.to_string())
  @fs.File::flush(file)
}

///|
pub fn File::close(self : File) -> Unit {
  if self.file is Some(file) {
    self.file = None
    @fs.File::close(file)
  }
}

///|
fn log_write_error(path : String, message : String) -> Unit {
  self_log.push(
    Entry(
      level=Error,
      category="self_log",
      "failed to write to log file \{path}: \{message}",
      fields={ "path": path, "error": message },
    ),
  )
}

///|
pub impl Writer for File with fn write(self : File, entry : Entry) -> Unit {
  self.write_entry(entry) catch {
    error => log_write_error(self.path, error.to_string())
  }
}
