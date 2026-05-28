///|
pub(open) trait Handler {
  fn handle(Self, Entry) -> Unit
}

///|
struct TextHandler {
  writer : &@sync/io.Writer
}

///|
pub fn TextHandler::TextHandler(writer : &@sync/io.Writer) -> TextHandler {
  TextHandler::{ writer, }
}

///|
struct JsonHandler {
  writer : &@sync/io.Writer
}

///|
pub fn JsonHandler::JsonHandler(writer : &@sync/io.Writer) -> JsonHandler {
  JsonHandler::{ writer, }
}

///|
fn write_line(writer : &@sync/io.Writer, line : String) -> Unit {
  writer.write(line + "\n") catch {
    error =>
      self_log.push(
        Entry(
          level=Error,
          category="self_log",
          "failed to write log entry: \{@debug.to_string(error)}",
          fields={ "error": @debug.to_string(error) },
        ),
      )
  }
}

///|
pub impl Handler for TextHandler with fn handle(
  self : TextHandler,
  entry : Entry,
) -> Unit {
  write_line(self.writer, entry.to_string())
}

///|
pub impl Handler for JsonHandler with fn handle(
  self : JsonHandler,
  entry : Entry,
) -> Unit {
  write_line(self.writer, entry.to_json().stringify())
}

///|
pub(all) struct MultiHandler(Array[&Handler])

///|
pub impl Handler for MultiHandler with fn handle(
  self : MultiHandler,
  entry : Entry,
) -> Unit {
  for handler in self.0 {
    handler.handle(entry)
  }
}

///|
let self_log : Array[Entry] = []
