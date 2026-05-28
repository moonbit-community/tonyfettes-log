///|
pub(all) struct Mux(Array[&@async/io.Writer])

///|
pub impl @async/io.Writer for Mux with fn write_once(self, buf, offset~, len~) {
  guard offset >= 0 && len >= 0 && offset + len <= buf.length()
  let data = buf[offset:offset + len]
  for writer in self.0 {
    writer.write(data)
  }
  len
}
