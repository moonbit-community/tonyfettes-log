///|
/// A sink that receives structured log entries.
///
/// Direct handler calls may raise errors. Logger methods catch and ignore those
/// errors so logging failures do not interrupt application code.
pub(open) trait Handler {
  /// Write or otherwise process one log entry.
  fn handle(Self, Entry) -> Unit raise
}

///|
/// Output format used by built-in handlers.
pub(all) enum Format {
  /// Human-readable key-value text.
  Text
  /// One JSON object per line.
  Jsonl
}

///|
/// A handler that writes log entries to standard output.
struct Stdout {
  format : Format
}

///|
/// Create a standard-output handler.
///
/// The default format is `Text`.
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
/// Error raised by `Multi` when one or more child handlers fail.
pub(all) suberror MultiError {
  /// The errors collected from failing child handlers.
  MultiError(Array[Error])
}

///|
/// A handler that fans out each entry to multiple child handlers.
///
/// Every child handler is attempted. If any fail, `MultiError` is raised after
/// all handlers have been called.
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
/// A handler that appends log entries to a file.
///
/// `File` is native-only. It keeps the file open until `close` is called or the
/// handler becomes unreachable.
struct File {
  format : Format
  file : @fs.File
}

///|
/// Open a file handler in append mode.
///
/// The default format is `Jsonl`.
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
/// Close the file handle.
///
/// Calling `close` more than once is safe.
pub fn File::close(self : File) -> Unit {
  @fs.File::close(self.file)
}

///|
pub impl Handler for File with fn handle(self : File, entry : Entry) -> Unit raise {
  self.write_entry(entry)
}
