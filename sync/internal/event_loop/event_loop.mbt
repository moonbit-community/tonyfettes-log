// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
#cfg(not(platform="windows"))
pub const IS_WINDOWS : Bool = false

///|
#cfg(platform="windows")
pub const IS_WINDOWS : Bool = true

///|
pub(all) enum Platform {
  Linux = 0
  MacOS = 1
  Windows = 2
}

///|
extern "C" fn get_platform() -> Platform = "tonyfettes_sync_event_loop_get_platform"

///|
pub let platform : Platform = get_platform()

///|
#external
pub type AddrInfo

///|
struct IoHandle {
  mut fd : @fd_util.Fd
  kind : @fd_util.FileKind
}

///|
pub fn IoHandle::from_fd(
  fd : @fd_util.Fd,
  kind~ : @fd_util.FileKind,
  is_async? : Bool = false,
) -> IoHandle raise {
  ignore(is_async)
  if !@fd_util.fd_is_valid(fd) {
    @os_error.check_errno("@event_loop.IoHandle::from_fd()")
  }
  { fd, kind }
}

///|
pub fn IoHandle::fd(self : IoHandle) -> @fd_util.Fd {
  self.fd
}

///|
pub fn IoHandle::kind(self : IoHandle) -> @fd_util.FileKind {
  self.kind
}

///|
pub fn IoHandle::detach_from_event_loop(self : IoHandle) -> @fd_util.Fd {
  let fd = self.fd
  self.fd = @fd_util.invalid_fd
  fd
}

///|
pub fn IoHandle::close(self : IoHandle) -> Unit {
  let fd = self.detach_from_event_loop()
  if @fd_util.fd_is_valid(fd) {
    @fd_util.close(fd, kind=self.kind, context="") catch {
      _ => ()
    }
  }
}

///|
#borrow(buf)
extern "C" fn read_ffi(
  fd : @fd_util.Fd,
  buf : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> Int = "tonyfettes_sync_event_loop_read"

///|
pub fn IoHandle::read(
  self : IoHandle,
  buf : FixedArray[Byte],
  offset~ : Int,
  len~ : Int,
  context~ : String,
) -> Int raise {
  let ret = read_ffi(self.fd, buf, offset, len)
  if ret < 0 {
    @os_error.check_errno(context)
  }
  ret
}

///|
#borrow(buf)
extern "C" fn write_ffi(
  fd : @fd_util.Fd,
  buf : Bytes,
  offset : Int,
  len : Int,
) -> Int = "tonyfettes_sync_event_loop_write"

///|
pub fn IoHandle::write(
  self : IoHandle,
  buf : Bytes,
  offset~ : Int,
  len~ : Int,
  context~ : String,
) -> Int raise {
  let ret = write_ffi(self.fd, buf, offset, len)
  if ret < 0 {
    @os_error.check_errno(context)
  }
  ret
}

///|
#borrow(addr)
extern "C" fn bind_ffi(fd : @fd_util.Fd, addr : Bytes) -> Int = "tonyfettes_sync_event_loop_bind"

///|
pub fn IoHandle::bind(
  self : IoHandle,
  addr : Bytes,
  context~ : String,
) -> Unit raise {
  guard bind_ffi(self.fd, addr) == 0 else { @os_error.check_errno(context) }
}

///|
#borrow(addr)
extern "C" fn connect_ffi(fd : @fd_util.Fd, addr : Bytes) -> Int = "tonyfettes_sync_event_loop_connect"

///|
pub fn IoHandle::connect(
  self : IoHandle,
  addr : Bytes,
  context~ : String,
) -> Unit raise {
  guard connect_ffi(self.fd, addr) == 0 else { @os_error.check_errno(context) }
}

///|
#borrow(addr)
extern "C" fn accept_ffi(fd : @fd_util.Fd, addr : Bytes) -> @fd_util.Fd = "tonyfettes_sync_event_loop_accept"

///|
pub fn IoHandle::accept(
  self : IoHandle,
  addr : Bytes,
  context~ : String,
) -> IoHandle raise {
  let fd = accept_ffi(self.fd, addr)
  if !@fd_util.fd_is_valid(fd) {
    @os_error.check_errno(context)
  }
  IoHandle::from_fd(fd, kind=Socket)
}

///|
#borrow(buf, addr)
extern "C" fn recvfrom_ffi(
  fd : @fd_util.Fd,
  buf : FixedArray[Byte],
  offset : Int,
  len : Int,
  addr : Bytes,
) -> Int = "tonyfettes_sync_event_loop_recvfrom"

///|
pub fn IoHandle::recvfrom(
  self : IoHandle,
  buf : FixedArray[Byte],
  offset~ : Int,
  len~ : Int,
  addr~ : Bytes,
  context~ : String,
) -> Int raise {
  let ret = recvfrom_ffi(self.fd, buf, offset, len, addr)
  if ret < 0 {
    @os_error.check_errno(context)
  }
  ret
}

///|
#borrow(buf, addr)
extern "C" fn sendto_ffi(
  fd : @fd_util.Fd,
  buf : Bytes,
  offset : Int,
  len : Int,
  addr : Bytes,
) -> Int = "tonyfettes_sync_event_loop_sendto"

///|
pub fn IoHandle::sendto(
  self : IoHandle,
  buf : Bytes,
  offset~ : Int,
  len~ : Int,
  addr~ : Bytes,
  context~ : String,
) -> Int raise {
  let ret = sendto_ffi(self.fd, buf, offset, len, addr)
  if ret < 0 {
    @os_error.check_errno(context)
  }
  ret
}

///|
#borrow(host)
extern "C" fn getaddrinfo_ffi(host : @os_string.OsString) -> AddrInfo = "tonyfettes_sync_event_loop_getaddrinfo"

///|
extern "C" fn getaddrinfo_error() -> Int = "tonyfettes_sync_event_loop_getaddrinfo_error"

///|
extern "C" fn gai_error_to_bytes(code : Int) -> Bytes = "tonyfettes_sync_event_loop_gai_error"

///|
pub fn getaddrinfo(
  host : StringView,
  context~ : String,
) -> Result[AddrInfo, String] raise {
  let root = getaddrinfo_ffi(@os_string.encode(host))
  let err = getaddrinfo_error()
  if err != 0 {
    Err(@utf8.decode(gai_error_to_bytes(err)))
  } else {
    ignore(context)
    Ok(root)
  }
}

///|
extern "C" fn kind_of_fd_ffi(fd : @fd_util.Fd) -> Int = "tonyfettes_sync_event_loop_kind_of_fd"

///|
pub fn kind_of_fd(
  fd : @fd_util.Fd,
  context~ : String,
) -> @fd_util.FileKind raise {
  let kind = kind_of_fd_ffi(fd)
  if kind < 0 {
    @os_error.check_errno(context)
  }
  @fd_util.FileKind::unsafe_from_int(kind)
}

///|
pub fn register_hook(
  init? : () -> Unit raise,
  exit? : () -> Unit raise,
) -> Unit {
  ignore(init)
  ignore(exit)
}
