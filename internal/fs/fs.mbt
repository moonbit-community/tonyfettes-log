///|
/// Opaque native file handle used by the xlog file handler.
type File

///|
fn cstring(s : String) -> Bytes {
  @utf8.encode(s)
}

///|
#borrow(path)
extern "C" fn open_append(path : Bytes) -> File = "tonyfettes_xlog_internal_fs_open_append"

///|
#borrow(file)
extern "C" fn is_null(file : File) -> Bool = "tonyfettes_xlog_internal_fs_is_null"

///|
#borrow(file, data)
extern "C" fn write(file : File, data : Bytes) -> Int = "tonyfettes_xlog_internal_fs_write"

///|
#borrow(file)
extern "C" fn flush(file : File) -> Int = "tonyfettes_xlog_internal_fs_flush"

///|
#borrow(file)
extern "C" fn close(file : File) -> Unit = "tonyfettes_xlog_internal_fs_close"

///|
/// Open `path` in append mode.
pub fn File::open_append(path : String) -> File raise IOError {
  let file = open_append(cstring(path))
  guard !is_null(file) else {
    raise IOError("failed to open \{path} for append")
  }
  file
}

///|
/// Write bytes to an open file.
pub fn File::write(self : File, data : Bytes) -> Unit raise IOError {
  guard !is_null(self) else {
    raise IOError("@fs.File::write(): file is closed")
  }
  guard write(self, data) == 0 else {
    raise IOError("@fs.File::write(): failed to write")
  }
}

///|
/// Write a UTF-8 string to an open file.
pub fn File::write_string(self : File, data : String) -> Unit raise IOError {
  self.write(@utf8.encode(data))
}

///|
/// Flush buffered file contents to the operating system.
pub fn File::flush(self : File) -> Unit raise IOError {
  guard !is_null(self) else {
    raise IOError("@fs.File::flush(): file is closed")
  }
  guard flush(self) == 0 else {
    raise IOError("@fs.File::flush(): failed to flush")
  }
}

///|
/// Close the file handle.
pub fn File::close(self : File) -> Unit {
  close(self)
}
