///|
pub(all) suberror IOError {
  IOError(String)
}

///|
pub impl Show for IOError with fn output(self, logger) -> Unit {
  let IOError(message) = self
  logger <+ "IOError(\{to_repr(message)})"
}
