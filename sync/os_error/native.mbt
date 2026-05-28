// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
extern "C" fn get_errno_impl() -> Int = "tonyfettes_sync_os_error_get_errno"

///|
extern "C" fn errno_is_nonblocking_io_error(errno : Int) -> Bool = "tonyfettes_sync_os_error_is_nonblocking_io_error"

///|
extern "C" fn errno_is_EINTR(errno : Int) -> Bool = "tonyfettes_sync_os_error_is_EINTR"

///|
extern "C" fn errno_is_ENOENT(errno : Int) -> Bool = "tonyfettes_sync_os_error_is_ENOENT"

///|
extern "C" fn errno_is_EEXIST(errno : Int) -> Bool = "tonyfettes_sync_os_error_is_EEXIST"

///|
extern "C" fn errno_is_EACCES(errno : Int) -> Bool = "tonyfettes_sync_os_error_is_EACCES"

///|
extern "C" fn errno_is_ECONNREFUSED(errno : Int) -> Bool = "tonyfettes_sync_os_error_is_ECONNREFUSED"

///|
extern "C" fn errno_to_bytes(errno : Int) -> Bytes = "tonyfettes_sync_os_error_errno_to_string"

///|
extern "C" fn get_ENOTDIR() -> Int = "tonyfettes_sync_os_error_get_ENOTDIR"
