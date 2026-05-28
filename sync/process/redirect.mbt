// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
struct ReadFromProcess {
  fd : Int
  read_buf : @io.ReaderBuffer
  mut closed : Bool
}

///|
struct WriteToProcess {
  fd : Int
  mut closed : Bool
}

///|
pub fn read_from_process() -> (ReadFromProcess, &ProcessOutput) raise {
  let fds = FixedArray::make(2, 0)
  check(pipe_ffi(fds), "@process.read_from_process()")
  (
    { fd: fds[0], read_buf: @io.ReaderBuffer::new(), closed: false },
    TempPipeWrite::{ fd: fds[1], closed: false },
  )
}

///|
pub fn write_to_process() -> (&ProcessInput, WriteToProcess) raise {
  let fds = FixedArray::make(2, 0)
  check(pipe_ffi(fds), "@process.write_to_process()")
  (TempPipeRead::{ fd: fds[0], closed: false }, { fd: fds[1], closed: false })
}

///|
pub fn ReadFromProcess::close(self : ReadFromProcess) -> Unit {
  if !self.closed {
    ignore(close_ffi(self.fd))
    self.closed = true
  }
}

///|
pub impl @io.Reader for ReadFromProcess with fn _get_internal_buffer(self) {
  self.read_buf
}

///|
pub impl @io.Reader for ReadFromProcess with fn _direct_read(
  self,
  dst,
  offset~,
  max_len~,
) {
  guard !self.closed else { raise @io.ReaderClosed }
  let n = read_ffi(self.fd, dst, offset, max_len)
  guard n >= 0 else { raise_os_error("@process.ReadFromProcess::read()") }
  n
}

///|
pub fn WriteToProcess::close(self : WriteToProcess) -> Unit {
  if !self.closed {
    ignore(close_ffi(self.fd))
    self.closed = true
  }
}

///|
pub impl @io.Writer for WriteToProcess with fn write_once(
  self,
  buf,
  offset~,
  len~,
) {
  guard !self.closed else {
    raise Failure::Failure("@process.WriteToProcess::write(): pipe is closed")
  }
  let n = write_ffi(self.fd, buf, offset, len)
  guard n >= 0 else { raise_os_error("@process.WriteToProcess::write()") }
  n
}

///|
#label_migration(create, fill=false, msg="the option `create` is deprecated, use `create_mode` and `permission` instead")
#label_migration(truncate, fill=false, msg="the option `truncate` is deprecated, use `create_mode` instead")
pub fn redirect_to_file(
  path : String,
  append? : Bool = false,
  create_mode? : @fs.CreateMode,
  permission? : Int,
  create? : Int,
  truncate? : Bool = false,
) -> &ProcessOutput raise {
  let create_mode = match create_mode {
    Some(mode) => mode
    None =>
      match (create is Some(_), truncate) {
        (true, true) => @fs.CreateOrTruncate
        (true, false) => @fs.OpenOrCreate
        (false, true) => @fs.TruncateExisting
        (false, false) => @fs.OpenExisting
      }
  }
  let permission = match permission {
    Some(perm) => perm
    None if create is Some(perm) => perm
    None => 0o644
  }
  let file = @fs.open(path, mode=WriteOnly, append~, create_mode~, permission~)
  RedirectToFile(file)
}

///|
pub fn redirect_from_file(path : String) -> &ProcessInput raise {
  RedirectToFile(@fs.open(path, mode=ReadOnly))
}

///|
trait ProcessInput {
  fn fd(Self) -> Int
  fn after_spawn(Self) -> Unit = _
}

///|
impl ProcessInput with fn after_spawn(_) {
  ()
}

///|
pub impl ProcessInput for @pipe.PipeRead with fn fd(self) {
  self.fd()
}

///|
pub impl ProcessInput for @stdio.Input with fn fd(self) {
  self.fd()
}

///|
trait ProcessOutput {
  fn fd(Self) -> Int
  fn after_spawn(Self) -> Unit = _
}

///|
impl ProcessOutput with fn after_spawn(_) {
  ()
}

///|
pub impl ProcessOutput for @pipe.PipeWrite with fn fd(self) {
  self.fd()
}

///|
pub impl ProcessOutput for @stdio.Output with fn fd(self) {
  self.fd()
}

///|
priv struct TempPipeRead {
  fd : Int
  mut closed : Bool
}

///|
priv struct TempPipeWrite {
  fd : Int
  mut closed : Bool
}

///|
impl ProcessInput for TempPipeRead with fn fd(self) {
  self.fd
}

///|
impl ProcessInput for TempPipeRead with fn after_spawn(self) {
  if !self.closed {
    ignore(close_ffi(self.fd))
    self.closed = true
  }
}

///|
impl ProcessOutput for TempPipeWrite with fn fd(self) {
  self.fd
}

///|
impl ProcessOutput for TempPipeWrite with fn after_spawn(self) {
  if !self.closed {
    ignore(close_ffi(self.fd))
    self.closed = true
  }
}

///|
priv struct RedirectToFile(@fs.File)

///|
impl ProcessInput for RedirectToFile with fn fd(self) {
  self.0.fd()
}

///|
impl ProcessInput for RedirectToFile with fn after_spawn(self) {
  self.0.close()
}

///|
impl ProcessOutput for RedirectToFile with fn fd(self) {
  self.0.fd()
}

///|
impl ProcessOutput for RedirectToFile with fn after_spawn(self) {
  self.0.close()
}
