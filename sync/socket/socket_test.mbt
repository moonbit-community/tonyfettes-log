// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "addr parse and resolve localhost" {
  let addr = @socket.Addr::parse("127.0.0.1:80")
  inspect(addr.port(), content="80")
  inspect(addr.is_ipv6(), content="false")
  let resolved = @socket.Addr::resolve("localhost", port=80)
  inspect(resolved.port(), content="80")
}

///|
test "udp client server roundtrip" {
  let server = @socket.UdpServer(@socket.Addr::new(0, 0))
  defer server.close()
  let client = @socket.UdpClient(server.addr)
  defer client.close()
  client.send(b"ping")
  let buf = FixedArray::make(16, b'\x00')
  let (n, peer) = server.recvfrom(buf)
  inspect(buf.unsafe_reinterpret_as_bytes()[:n], content="b\"ping\"")
  server.sendto(b"pong", peer)
  let n = client.recv(buf)
  inspect(buf.unsafe_reinterpret_as_bytes()[:n], content="b\"pong\"")
}

///|
test "tcp loopback roundtrip" {
  let server = @socket.TcpServer(@socket.Addr::new(0, 0))
  defer server.close()
  let client = @socket.Tcp::connect(server.addr)
  defer client.close()
  let (accepted, _) = server.accept()
  defer accepted.close()
  client.write("ping")
  let buf = FixedArray::make(4, b'\x00')
  inspect(@utf8.decode(accepted.read_exactly(4)), content="ping")
  accepted.write("pong")
  inspect(@utf8.decode(client.read_exactly(4)), content="pong")
  ignore(buf)
}
