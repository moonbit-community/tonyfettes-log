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
priv suberror HandlerTestError {
  HandlerTestError(String)
}

///|
struct FailingHandler {
  messages : Array[String]
}

///|
impl Handler for FailingHandler with fn handle(
  self : FailingHandler,
  entry : Entry,
) -> Unit raise {
  self.messages.push(entry.message)
  raise HandlerTestError(entry.message)
}

///|
fn test_entry(message : String) -> Entry {
  Entry(level=Info, message)
}

///|
test "package-level functions use the default logger" {
  let entries : Array[Entry] = []
  let logger = global()
  defer {
    logger.set_handler(Stdout())
    logger.set_config(Config())
  }
  logger.set_handler(MemoryHandler::{ entries, })
  logger.set_level(Debug)
  info("global info")
  debug("global debug")
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
test "default config reads MOON_XLOG" {
  @env.set_env_var("MOON_XLOG", "debug")
  let logger = Logger(Stdout(), config=default_config())
  @env.unset_env_var("MOON_XLOG")
  guard logger.is_level_enabled(Debug) else {
    fail("expect MOON_XLOG to enable debug")
  }
  guard !logger.is_level_enabled(Trace) else {
    fail("expect MOON_XLOG=debug to reject trace")
  }
}

///|
test "default config falls back on invalid MOON_XLOG" {
  @env.set_env_var("MOON_XLOG", "app..db=debug")
  let logger = Logger(Stdout(), config=default_config())
  @env.unset_env_var("MOON_XLOG")
  guard logger.is_level_enabled(Info) else {
    fail("expect invalid MOON_XLOG to fall back to info")
  }
  guard !logger.is_level_enabled(Debug) else {
    fail("expect fallback level to reject debug")
  }
}

///|
test "file handler reports write after close" {
  let path = "_build/test.file.closed.self.log"
  if @x/fs.path_exists(path) {
    @x/fs.remove_file(path) catch {
      _ => ()
    }
  }
  let file = File(path)
  file.close()
  file.close()
  let result : Result[Unit, Error] = try? file.handle(test_entry("after close"))
  guard result is Err(@fs.IOError(message)) else {
    fail("expect direct file handler call to report IOError")
  }
  guard message.contains("file is closed") else {
    fail("expect write after close to be reported")
  }
}

///|
test "logger swallows handler errors" {
  let path = "_build/test.file.closed.logger.swallow"
  if @x/fs.path_exists(path) {
    @x/fs.remove_file(path) catch {
      _ => ()
    }
  }
  let file = File(path)
  file.close()
  Logger(file).info("after close")
}

///|
test "multi attempts every handler and returns collected errors" {
  let first_messages : Array[String] = []
  let second_messages : Array[String] = []
  let ok_entries : Array[Entry] = []
  let handlers : Array[&Handler] = [
    FailingHandler::{ messages: first_messages },
    MemoryHandler::{ entries: ok_entries },
    FailingHandler::{ messages: second_messages },
  ]
  let result = try? Multi(handlers).handle(test_entry("fanout"))
  guard result is Err(MultiError(errors)) else {
    fail("expect multi handler to report collected errors")
  }
  guard errors.length() == 2 else {
    fail("expect two collected handler errors")
  }
  guard first_messages == ["fanout"] && second_messages == ["fanout"] else {
    fail("expect failing handlers to be attempted")
  }
  guard ok_entries is [entry] && entry.message == "fanout" else {
    fail("expect successful handler to be attempted")
  }
}
