// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
priv struct Pipe {
  chunks : Array[Bytes]
  read_buf : ReaderBuffer
  mut head : Int
  mut head_offset : Int
  mut read_closed : Bool
  mut write_closed : Bool
}

///|
struct PipeRead(Pipe)

///|
struct PipeWrite(Pipe)

///|
pub fn pipe() -> (PipeRead, PipeWrite) {
  let p = {
    chunks: [],
    read_buf: ReaderBuffer::new(),
    head: 0,
    head_offset: 0,
    read_closed: false,
    write_closed: false,
  }
  (PipeRead(p), PipeWrite(p))
}

///|
pub fn PipeRead::close(self : PipeRead) -> Unit {
  let PipeRead(pipe) = self
  pipe.read_closed = true
  pipe.read_buf.clear()
}

///|
pub fn PipeWrite::close(self : PipeWrite) -> Unit {
  let PipeWrite(pipe) = self
  pipe.write_closed = true
}

///|
pub impl Reader for PipeRead with fn _get_internal_buffer(self) {
  let PipeRead(pipe) = self
  pipe.read_buf
}

///|
pub impl Reader for PipeRead with fn _direct_read(self, dst, offset~, max_len~) {
  let PipeRead(pipe) = self
  guard !pipe.read_closed else { raise ReaderClosed }
  match pipe.chunks.get(pipe.head) {
    None => 0
    Some(chunk) => {
      let available = chunk.length() - pipe.head_offset
      let len = @cmp.minimum(max_len, available)
      dst.blit_from_bytes(offset, chunk, pipe.head_offset, len)
      pipe.head_offset += len
      if pipe.head_offset == chunk.length() {
        pipe.head += 1
        pipe.head_offset = 0
      }
      len
    }
  }
}

///|
pub suberror PipeClosed derive(Debug, ToJson)

///|
pub impl Writer for PipeWrite with fn write_once(self, buf, offset~, len~) {
  let PipeWrite(pipe) = self
  guard !pipe.write_closed && !pipe.read_closed else { raise PipeClosed }
  let chunk = FixedArray::make(len, b'\x00')
  chunk.blit_from_bytes(0, buf, offset, len)
  pipe.chunks.push(Bytes::from_array(chunk))
  len
}
