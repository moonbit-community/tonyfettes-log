///|
pub(open) trait Handler {
  async fn handle(Self, Entry) -> Unit
}

///|
struct JsonHandler {
  writer : &@async/io.Writer
}

///|
pub fn[W : @async/io.Writer] JsonHandler::JsonHandler(
  writer : W,
) -> JsonHandler {
  JsonHandler::{ writer, }
}

///|
pub impl Handler for JsonHandler with fn handle(self, entry) {
  let sb = StringBuilder::new()
  sb.write_string(entry.to_json().stringify())
  sb.write_char('\n')
  self.writer.write(sb.to_string())
}

///|
struct TextHandler {
  writer : &@async/io.Writer
}

///|
pub fn[W : @async/io.Writer] TextHandler::TextHandler(
  writer : W,
) -> TextHandler {
  TextHandler::{ writer, }
}

///|
pub impl Handler for TextHandler with fn handle(self, entry) {
  let sb = StringBuilder::new()
  sb.write_object(entry)
  sb.write_char('\n')
  self.writer.write(sb.to_string())
}
