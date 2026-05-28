// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "stdio fds" {
  inspect(@stdio.stdin.fd(), content="0")
  inspect(@stdio.stdout.fd(), content="1")
  inspect(@stdio.stderr.fd(), content="2")
}
