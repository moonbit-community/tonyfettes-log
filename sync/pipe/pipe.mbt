// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
struct PipeRead {
  fd : Int
  read_buf : @io.ReaderBuffer
  mut closed : Bool
}

///|
struct PipeWrite {
  fd : Int
  mut closed : Bool
}

///|
pub fn PipeRead::fd(self : PipeRead) -> Int {
  if self.closed {
    -1
  } else {
    self.fd
  }
}

///|
pub fn PipeWrite::fd(self : PipeWrite) -> Int {
  if self.closed {
    -1
  } else {
    self.fd
  }
}

///|
pub fn pipe() -> (PipeRead, PipeWrite) raise {
  let fds = FixedArray::make(2, 0)
  check(pipe_ffi(fds), "@pipe.pipe()")
  (
    { fd: fds[0], read_buf: @io.ReaderBuffer::new(), closed: false },
    { fd: fds[1], closed: false },
  )
}

///|
pub fn PipeRead::close(self : PipeRead) -> Unit {
  if !self.closed {
    ignore(close_ffi(self.fd))
    self.closed = true
  }
}

///|
pub fn PipeWrite::close(self : PipeWrite) -> Unit {
  if !self.closed {
    ignore(close_ffi(self.fd))
    self.closed = true
  }
}

///|
pub impl @io.Reader for PipeRead with fn _get_internal_buffer(self) {
  self.read_buf
}

///|
pub impl @io.Reader for PipeRead with fn _direct_read(
  self,
  dst,
  offset~,
  max_len~,
) {
  guard !self.closed else { raise @io.ReaderClosed }
  let n = read_ffi(self.fd, dst, offset, max_len)
  guard n >= 0 else { raise_os_error("@pipe.PipeRead::read()") }
  n
}

///|
pub impl @io.Writer for PipeWrite with fn write_once(self, buf, offset~, len~) {
  guard !self.closed else {
    raise Failure::Failure("@pipe.PipeWrite::write(): pipe is closed")
  }
  let n = write_ffi(self.fd, buf, offset, len)
  guard n >= 0 else { raise_os_error("@pipe.PipeWrite::write()") }
  n
}
