///|
struct MemoryWriter {
  entries : Array[Entry]
}

///|
impl Writer for MemoryWriter with fn write(self : MemoryWriter, entry : Entry) -> Unit {
  self.entries.push(entry)
}

///|
test "package-level functions use the default logger" {
  let entries : Array[Entry] = []
  set_default(Logger(MemoryWriter::{ entries, }, level=Debug))
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
test "default logger reads MOON_SLOG" {
  @env.set_env_var("MOON_SLOG", "debug")
  default_logger.val = None
  let logger = default()
  @env.unset_env_var("MOON_SLOG")
  default_logger.val = None
  guard logger.is_level_enabled(Debug) else {
    fail("expect MOON_SLOG to enable debug")
  }
  guard !logger.is_level_enabled(Trace) else {
    fail("expect MOON_SLOG=debug to reject trace")
  }
}

///|
test "default logger falls back on invalid MOON_SLOG" {
  @env.set_env_var("MOON_SLOG", "app..db=debug")
  default_logger.val = None
  let logger = default()
  @env.unset_env_var("MOON_SLOG")
  default_logger.val = None
  guard logger.is_level_enabled(Info) else {
    fail("expect invalid MOON_SLOG to fall back to info")
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
