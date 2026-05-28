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
}

///|
pub fn File::File(
  path : String,
  format? : Format = Jsonl,
) -> File raise @x/fs.IOError {
  if @x/fs.path_exists(path) {
    guard @x/fs.is_file(path) else {
      raise @x/fs.IOError("\{path} is not a file")
    }
  } else {
    @x/fs.write_string_to_file(path, "")
  }
  File::{ format, path }
}

///|
let self_log : Array[Entry] = []

///|
pub impl Writer for File with fn write(self : File, entry : Entry) -> Unit {
  let s = @x/fs.read_file_to_string(self.path) catch {
    error => {
      self_log.push(
        Entry(
          level=Error,
          category="self_log",
          "failed to read from log file \{self.path}: \{@debug.to_string(error)}",
          fields={ "path": self.path, "error": @debug.to_string(error) },
        ),
      )
      return
    }
  }
  let sb = StringBuilder::new()
  sb.write_string(s)
  match self.format {
    Text => sb.write_string(entry.to_string())
    Jsonl => sb.write_string(entry.to_json().stringify())
  }
  sb.write_char('\n')
  @x/fs.write_string_to_file(self.path, sb.to_string()) catch {
    error =>
      self_log.push(
        Entry(
          level=Error,
          category="self_log",
          "failed to write to log file \{self.path}: \{@debug.to_string(error)}",
          fields={ "path": self.path, "error": @debug.to_string(error) },
        ),
      )
  }
}
