// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
extern "C" fn get_curr_env_ffi() -> FixedArray[Bytes?] = "tonyfettes_sync_process_get_curr_env"

///|
#borrow(cmd, argv, env, cwd)
extern "C" fn spawn_ffi(
  cmd : Bytes,
  argv : FixedArray[Bytes?],
  env : FixedArray[Bytes?],
  stdin : Int,
  stdout : Int,
  stderr : Int,
  has_cwd : Bool,
  cwd : Bytes,
) -> Int = "tonyfettes_sync_process_spawn"

///|
#borrow(out)
extern "C" fn wait_pid_ffi(pid : Int, out : Ref[Int]) -> Int = "tonyfettes_sync_process_wait_pid"

///|
#borrow(out)
extern "C" fn try_wait_pid_ffi(pid : Int, out : Ref[Int]) -> Int = "tonyfettes_sync_process_try_wait_pid"

///|
extern "C" fn terminate_process_ffi(pid : Int, signal : Int) -> Int = "tonyfettes_sync_process_terminate"

///|
extern "C" fn kill_process_ffi(pid : Int) -> Int = "tonyfettes_sync_process_kill"

///|
extern "C" fn sleep_millis_ffi(ms : Int) -> Unit = "tonyfettes_sync_process_sleep_millis"

///|
#borrow(fds)
extern "C" fn pipe_ffi(fds : FixedArray[Int]) -> Int = "tonyfettes_sync_process_pipe"

///|
extern "C" fn close_ffi(fd : Int) -> Int = "tonyfettes_sync_process_close"

///|
#borrow(dst)
extern "C" fn read_ffi(
  fd : Int,
  dst : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> Int = "tonyfettes_sync_process_read"

///|
#borrow(src)
extern "C" fn write_ffi(fd : Int, src : Bytes, offset : Int, len : Int) -> Int = "tonyfettes_sync_process_write"

///|
fn[T] raise_os_error(context : String) -> T raise {
  raise @os_error.OSError(@os_error.get_errno(), context~)
}

///|
fn check(code : Int, context : String) -> Unit raise {
  guard code == 0 else { raise_os_error(context) }
}
