// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
priv struct MemoryTransport {
  input : @io.PipeRead
  output : @io.PipeWrite
}

///|
fn MemoryTransport::new(
  input : @io.PipeRead,
  output : @io.PipeWrite,
) -> MemoryTransport {
  { input, output }
}

///|
impl Transport for MemoryTransport with fn close(self) {
  self.input.close()
  self.output.close()
}

///|
impl @io.Reader for MemoryTransport with fn _get_internal_buffer(self) {
  self.input._get_internal_buffer()
}

///|
impl @io.Reader for MemoryTransport with fn _direct_read(
  self,
  buf,
  offset~,
  max_len~,
) {
  self.input._direct_read(buf, offset~, max_len~)
}

///|
impl @io.Writer for MemoryTransport with fn write_once(self, buf, offset~, len~) {
  self.output.write_once(buf, offset~, len~)
}

///|
test "websocket receive unmasked text frame" {
  let (incoming_r, incoming_w) = @io.pipe()
  let (outgoing_r, outgoing_w) = @io.pipe()
  incoming_w.write(b"\x81\x05hello")
  incoming_w.close()
  let transport = MemoryTransport::new(incoming_r, outgoing_w)
  let ws = Conn::new(transport, 4096, mask=None)
  let msg = ws.recv()
  inspect(@debug.to_string(msg.kind), content="Text")
  inspect(msg.read_all().text(), content="hello")
  outgoing_w.close()
  inspect(outgoing_r.read_all().binary().length(), content="0")
}

///|
test "websocket send unmasked text frame" {
  let (incoming_r, _incoming_w) = @io.pipe()
  let (outgoing_r, outgoing_w) = @io.pipe()
  let transport = MemoryTransport::new(incoming_r, outgoing_w)
  let ws = Conn::new(transport, 4096, mask=None)
  ws.send_text("hi")
  outgoing_w.close()
  inspect(outgoing_r.read_all().binary(), content="b\"\\x81\\x02hi\"")
}
