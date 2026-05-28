// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
pub fn get_errno() -> Int {
  get_errno_impl()
}

///|
pub fn is_nonblocking_io_error() -> Bool {
  errno_is_nonblocking_io_error(get_errno())
}

///|
#internal(internal, "for internal use only")
pub fn errno_to_string(errno : Int) -> String {
  @utf8.decode_lossy(errno_to_bytes(errno)).trim_end(chars="\r\n").to_owned()
}

///|
pub(all) suberror OSError {
  OSError(Int, context~ : String)
} derive(ToJson)

///|
pub impl Show for OSError with fn output(self, logger) -> Unit {
  let OSError(errno, context~) = self
  let msg = "\{context}: \{errno_to_string(errno)}"
  logger <+ "OSError(\{to_repr(msg)})"
}

///|
pub fn OSError::is_nonblocking_io_error(err : OSError) -> Bool {
  let OSError(errno, ..) = err
  errno_is_nonblocking_io_error(errno)
}

///|
pub fn OSError::is_EINTR(err : OSError) -> Bool {
  let OSError(errno, ..) = err
  errno_is_EINTR(errno)
}

///|
pub fn OSError::is_ENOENT(err : OSError) -> Bool {
  let OSError(errno, ..) = err
  errno_is_ENOENT(errno)
}

///|
pub fn OSError::is_EEXIST(err : OSError) -> Bool {
  let OSError(errno, ..) = err
  errno_is_EEXIST(errno)
}

///|
pub fn OSError::is_EACCES(err : OSError) -> Bool {
  let OSError(errno, ..) = err
  errno_is_EACCES(errno)
}

///|
pub fn OSError::is_ECONNREFUSED(err : OSError) -> Bool {
  let OSError(errno, ..) = err
  errno_is_ECONNREFUSED(errno)
}

///|
pub fn check_errno(context : String) -> Unit raise OSError {
  let err_code = get_errno()
  if err_code != 0 {
    raise OSError(err_code, context~)
  }
}

///|
pub let errno_ENOTDIR : Int = get_ENOTDIR()
