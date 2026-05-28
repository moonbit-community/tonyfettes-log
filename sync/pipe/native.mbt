// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
#borrow(fds)
extern "C" fn pipe_ffi(fds : FixedArray[Int]) -> Int = "tonyfettes_sync_pipe_pipe"

///|
extern "C" fn close_ffi(fd : Int) -> Int = "tonyfettes_sync_pipe_close"

///|
#borrow(dst)
extern "C" fn read_ffi(
  fd : Int,
  dst : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> Int = "tonyfettes_sync_pipe_read"

///|
#borrow(src)
extern "C" fn write_ffi(fd : Int, src : Bytes, offset : Int, len : Int) -> Int = "tonyfettes_sync_pipe_write"

///|
fn[T] raise_os_error(context : String) -> T raise {
  raise @os_error.OSError(@os_error.get_errno(), context~)
}

///|
fn check(code : Int, context : String) -> Unit raise {
  guard code == 0 else { raise_os_error(context) }
}
