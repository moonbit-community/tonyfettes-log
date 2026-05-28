// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
pub fn kind(path : StringView, follow_symlink? : Bool = true) -> FileKind raise {
  kind_native(path.to_owned(), follow_symlink~)
}

///|
pub fn atime(
  path : StringView,
  follow_symlink? : Bool = true,
) -> (Int64, Int) raise {
  let path = path.to_owned()
  stat_times(path, follow_symlink~)
  (atime_sec_ffi(), atime_nsec_ffi())
}

///|
pub fn mtime(
  path : StringView,
  follow_symlink? : Bool = true,
) -> (Int64, Int) raise {
  let path = path.to_owned()
  stat_times(path, follow_symlink~)
  (mtime_sec_ffi(), mtime_nsec_ffi())
}

///|
pub fn ctime(
  path : StringView,
  follow_symlink? : Bool = true,
) -> (Int64, Int) raise {
  let path = path.to_owned()
  stat_times(path, follow_symlink~)
  (ctime_sec_ffi(), ctime_nsec_ffi())
}

///|
pub fn exists(path : StringView) -> Bool {
  exists_ffi(cstring(path.to_owned()))
}

///|
pub fn can_read(path : StringView) -> Bool {
  access_ffi(cstring(path.to_owned()), 4)
}

///|
pub fn can_write(path : StringView) -> Bool {
  access_ffi(cstring(path.to_owned()), 2)
}

///|
pub fn can_execute(path : StringView) -> Bool {
  access_ffi(cstring(path.to_owned()), 1)
}

///|
pub fn realpath(path : StringView) -> String raise {
  let bytes = realpath_ffi(cstring(path.to_owned()))
  guard bytes.length() > 0 else { raise_os_error("@fs.realpath()") }
  @utf8.decode(bytes)
}

///|
pub fn chmod(path : StringView, mode : Int) -> Unit raise {
  check(chmod_ffi(cstring(path.to_owned()), mode), "@fs.chmod()")
}

///|
pub fn symlink(target~ : StringView, path : StringView) -> Unit raise {
  check(
    symlink_ffi(cstring(target.to_owned()), cstring(path.to_owned())),
    "@fs.symlink()",
  )
}

///|
pub fn remove(path : StringView) -> Unit raise {
  check(remove_ffi(cstring(path.to_owned())), "@fs.remove()")
}

///|
pub fn rename(
  old_path : StringView,
  new_path : StringView,
  replace? : Bool = true,
) -> Unit raise {
  check(
    rename_ffi(
      cstring(old_path.to_owned()),
      cstring(new_path.to_owned()),
      replace,
    ),
    "@fs.rename()",
  )
}

///|
pub fn tmpdir(prefix~ : StringView) -> String raise {
  let bytes = tmpdir_ffi(cstring(prefix.to_owned()))
  guard bytes.length() > 0 else { raise_os_error("@fs.tmpdir()") }
  @utf8.decode(bytes)
}
