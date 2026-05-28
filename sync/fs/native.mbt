// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
fn cstring(s : String) -> Bytes {
  @utf8.encode(s)
}

///|
#borrow(path)
extern "C" fn open_ffi(
  path : Bytes,
  access : Int,
  create : Int,
  append : Bool,
  sync : Int,
  permission : Int,
) -> FileHandle = "tonyfettes_sync_fs_open"

///|
extern "C" fn is_null_ffi(ptr : FileHandle) -> Bool = "tonyfettes_sync_fs_is_null"

///|
#borrow(file)
extern "C" fn fclose_ffi(file : FileHandle) -> Int = "tonyfettes_sync_fs_fclose"

///|
#borrow(file, dst)
extern "C" fn fread_ffi(
  file : FileHandle,
  dst : FixedArray[Byte],
  offset : Int,
  len : Int,
) -> Int = "tonyfettes_sync_fs_fread"

///|
#borrow(file, src)
extern "C" fn fwrite_ffi(
  file : FileHandle,
  src : Bytes,
  offset : Int,
  len : Int,
) -> Int = "tonyfettes_sync_fs_fwrite"

///|
#borrow(file, dst)
extern "C" fn fread_at_ffi(
  file : FileHandle,
  dst : FixedArray[Byte],
  offset : Int,
  len : Int,
  position : Int64,
) -> Int = "tonyfettes_sync_fs_fread_at"

///|
#borrow(file, src)
extern "C" fn fwrite_at_ffi(
  file : FileHandle,
  src : Bytes,
  offset : Int,
  len : Int,
  position : Int64,
) -> Int = "tonyfettes_sync_fs_fwrite_at"

///|
#borrow(file)
extern "C" fn fileno_ffi(file : FileHandle) -> Int = "tonyfettes_sync_fs_fileno"

///|
#borrow(file)
extern "C" fn file_kind_ffi(file : FileHandle) -> FileKind = "tonyfettes_sync_fs_file_kind"

///|
#borrow(file)
extern "C" fn file_size_ffi(file : FileHandle) -> Int64 = "tonyfettes_sync_fs_file_size"

///|
#borrow(file)
extern "C" fn fsync_ffi(file : FileHandle, only_data : Bool) -> Int = "tonyfettes_sync_fs_fsync"

///|
#borrow(file)
extern "C" fn flock_ffi(
  file : FileHandle,
  exclusive~ : Bool,
  nonblock~ : Bool,
) -> Int = "tonyfettes_sync_fs_flock"

///|
#borrow(file)
extern "C" fn funlock_ffi(file : FileHandle) -> Int = "tonyfettes_sync_fs_funlock"

///|
#borrow(path)
extern "C" fn exists_ffi(path : Bytes) -> Bool = "tonyfettes_sync_fs_exists"

///|
#borrow(path)
extern "C" fn mkdir_ffi(path : Bytes, mode : Int) -> Int = "tonyfettes_sync_fs_mkdir"

///|
#borrow(path)
extern "C" fn rmdir_ffi(path : Bytes) -> Int = "tonyfettes_sync_fs_rmdir"

///|
#borrow(path)
extern "C" fn remove_ffi(path : Bytes) -> Int = "tonyfettes_sync_fs_remove"

///|
#borrow(old_path, new_path)
extern "C" fn rename_ffi(
  old_path : Bytes,
  new_path : Bytes,
  replace : Bool,
) -> Int = "tonyfettes_sync_fs_rename"

///|
#borrow(path)
extern "C" fn kind_ffi(path : Bytes, follow_symlink : Bool) -> Int = "tonyfettes_sync_fs_kind"

///|
#borrow(path)
extern "C" fn stat_times_ffi(path : Bytes, follow_symlink : Bool) -> Int = "tonyfettes_sync_fs_stat_times"

///|
extern "C" fn atime_sec_ffi() -> Int64 = "tonyfettes_sync_fs_atime_sec"

///|
extern "C" fn atime_nsec_ffi() -> Int = "tonyfettes_sync_fs_atime_nsec"

///|
extern "C" fn mtime_sec_ffi() -> Int64 = "tonyfettes_sync_fs_mtime_sec"

