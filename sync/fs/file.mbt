// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
fn ensure_open(file : File, context : String) -> Unit raise {
  if file.closed {
    raise Failure::Failure("\{context}: file is closed")
  }
}

///|
fn Mode::is_read_only(self : Mode) -> Bool {
  match self {
    ReadOnly => true
    _ => false
  }
}

///|
fn Mode::is_write_only(self : Mode) -> Bool {
  match self {
    WriteOnly => true
    _ => false
  }
}

///|
fn Lock::is_exclusive(self : Lock) -> Bool {
  match self {
    Exclusive => true
    _ => false
  }
}

///|
fn Mode::to_int(self : Mode) -> Int {
  match self {
    ReadOnly => 0
    WriteOnly => 1
    ReadWrite => 2
  }
}

///|
fn CreateMode::to_int(self : CreateMode) -> Int {
  match self {
    OpenExisting => 0
    TruncateExisting => 1
    OpenOrCreate => 2
    CreateOrTruncate => 3
    CreateNew => 4
  }
}

///|
fn SyncMode::to_int(self : SyncMode) -> Int {
  match self {
    NoSync => 0
    Data => 1
    Full => 2
  }
}

///|
fn ensure_readable(file : File, context : String) -> Unit raise {
  ensure_open(file, context)
  guard !file.mode.is_write_only() else {
    raise Failure::Failure("\{context}: file is not opened for reading")
  }
}

///|
fn ensure_writable(file : File, context : String) -> Unit raise {
  ensure_open(file, context)
  guard !file.mode.is_read_only() else {
    raise Failure::Failure("\{context}: file is not opened for writing")
  }
}

///|
#label_migration(create, fill=false, msg="the option `create` is deprecated, use `create_mode` and `permission` instead")
#label_migration(truncate, fill=false, msg="the option `truncate` is deprecated, use `create_mode` instead")
pub fn open(
  filename : StringView,
  mode~ : Mode,
  sync? : SyncMode = NoSync,
  append? : Bool = false,
  create_mode? : CreateMode,
  permission? : Int,
  create? : Int,
  truncate? : Bool = false,
) -> File raise {
  let path = filename.to_owned()
  let create_mode = match create_mode {
    Some(mode) => mode
    None =>
      match (create is Some(_), truncate) {
        (true, true) => CreateOrTruncate
        (true, false) => OpenOrCreate
        (false, true) => TruncateExisting
        (false, false) => OpenExisting
      }
  }
  let permission = match permission {
    Some(perm) => perm
    None if create is Some(perm) => perm
    None => 0o644
  }
  let handle = open_ffi(
    cstring(path),
    mode.to_int(),
    create_mode.to_int(),
    append,
    sync.to_int(),
    permission,
  )
  guard !is_null_ffi(handle) else { raise_os_error("@fs.open()") }
  { handle, path, mode, read_buf: @io.ReaderBuffer::new(), closed: false }
}

///|
pub fn create(
  filename : StringView,
  allow_existing? : Bool = true,
  permission? : Int = 0o644,
  sync? : SyncMode = NoSync,
) -> File raise {
  let create_mode = if allow_existing { CreateOrTruncate } else { CreateNew }
  open(filename, mode=WriteOnly, sync~, create_mode~, permission~)
}

///|
pub fn File::close(self : File) -> Unit {
  if !self.closed {
    ignore(fclose_ffi(self.handle))
    self.closed = true
  }
}

///|
pub fn File::fd(self : File) -> Int {
  if self.closed {
    -1
  } else {
    fileno_ffi(self.handle)
  }
}

///|
pub fn File::kind(self : File) -> FileKind {
  if self.closed {
    Unknown
  } else {
    file_kind_ffi(self.handle)
  }
}

///|
pub fn File::as_dir(self : File) -> Directory raise {
  ensure_open(self, "@fs.File::as_dir()")
  guard self.kind() == Directory else {
    self.close()
    raise @os_error.OSError(
      @os_error.errno_ENOTDIR,
      context="@fs.File::as_dir()",
    )
  }
  let dir = Directory::from_handle(self.handle)
  self.closed = true
  dir
}

///|
pub impl @io.Reader for File with fn _get_internal_buffer(self) {
  self.read_buf
}

///|
pub impl @io.Reader for File with fn _direct_read(self, dst, offset~, max_len~) {
  ensure_readable(self, "@fs.File::read()")
  let n = fread_ffi(self.handle, dst, offset, max_len)
  guard n >= 0 else { raise_os_error("@fs.File::read()") }
  n
}

