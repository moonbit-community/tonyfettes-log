// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for ReaderClosed

///|
pub impl Show for ReaderClosed with fn output(_self, logger) {
  logger <+ "ReaderClosed"
}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for PipeClosed

///|
pub impl Show for PipeClosed with fn output(_self, logger) {
  logger <+ "PipeClosed"
}