///|
extern "C" fn mtime_nsec_ffi() -> Int = "tonyfettes_sync_fs_mtime_nsec"

///|
extern "C" fn ctime_sec_ffi() -> Int64 = "tonyfettes_sync_fs_ctime_sec"

///|
extern "C" fn ctime_nsec_ffi() -> Int = "tonyfettes_sync_fs_ctime_nsec"

///|
#borrow(path)
extern "C" fn access_ffi(path : Bytes, mode : Int) -> Bool = "tonyfettes_sync_fs_access"

///|
#borrow(path)
extern "C" fn realpath_ffi(path : Bytes) -> Bytes = "tonyfettes_sync_fs_realpath"

///|
#borrow(path)
extern "C" fn chmod_ffi(path : Bytes, mode : Int) -> Int = "tonyfettes_sync_fs_chmod"

///|
#borrow(target, path)
extern "C" fn symlink_ffi(target : Bytes, path : Bytes) -> Int = "tonyfettes_sync_fs_symlink"

///|
extern "C" fn dir_min_buffer_size_ffi() -> Int = "tonyfettes_sync_fs_dir_buffer_min_size"

///|
extern "C" fn dir_entry_count_mode_ffi() -> Bool = "tonyfettes_sync_fs_dir_entry_count_mode"

///|
#borrow(file, buf)
extern "C" fn readdir_ffi(
  file : FileHandle,
  buf : FixedArray[Byte],
  len : Int,
) -> Int = "tonyfettes_sync_fs_readdir"

///|
#borrow(buf)
extern "C" fn dir_entry_length_ffi(buf : FixedArray[Byte], offset : Int) -> Int = "tonyfettes_sync_fs_dir_entry_length"

///|
#borrow(buf)
extern "C" fn dir_entry_name_ffi(buf : FixedArray[Byte], offset : Int) -> Bytes = "tonyfettes_sync_fs_dir_entry_name"

///|
#borrow(buf)
extern "C" fn dir_entry_is_dir_ffi(buf : FixedArray[Byte], offset : Int) -> Int = "tonyfettes_sync_fs_dir_entry_is_dir"

///|
#borrow(buf)
extern "C" fn dir_entry_is_hidden_ffi(
  buf : FixedArray[Byte],
  offset : Int,
) -> Bool = "tonyfettes_sync_fs_dir_entry_is_hidden"

///|
#borrow(file, name)
extern "C" fn kind_at_ffi(
  file : FileHandle,
  name : Bytes,
  follow_symlink : Bool,
) -> Int = "tonyfettes_sync_fs_kind_at"

///|
#borrow(prefix)
extern "C" fn tmpdir_ffi(prefix : Bytes) -> Bytes = "tonyfettes_sync_fs_tmpdir"

///|
fn[T] raise_os_error(context : String) -> T raise {
  raise @os_error.OSError(@os_error.get_errno(), context~)
}

///|
fn check(code : Int, context : String) -> Unit raise {
  guard code == 0 else { raise_os_error(context) }
}

///|
fn file_kind_from_int(k : Int) -> FileKind {
  match k {
    1 => Regular
    2 => Directory
    3 => SymLink
    4 => Socket
    5 => Pipe
    6 => BlockDevice
    7 => CharDevice
    _ => Unknown
  }
}

///|
fn kind_native(path : String, follow_symlink~ : Bool) -> FileKind raise {
  let res = kind_ffi(cstring(path), follow_symlink)
  guard res >= 0 else { raise_os_error("@fs.kind()") }
  file_kind_from_int(res)
}

///|
fn kind_at_native(
  file : FileHandle,
  name : String,
  follow_symlink~ : Bool,
  context~ : String,
) -> FileKind raise {
  let res = kind_at_ffi(file, cstring(name), follow_symlink)
  guard res >= 0 else { raise_os_error(context) }
  file_kind_from_int(res)
}

///|
fn stat_times(path : String, follow_symlink~ : Bool) -> Unit raise {
  check(stat_times_ffi(cstring(path), follow_symlink), "@fs stat timestamp")
}
