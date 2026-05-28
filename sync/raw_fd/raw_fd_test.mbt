// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "raw fd read write pipe" {
  let (read_end, write_end) = @pipe.pipe()
  let raw_read = @raw_fd.RawFd(read_end.fd())
  let raw_write = @raw_fd.RawFd(write_end.fd())
  defer raw_read.close()
  defer raw_write.close()
  inspect(raw_write.write(b"hello"), content="5")
  let buf = FixedArray::make(8, b'\x00')
  let n = raw_read.read(buf)
  inspect(n, content="5")
  inspect(buf.unsafe_reinterpret_as_bytes()[:n], content="b\"hello\"")
}
