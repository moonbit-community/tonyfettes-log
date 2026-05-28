// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "pipe read all as text" {
  let (reader, writer) = @io.pipe()
  writer.write("hello")
  writer.write(", moonbit")
  writer.close()
  inspect(reader.read_all().text(), content="hello, moonbit")
}

///|
test "buffered writer flush" {
  let (reader, writer) = @io.pipe()
  let buffered = @io.BufferedWriter::new(writer, size=4)
  buffered.write("abcde")
  inspect(@utf8.decode(reader.read_exactly(4)), content="abcd")
  buffered.flush()
  inspect(reader.read_all().text(), content="e")
}
