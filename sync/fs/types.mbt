// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
pub(all) enum FileKind {
  Unknown = 0
  Regular = 1
  Directory = 2
  SymLink = 3
  Socket = 4
  Pipe = 5
  BlockDevice = 6
  CharDevice = 7
} derive(Eq, Debug)

///|
pub(all) enum Mode {
  ReadOnly = 0
  WriteOnly = 1
  ReadWrite = 2
}

///|
pub(all) enum SyncMode {
  NoSync
  Data
  Full
}

///|
pub(all) enum CreateMode {
  OpenExisting = 0
  TruncateExisting = 1
  OpenOrCreate = 2
  CreateOrTruncate = 3
  CreateNew = 4
}

///|
pub(all) enum Lock {
  Shared
  Exclusive
}

///|
#external
priv type FileHandle

///|
priv enum DirectoryState {
  NoMoreEntry
  NeedMoreEntry
  HasBufferedEntry
}

///|
struct File {
  handle : FileHandle
  path : String
  mode : Mode
  read_buf : @io.ReaderBuffer
  mut closed : Bool
}

///|
#valtype
pub struct DirectoryEntry {
  name : String
  is_dir : Bool
}

///|
struct Directory {
  handle : FileHandle
  buf : FixedArray[Byte]
  mut offset : Int
  mut count : Int
  mut job_ret : Int
  mut state : DirectoryState
  mut closed : Bool
}
