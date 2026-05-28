// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "read request basic" {
  let (r, w) = @io.pipe()
  w
  ..write("GET / HTTP/1.1\r\n")
  ..write("Host: x.y.org\r\n")
  .write("User-Agent: MoonBit\r\n\r\n")
  w.close()
  let input = Reader::new(r)
  let request = input.read_request()
  inspect(@debug.to_string(request.meth), content="Get")
  inspect(request.path, content="/")
  debug_inspect(request.headers.get("host"), content="Some(\"x.y.org\")")
  debug_inspect(request.headers.get("user-agent"), content="Some(\"MoonBit\")")
  inspect(input.read_all().text(), content="")
}

///|
test "read request fixed body" {
  let (r, w) = @io.pipe()
  w
  ..write("POST /submit HTTP/1.1\r\n")
  ..write("Host: x.y.org\r\n")
  ..write("Content-Length: 7\r\n\r\n")
  .write("message")
  w.close()
  let input = Reader::new(r)
  let request = input.read_request()
  inspect(@debug.to_string(request.meth), content="Post")
  inspect(request.path, content="/submit")
  debug_inspect(request.headers.get("content-length"), content="Some(\"7\")")
  inspect(input.read_all().text(), content="message")
}

///|
test "read request chunked body" {
  let (r, w) = @io.pipe()
  w
  ..write("POST / HTTP/1.1\r\n")
  ..write("Host: x.y.org\r\n")
  ..write("Transfer-Encoding: chunked\r\n\r\n")
  ..write("4\r\nabcd\r\n")
  ..write("4\r\nefgh\r\n")
  .write("0\r\n\r\n")
  w.close()
  let input = Reader::new(r)
  let request = input.read_request()
  inspect(@debug.to_string(request.meth), content="Post")
  debug_inspect(
    request.headers.get("transfer-encoding"),
    content="Some(\"chunked\")",
  )
  inspect(input.read_all().text(), content="abcdefgh")
}

///|
test "read response passthrough fallback" {
  let (r, w) = @io.pipe()
  w
  ..write("HTTP/1.1 200 OK\r\n")
  ..write("Connection: close\r\n")
  ..write("Content-Type: text/plain\r\n\r\n")
  .write("Hello, World!")
  w.close()
  let input = Reader::new(r)
  let response = input.read_response(request_method=None, auto_decompress=true)
  inspect(response.code, content="200")
  debug_inspect(response.headers.get("connection"), content="Some(\"close\")")
  inspect(input.read_all().text(), content="Hello, World!")
}

///|
test "read response bodyless cases" {
  let no_length : Map[String, String] = {}
  inspect(
    should_read_body_until_close(100, no_length, Empty, None),
    content="false",
  )
  inspect(
    should_read_body_until_close(204, no_length, Empty, None),
    content="false",
  )
  inspect(
    should_read_body_until_close(205, no_length, Empty, None),
    content="false",
  )
  inspect(
    should_read_body_until_close(304, no_length, Empty, None),
    content="false",
  )
  inspect(
    should_read_body_until_close(200, no_length, Empty, Some(Connect)),
    content="false",
  )
  inspect(
    should_read_body_until_close(200, no_length, Empty, Some(Head)),
    content="false",
  )
  inspect(
    should_read_body_until_close(200, no_length, Empty, None),
    content="true",
  )
  inspect(
    should_read_body_until_close(404, no_length, Empty, None),
    content="true",
  )
}

///|
test "read response parse cookies" {
  let (r, w) = @io.pipe()
  w
  ..write("HTTP/1.1 200 OK\r\n")
  ..write("Set-Cookie: Cookie1=value1\r\n")
  ..write(
    "Set-Cookie: Cookie2=value2; Path=/path/to/xxx; Max-Age=420000; Secure\r\n",
  )
  ..write(
    "Set-Cookie: Cookie3=value3; Expires=Sun, 06 Nov 1994 08:49:37 GMT; Domain=example.moonbitlang.com; HttpOnly\r\n",
  )
  ..write("Set-Cookie: Cookie4=value four; ExtNoArg; ExtWithArg=xxx\r\n")
  .write("Content-Length: 0\r\n\r\n")
  w.close()
  let input = Reader::new(r)
  let response = input.read_response(request_method=None, auto_decompress=true)
  debug_inspect(
    response.cookies,
    content=(
      #|[
      #|  {
      #|    name: "Cookie1",
      #|    value: "value1",
      #|    path: None,
      #|    expires_raw: None,
      #|    max_age: None,
      #|    domain: None,
      #|    secure: false,
      #|    http_only: false,
      #|    extensions: [],
      #|  },
      #|  {
      #|    name: "Cookie2",
      #|    value: "value2",
      #|    path: Some("/path/to/xxx"),
      #|    expires_raw: None,
      #|    max_age: Some(420000),
      #|    domain: None,
      #|    secure: true,
      #|    http_only: false,
      #|    extensions: [],
      #|  },
      #|  {
      #|    name: "Cookie3",
      #|    value: "value3",
      #|    path: None,
      #|    expires_raw: Some("Sun, 06 Nov 1994 08:49:37 GMT"),
      #|    max_age: None,
      #|    domain: Some("example.moonbitlang.com"),
      #|    secure: false,
      #|    http_only: true,
      #|    extensions: [],
      #|  },
      #|  {
      #|    name: "Cookie4",
      #|    value: "value four",
      #|    path: None,
      #|    expires_raw: None,
      #|    max_age: None,
      #|    domain: None,
      #|    secure: false,
      #|    http_only: false,
      #|    extensions: ["ExtNoArg", "ExtWithArg=xxx"],
      #|  },
      #|]
    ),
  )
}
