///|
struct MemoryHandler {
  entries : Array[Entry]
}

///|
impl Handler for MemoryHandler with fn handle(
  self : MemoryHandler,
  entry : Entry,
) -> Unit {
  self.entries.push(entry)
}

///|
test "package-level functions use the default logger" {
  let entries : Array[Entry] = []
  default_logger.val = None
  let logger = default()
  logger.set_handler(MemoryHandler::{ entries, })
  logger.set_level(Debug)
  info("global info")
  debug("global debug")
  default_logger.val = None
  guard entries is [info_entry, debug_entry] else {
    fail("expect exactly two entries")
  }
  guard info_entry.level == Info && info_entry.message == "global info" else {
    fail("expect info entry")
  }
  guard info_entry.source is Some(info_source) &&
    info_source.to_string().contains("log_wbtest.mbt") else {
    fail("expect package-level source to point at test callsite")
  }
  guard debug_entry.level == Debug && debug_entry.message == "global debug" else {
    fail("expect debug entry")
  }
}

///|
test "default logger reads MOON_XLOG" {
  @env.set_env_var("MOON_XLOG", "debug")
  default_logger.val = None
  let logger = default()
  @env.unset_env_var("MOON_XLOG")
  default_logger.val = None
  guard logger.is_level_enabled(Debug) else {
    fail("expect MOON_XLOG to enable debug")
  }
  guard !logger.is_level_enabled(Trace) else {
    fail("expect MOON_XLOG=debug to reject trace")
  }
}

///|
test "default logger falls back on invalid MOON_XLOG" {
  @env.set_env_var("MOON_XLOG", "app..db=debug")
  default_logger.val = None
  let logger = default()
  @env.unset_env_var("MOON_XLOG")
  default_logger.val = None
  guard logger.is_level_enabled(Info) else {
    fail("expect invalid MOON_XLOG to fall back to info")
  }
  guard !logger.is_level_enabled(Debug) else {
    fail("expect fallback level to reject debug")
  }
}

///|
test "file close is idempotent and write after close is self logged" {
  let path = "_build/test.file.closed.self.log"
  if @x/fs.path_exists(path) {
    @x/fs.remove_file(path) catch {
      _ => ()
    }
  }
  self_log.clear()
  let file = File(path)
  file.close()
  file.close()
  Logger(file).info("after close")
  guard self_log is [entry] else { fail("expect exactly one self-log entry") }
  guard entry.level == Error && entry.category == Some("self_log") else {
    fail("expect self-log error entry")
  }
  guard entry.message.contains("file is closed") else {
    fail("expect write after close to be reported")
  }
  self_log.clear()
}
