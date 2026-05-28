// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
#borrow(dst)
extern "C" fn read_ffi(
  fd : Int,
  dst : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> Int = "tonyfettes_sync_stdio_read"

///|
#borrow(src)
extern "C" fn write_ffi(fd : Int, src : Bytes, offset : Int, len : Int) -> Int = "tonyfettes_sync_stdio_write"

///|
fn[T] raise_os_error(context : String) -> T raise {
  raise @os_error.OSError(@os_error.get_errno(), context~)
}
