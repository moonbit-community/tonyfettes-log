// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
struct BufferedWriter[W] {
  writer : W
  buf : FixedArray[Byte]
  mut len : Int
}

///|
pub fn[W] BufferedWriter::new(
  writer : W,
  size? : Int = 1024,
) -> BufferedWriter[W] {
  { writer, buf: FixedArray::make(size, b'\x00'), len: 0 }
}

///|
pub fn[W] BufferedWriter::capacity(self : BufferedWriter[W]) -> Int {
  self.buf.length()
}

///|
pub fn[W : Writer] BufferedWriter::flush(
  self : BufferedWriter[W],
) -> Unit raise {
  if self.len > 0 {
    self.writer.write(self.buf.unsafe_reinterpret_as_bytes()[:self.len])
    self.len = 0
  }
}

///|
pub impl[W : Writer] Writer for BufferedWriter[W] with fn write_once(
  self,
  buf,
  offset~,
  len~,
) {
  if self.len >= self.buf.length() {
    self.flush()
  }
  let len = @cmp.minimum(len, self.buf.length() - self.len)
  self.buf.blit_from_bytes(self.len, buf, offset, len)
  self.len += len
  len
}

///|
pub impl[W : Writer] Writer for BufferedWriter[W] with fn write_reader(
  self,
  reader,
) {
  for ;; {
    if self.len >= self.buf.length() {
      self.flush()
    }
    let n = reader.read(
      self.buf,
      offset=self.len,
      max_len=self.buf.length() - self.len,
    )
    if n == 0 {
      break
    }
    self.len += n
  }
}
