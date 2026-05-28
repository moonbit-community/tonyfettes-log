///|
/// Error raised by the native file wrapper.
pub(all) suberror IOError {
  /// The file operation failure message.
  IOError(String)
}

///|
pub impl Show for IOError with fn output(self, logger) -> Unit {
  let IOError(message) = self
  logger <+ "IOError(\{to_repr(message)})"
}
