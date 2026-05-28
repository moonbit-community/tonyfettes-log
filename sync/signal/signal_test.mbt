// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
test "signal codes" {
  assert_true(@signal.SIGINT.to_int() >= 0)
  assert_true(@signal.SIGTERM.to_int() >= 0)
  assert_true(@signal.SIGHUP.to_int() >= 0)
}
