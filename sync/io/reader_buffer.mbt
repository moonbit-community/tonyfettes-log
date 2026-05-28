// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
struct ReaderBuffer {
  mut buf : FixedArray[Byte]
  mut start : Int
  mut len : Int
}

///|
pub fn ReaderBuffer::new() -> ReaderBuffer {
  { buf: FixedArray::make(0, b'\x00'), start: 0, len: 0 }
}

///|
const SegmentSize = 1024

///|
fn ReaderBuffer::clear(self : ReaderBuffer) -> Unit {
  self.buf = []
  self.start = 0
  self.len = 0
}

///|
fn ReaderBuffer::drop(self : ReaderBuffer, n : Int) -> Unit {
  guard n <= self.len
  self.len -= n
  if self.len == 0 {
    self.start = 0
  } else {
    self.start += n
  }
}

///|
fn ReaderBuffer::enlarge_to(self : ReaderBuffer, n : Int) -> Unit {
  let capacity = self.buf.length()
  if self.start + n <= capacity {
    return
  }
  if n <= capacity {
    self.buf.blit_to(self.buf, src_offset=self.start, len=self.len)
    self.start = 0
    return
  }
  let padding = n % SegmentSize
  let target_len = if padding == 0 { n } else { n - padding + SegmentSize }
  let new_buf = FixedArray::make(target_len, b'\x00')
  self.buf.blit_to(new_buf, src_offset=self.start, dst_offset=0, len=self.len)
  self.buf = new_buf
  self.start = 0
}

///|
fn[R : Reader] ReaderBuffer::try_ensure(
  self : ReaderBuffer,
  len : Int,
  reader~ : R,
) -> Bool raise {
  if self.len >= len {
    return true
  }
  self.enlarge_to(len)
  let capacity = self.buf.length()
  while self.len < len {
    let offset = self.start + self.len
    let n = reader._direct_read(self.buf, offset~, max_len=capacity - offset)
    if n == 0 {
      return false
    }
    self.len += n
  }
  true
}

///|
fn[R : Reader] ReaderBuffer::find_opt(
  self : ReaderBuffer,
  target : Bytes,
  reader~ : R,
) -> Int? raise {
  let target_len = target.length()
  for searched = 0 {
    guard self.try_ensure(searched + target_len, reader~) else { return None }
    let len = self.len
    let start = self.start + searched
    let end = self.start + len
    let region = self.buf.unsafe_reinterpret_as_bytes()[start:end]
    if region.find(target) is Some(i) {
      return Some(searched + i)
    }
    continue len - target_len + 1
  }
}
