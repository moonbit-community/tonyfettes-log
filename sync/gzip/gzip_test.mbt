// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "gzip encode decode roundtrip" {
  let (compressed_r, compressed_w) = @io.pipe()
  let encoder = @gzip.Encoder(compressed_w)
  encoder.write("hello gzip")
  encoder.end()
  compressed_w.close()
  let decoder = @gzip.Decoder(compressed_r)
  inspect(decoder.read_all().text(), content="hello gzip")
}

///|
test "gzip decoder supports small reads" {
  let (compressed_r, compressed_w) = @io.pipe()
  let encoder = @gzip.Encoder(compressed_w)
  encoder.write("abcdef")
  encoder.end()
  compressed_w.close()
  let decoder = @gzip.Decoder(compressed_r)
  inspect(@utf8.decode(decoder.read_exactly(2)), content="ab")
  inspect(decoder.read_all().text(), content="cdef")
}