///|
pub fn File::read_at(
  self : File,
  buf : FixedArray[Byte],
  position~ : Int64,
  offset? : Int = 0,
  len? : Int = buf.length() - offset,
) -> Int raise {
  ensure_readable(self, "@fs.File::read_at()")
  guard position >= 0L else {
    raise Failure::Failure("@fs.File::read_at(): negative position")
  }
  let n = fread_at_ffi(self.handle, buf, offset, len, position)
  guard n >= 0 else { raise_os_error("@fs.File::read_at()") }
  n
}

///|
pub fn File::read_exactly_at(
  self : File,
  len : Int,
  position~ : Int64,
) -> Bytes raise {
  let buf = FixedArray::make(len, b'\x00')
  let n = self.read_at(buf, position~, offset=0, len~)
  if n < len {
    raise @io.ReaderClosed
  }
  buf.unsafe_reinterpret_as_bytes()
}

///|
pub impl @io.Writer for File with fn write_once(self, buf, offset~, len~) {
  ensure_writable(self, "@fs.File::write()")
  let n = fwrite_ffi(self.handle, buf, offset, len)
  guard n >= 0 else { raise_os_error("@fs.File::write()") }
  n
}

///|
pub fn File::write_at(
  self : File,
  buf : BytesView,
  position~ : Int64,
) -> Unit raise {
  ensure_writable(self, "@fs.File::write_at()")
  guard position >= 0L else {
    raise Failure::Failure("@fs.File::write_at(): negative position")
  }
  let n = fwrite_at_ffi(
    self.handle,
    buf.data(),
    buf.start_offset(),
    buf.length(),
    position,
  )
  guard n == buf.length() else { raise_os_error("@fs.File::write_at()") }
}

///|
pub fn File::sync(self : File, only_data? : Bool = false) -> Unit raise {
  ensure_open(self, "@fs.File::sync()")
  check(fsync_ffi(self.handle, only_data), "@fs.File::sync()")
}

///|
pub fn File::size(self : File) -> Int64 raise {
  ensure_open(self, "@fs.File::size()")
  let size = file_size_ffi(self.handle)
  guard size >= 0L else { raise_os_error("@fs.File::size()") }
  size
}

///|
pub fn File::lock(self : File, lock : Lock) -> Unit raise {
  ensure_open(self, "@fs.File::lock()")
  check(
    flock_ffi(self.handle, exclusive=lock.is_exclusive(), nonblock=false),
    "@fs.File::lock()",
  )
}

///|
pub fn File::try_lock(self : File, lock : Lock) -> Bool raise {
  ensure_open(self, "@fs.File::try_lock()")
  flock_ffi(self.handle, exclusive=lock.is_exclusive(), nonblock=true) == 0
}

///|
pub fn File::unlock(self : File) -> Unit {
  if !self.closed {
    ignore(funlock_ffi(self.handle))
  }
}

///|
pub fn File::atime(self : File) -> (Int64, Int) raise {
  atime(self.path, follow_symlink=true)
}

///|
pub fn File::mtime(self : File) -> (Int64, Int) raise {
  mtime(self.path, follow_symlink=true)
}

///|
pub fn File::ctime(self : File) -> (Int64, Int) raise {
  ctime(self.path, follow_symlink=true)
}

///|
pub fn read_file(
  path : StringView,
  sync_timestamp? : Bool = false,
) -> &@io.Data raise {
  let file = open(path, mode=ReadOnly)
  defer file.close()
  let data = file.read_all()
  if sync_timestamp {
    file.sync(only_data=false)
  }
  data
}

///|
#label_migration(create, fill=false, msg="the option `create` is deprecated, use `create_mode` and `permission` instead")
#label_migration(truncate, fill=false, msg="the option `truncate` is deprecated, use `create_mode` instead")
pub fn write_file(
  path : StringView,
  content : &@io.Data,
  create_mode? : CreateMode,
  permission? : Int,
  sync? : SyncMode = Data,
  append? : Bool = false,
  create? : Int,
  truncate? : Bool = true,
) -> Unit raise {
  let create_mode = match create_mode {
    Some(mode) => mode
    None =>
      match (create is Some(_), truncate) {
        (true, true) => CreateOrTruncate
        (true, false) => OpenOrCreate
        (false, true) => TruncateExisting
        (false, false) => OpenExisting
      }
  }
  let permission = match permission {
    Some(perm) => perm
    None if create is Some(perm) => perm
    None => 0o644
  }
  let file = open(
    path,
    mode=WriteOnly,
    sync~,
    append~,
    create_mode~,
    permission~,
  )
  defer file.close()
  file.write(content.binary())
}
