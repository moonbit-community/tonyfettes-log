// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for FileKind

///|
pub impl Show for FileKind with fn output(self, logger) {
  match self {
    Unknown => logger <+ "Unknown"
    Regular => logger <+ "Regular"
    Directory => logger <+ "Directory"
    SymLink => logger <+ "SymLink"
    Socket => logger <+ "Socket"
    Pipe => logger <+ "Pipe"
    BlockDevice => logger <+ "BlockDevice"
    CharDevice => logger <+ "CharDevice"
  }
}
