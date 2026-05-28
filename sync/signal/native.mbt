// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
extern "C" fn sigint_ffi() -> Int = "tonyfettes_sync_signal_sigint"

///|
extern "C" fn sigterm_ffi() -> Int = "tonyfettes_sync_signal_sigterm"

///|
extern "C" fn sighup_ffi() -> Int = "tonyfettes_sync_signal_sighup"

///|
extern "C" fn sigbreak_ffi() -> Int = "tonyfettes_sync_signal_sigbreak"
