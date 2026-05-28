// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
pub(all) enum Encoding {
  UTF8
}

///|
pub(open) trait Writer {
  fn write_once(Self, Bytes, offset~ : Int, len~ : Int) -> Int raise
  fn write(Self, &Data) -> Unit raise = _
  fn write_reader(Self, &Reader) -> Unit raise = _
}

///|
impl Writer with fn write(self, data) {
  let view = data.to_bytesview()
  let start = view.start_offset()
  let len = view.length()
  guard len > 0 else { return }
  let bytes = view.data()
  for written = 0; written < len; {
    let progress = self.write_once(
      bytes,
      offset=start + written,
      len=len - written,
    )
    guard progress > 0 else {
      raise Failure::Failure("writer made no progress")
    }
    continue written + progress
  }
}

///|
impl Writer with fn write_reader(self, reader) {
  let buf = reader._get_internal_buffer()
  if buf.len > 0 {
    let buf_bytes = buf.buf.unsafe_reinterpret_as_bytes()
    self.write(buf_bytes[buf.start:buf.start + buf.len])
    buf.start = 0
    buf.len = 0
  }
  buf.enlarge_to(1)
  let max_len = buf.buf.length()
  while reader._direct_read(buf.buf, offset=0, max_len~) is n && n > 0 {
    let buf_bytes = buf.buf.unsafe_reinterpret_as_bytes()
    self.write(buf_bytes[:n])
  }
}
