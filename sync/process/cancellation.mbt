// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
pub(all) struct CancellationHandler((Int) -> Unit)

///|
#cfg(platform="windows")
let default_signal : @signal.Signal = SIGBREAK

///|
#cfg(not(platform="windows"))
let default_signal : @signal.Signal = SIGTERM

///|
pub fn graceful_cancel(
  timeout~ : Int,
  signal? : @signal.Signal = default_signal,
) -> CancellationHandler {
  pid => {
    let signal = signal.to_int()
    if signal >= 0 {
      ignore(terminate_process_ffi(pid, signal))
    }
    sleep_millis_ffi(timeout)
    ignore(kill_process_ffi(pid))
  }
}

///|
pub fn hard_cancel() -> CancellationHandler {
  pid => ignore(kill_process_ffi(pid))
}
