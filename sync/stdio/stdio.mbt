// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
struct Input {
  fd : Int
  read_buf : @io.ReaderBuffer
}

///|
pub fn Input::fd(self : Input) -> Int {
  self.fd
}

///|
pub impl @io.Reader for Input with fn _get_internal_buffer(self) {
  self.read_buf
}

///|
pub impl @io.Reader for Input with fn _direct_read(self, dst, offset~, max_len~) {
  let n = read_ffi(self.fd, dst, offset, max_len)
  guard n >= 0 else { raise_os_error("@stdio.Input::read()") }
  n
}

///|
struct Output(Int)

///|
pub fn Output::fd(self : Output) -> Int {
  self.0
}

///|
pub impl @io.Writer for Output with fn write_once(self, buf, offset~, len~) {
  let n = write_ffi(self.0, buf, offset, len)
  guard n >= 0 else { raise_os_error("@stdio.Output::write()") }
  n
}

///|
pub let stdin : Input = { fd: 0, read_buf: @io.ReaderBuffer::new() }

///|
pub let stdout : Output = Output(1)

///|
pub let stderr : Output = Output(2)
