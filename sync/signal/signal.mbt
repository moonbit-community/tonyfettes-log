// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
pub(all) enum Signal {
  SIGINT = 0
  SIGTERM = 1
  SIGHUP = 2
  SIGBREAK = 3
} derive(Debug)

///|
pub fn Signal::to_int(signal : Signal) -> Int {
  match signal {
    SIGINT => sigint_ffi()
    SIGTERM => sigterm_ffi()
    SIGHUP => sighup_ffi()
    SIGBREAK => sigbreak_ffi()
  }
}
