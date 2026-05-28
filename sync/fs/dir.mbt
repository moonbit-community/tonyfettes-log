// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
fn is_special_name(name : String) -> Bool {
  name == "." || name == ".."
}

///|
fn join_path(base : String, name : String) -> String {
  if base is [.., '/'] || base is [.., '\\'] {
    base + name
  } else {
    "\{base}/\{name}"
  }
}

///|
fn parent_dir(path : String) -> String? {
  let trimmed = path[:].trim_end(chars="/\\")
  if trimmed.length() == 0 {
    return None
  }
  let slash = trimmed.rev_find("/")
  let backslash = trimmed.rev_find("\\")
  let index = match (slash, backslash) {
    (Some(a), Some(b)) => Some(@cmp.maximum(a, b))
    (Some(a), None) => Some(a)
    (None, Some(b)) => Some(b)
    (None, None) => None
  }
  match index {
    Some(i) if i > 0 => Some(trimmed[:i].to_owned())
    _ => None
  }
}

///|
pub fn mkdir(
  path : StringView,
  permission? : Int = 0o755,
  recursive? : Bool = false,
) -> Unit raise {
  let path = path.to_owned()
  check(mkdir_ffi(cstring(path), permission), "@fs.mkdir()") catch {
    @os_error.OSError(_) as err if recursive && err.is_ENOENT() =>
      match parent_dir(path) {
        Some(parent) => {
          mkdir(parent, permission~, recursive=true)
          check(mkdir_ffi(cstring(path), permission), "@fs.mkdir()")
        }
        None => raise err
      }
    err => raise err
  }
}

///|
pub fn rmdir(path : StringView, recursive? : Bool = false) -> Unit raise {
  let path = path.to_owned()
  if recursive {
    let children = readdir(path, include_hidden=true, include_special=false)
    for child in children {
      let child_path = join_path(path, child)
      if kind(child_path, follow_symlink=false) == Directory {
        rmdir(child_path, recursive=true)
      } else {
        remove(child_path)
      }
    }
  }
  check(rmdir_ffi(cstring(path)), "@fs.rmdir()")
}

///|
pub fn opendir(path : StringView) -> Directory raise {
  let file = open(path, mode=ReadOnly)
  guard file.kind() == Directory else {
    file.close()
    raise @os_error.OSError(@os_error.errno_ENOTDIR, context="@fs.opendir()")
  }
  let dir = Directory::from_handle(file.handle)
  file.closed = true
  dir
}

///|
fn Directory::from_handle(handle : FileHandle) -> Directory {
  {
    handle,
    buf: FixedArray::make(
      @cmp.maximum(dir_min_buffer_size_ffi(), 1024),
      b'\x00',
    ),
    offset: 0,
    count: 0,
    job_ret: 0,
    state: NeedMoreEntry,
    closed: false,
  }
}

///|
pub fn Directory::close(self : Directory) -> Unit {
  if !self.closed {
    ignore(fclose_ffi(self.handle))
    self.closed = true
  }
}

///|
fn Directory::next_entry(
  dir : Directory,
  include_hidden~ : Bool,
  include_special~ : Bool,
) -> DirectoryEntry? raise {
  guard !dir.closed else {
    raise Failure::Failure("@fs.Directory::next(): directory is closed")
  }
  match dir.state {
    NoMoreEntry => return None
    HasBufferedEntry => ()
    NeedMoreEntry => {
      dir.offset = 0
      dir.count = 0
      dir.job_ret = readdir_ffi(dir.handle, dir.buf, dir.buf.length())
      guard dir.job_ret >= 0 else { raise_os_error("@fs.Directory::next()") }
      if dir.job_ret == 0 {
        dir.state = NoMoreEntry
        return None
      }
      dir.state = HasBufferedEntry
    }
  }
  let entry_len = dir_entry_length_ffi(dir.buf, dir.offset)
  let offset = dir.offset
  dir.offset += entry_len
  dir.count += 1
  let need_more_entry = if entry_len == 0 {
    true
  } else if dir_entry_count_mode_ffi() {
    dir.count >= dir.job_ret
  } else {
    dir.offset >= dir.job_ret
  }
  if need_more_entry {
    dir.state = NeedMoreEntry
  }
  if !include_hidden && dir_entry_is_hidden_ffi(dir.buf, offset) {
    return dir.next_entry(include_hidden~, include_special~)
  }
  let name = @utf8.decode(dir_entry_name_ffi(dir.buf, offset))
  if !include_special && is_special_name(name) {
    return dir.next_entry(include_hidden~, include_special~)
  }
  let is_dir = match dir_entry_is_dir_ffi(dir.buf, offset) {
    0 => false
    1..<_ => true
    _ =>
      try
        kind_at_native(
          dir.handle,
          name,
          follow_symlink=false,
          context="@fs.Directory::next()",
        )
      catch {
        _ => false
      } noraise {
        kind => kind == Directory
      }
  }
  Some({ name, is_dir })
}

///|
pub fn Directory::next(
  dir : Directory,
  include_hidden? : Bool = true,
  include_special? : Bool = false,
) -> DirectoryEntry? raise {
  dir.next_entry(include_hidden~, include_special~)
}

///|
pub fn Directory::read_all(
  dir : Directory,
  include_hidden? : Bool = true,
  include_special? : Bool = false,
) -> Array[String] raise {
  let result = []
  while dir.next_entry(include_hidden~, include_special~) is Some(entry) {
    result.push(entry.name)
  }
  result
}

///|
pub fn readdir(
  path : StringView,
  include_hidden? : Bool = true,
  include_special? : Bool = false,
  sort? : Bool = false,
) -> Array[String] raise {
  let dir = opendir(path)
  defer dir.close()
  let result = dir.read_all(include_hidden~, include_special~)
  if sort {
    result.sort()
  }
  result
}

///|
pub fn walk(
  path : StringView,
  f : (String, Array[String]) -> Unit raise,
  exclude? : (String) -> Bool = _ => false,
  max_concurrency? : Int = 1000,
  allow_failure? : Bool = false,
) -> Unit raise {
  let _max_concurrency = max_concurrency
  fn handle(path : String) -> Unit raise {
    guard !exclude(path) else { return }
    let dir = opendir(path)
    defer dir.close()
    let files = []
    let subdirs = []
    while dir.next(include_hidden=true, include_special=false) is Some(entry) {
      files.push(entry.name)
      if entry.is_dir {
        subdirs.push(join_path(path, entry.name))
      }
    }
    f(path, files) catch {
      _ if allow_failure => ()
      err => raise err
    }
    for subdir in subdirs {
      handle(subdir)
    }
  }

  handle(path.to_owned())
}
