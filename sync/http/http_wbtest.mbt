// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "parse fixed response body" {
  let (r, w) = @io.pipe()
  w.write("HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello")
  w.close()
  let reader = Reader::new(r)
  let response = reader.read_response(
    auto_decompress=false,
    request_method=None,
  )
  inspect(response.code, content="200")
  inspect(response.reason, content="OK")
  inspect(reader.read_all().text(), content="hello")
}

///|
test "send GET request headers" {
  let (r, w) = @io.pipe()
  let sender = Sender::new(w, headers={ "User-Agent": "sync-test" })
  let auto_decompress = sender.send_request(Get, "/", extra_headers={})
  inspect(auto_decompress, content="true")
  sender.end_body()
  w.close()
  inspect(
    r.read_all().text(),
    content="GET / HTTP/1.1\r\nUser-Agent: sync-test\r\nAccept-Encoding: gzip,identity\r\n\r\n",
  )
}
