///|
fn read_entries(path : String) -> Array[Json] raise {
  let text = @x/fs.read_file_to_string(path)
  let lines = []
  for line in text.split("\n") {
    let trimmed = line.trim()
    if trimmed.is_blank() {
      continue
    }
    lines.push(@json.parse(line))
  }
  lines
}

///|
fn reset_file(path : String) -> Unit {
  if @x/fs.path_exists(path) {
    @x/fs.remove_file(path) catch {
      _ => ()
    }
  }
}

///|
test "file logger factory" {
  let path = "_build/test.file.logger"
  reset_file(path)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file)
  logger.warn({ "message": "file warning" }, category="app")
  guard read_entries(path) is [line] else { fail("expect exactly one line") }
  guard line is Object(object) else { fail("expect an object") }
  guard object.get("timestamp") is Some(String(_)) else {
    fail("expect \"timestamp\" is some String")
  }
  guard object.get("level") is Some("WARN") else {
    fail("expect \"level\" is \"WARN\"")
  }
  guard object.get("category") is Some("app") else {
    fail("expect \"category\" is \"app\"")
  }
  guard object.get("fields") is Some({ "message": "file warning", .. }) else {
    fail("expect \"message\" is \"file warning\"")
  }
  guard object.get("source") is Some(String(source)) else {
    fail("expect \"source\" is some String")
  }
  guard source.contains("log_test.mbt") else {
    fail("expect source to point at test callsite")
  }
}

///|
test "event writes structured fields" {
  let path = "_build/test.event.fields"
  reset_file(path)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file)
  logger.info({ "message": "listening", "port": 8080 }, category="app")
  guard read_entries(path) is [line] else { fail("expect exactly one line") }
  guard line is Object(object) else { fail("expect an object") }
  guard object.get("message") is None else {
    fail("expect message to stay nested in fields")
  }
  guard object.get("fields") is Some({ "message": "listening", .. }) else {
    fail("expect message")
  }
  guard object.get("fields") is Some({ "port": 8080, .. }) else {
    fail("expect structured field")
  }
}

///|
test "file logger opens in append mode" {
  let path = "_build/test.file.append"
  reset_file(path)
  {
    let first = @xlog.File(path)
    defer first.close()
    @xlog.Logger(first).info({ "message": "first" }, category="app")
  }
  {
    let second = @xlog.File(path)
    defer second.close()
    @xlog.Logger(second).info({ "message": "second" }, category="app")
  }
  guard read_entries(path) is [first_entry, second_entry] else {
    fail("expect exactly two lines")
  }
  guard first_entry is Object(first_object) else { fail("expect an object") }
  guard first_object.get("fields") is Some({ "message": "first", .. }) else {
    fail("expect first message")
  }
  guard second_entry is Object(second_object) else { fail("expect an object") }
  guard second_object.get("fields") is Some({ "message": "second", .. }) else {
    fail("expect second message")
  }
}

///|
test "per-call category" {
  let path = "_build/test.category"
  reset_file(path)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file)
  logger.info({ "message": "Query executed" }, category="app.db")
  guard read_entries(path) is [line] else { fail("expect exactly one line") }
  guard line is Object(object) else { fail("expect an object") }
  guard object.get("category") is Some("app.db") else {
    fail("expect \"category\" is \"app.db\"")
  }
  guard object.get("fields") is Some({ "message": "Query executed", .. }) else {
    fail("expect \"message\" is \"Query executed\"")
  }
}

///|
test "logger levels are instance local" {
  let path = "_build/test.level"
  reset_file(path)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file, level=Warn)
  let db = @xlog.Logger(file, level=Warn)
  db.info({ "message": "hidden" })
  logger.set_level(Info)
  db.info({ "message": "still hidden" })
  logger.info({ "message": "parent visible" }, category="app")
  db.set_level(Info)
  db.info({ "message": "child visible" }, category="app.db")
  guard read_entries(path) is [parent, child] else {
    fail("expect exactly two lines")
  }
  guard parent is Object(parent_object) else { fail("expect an object") }
  guard parent_object.get("category") is Some("app") else {
    fail("expect \"category\" is \"app\"")
  }
  guard parent_object.get("fields") is Some({ "message": "parent visible", .. }) else {
    fail("expect parent message")
  }
  guard child is Object(child_object) else { fail("expect an object") }
  guard child_object.get("category") is Some("app.db") else {
    fail("expect \"category\" is \"app.db\"")
  }
  guard child_object.get("fields") is Some({ "message": "child visible", .. }) else {
    fail("expect child message")
  }
}

///|
test "config overrides category hierarchy" {
  let path = "_build/test.category.filter"
  reset_file(path)
  let config = @xlog.Config(level=Info)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file, config~)
  config.set_category_level("app.db", Debug)
  logger.debug({ "message": "db debug" }, category="app.db")
  logger.trace({ "message": "query trace hidden" }, category="app.db.query")
  logger.debug({ "message": "db2 debug hidden" }, category="app.db2")
  config.set_category_level("app.db.query", Trace)
  logger.trace({ "message": "query trace" }, category="app.db.query")
  guard read_entries(path) is [db_entry, query_entry] else {
    fail("expect exactly two lines")
  }
  guard db_entry is Object(db_object) else { fail("expect an object") }
  guard db_object.get("category") is Some("app.db") else {
    fail("expect \"category\" is \"app.db\"")
  }
  guard db_object.get("fields") is Some({ "message": "db debug", .. }) else {
    fail("expect db debug message")
  }
  guard query_entry is Object(query_object) else { fail("expect an object") }
  guard query_object.get("category") is Some("app.db.query") else {
    fail("expect \"category\" is \"app.db.query\"")
  }
  guard query_object.get("fields") is Some({ "message": "query trace", .. }) else {
    fail("expect query trace message")
  }
}

///|
test "config rejects invalid categories" {
  let config = @xlog.Config()
  for category in ["", ".app", "app.", "app..db"] {
    let result : Result[Unit, @xlog.ConfigError] = try? config.set_category_level(
      category,
      Debug,
    )
    guard result is Err(_) else {
      fail("expect invalid category to be rejected")
    }
  }
  config.set_category_level("app.db", Debug)
}

///|
test "config reads default level and overrides from env" {
  let env = "MOON_LOG_TEST_CONFIG"
  @env.set_env_var(env, "warn,app.db=debug,app.db.query=trace")
  let config = @xlog.Config::from_env(env~)
  @env.unset_env_var(env)
  let path = "_build/test.config.env"
  reset_file(path)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file, config~)
  logger.info({ "message": "app info hidden" }, category="app")
  logger.warn({ "message": "app warn" }, category="app")
  logger.debug({ "message": "db debug" }, category="app.db")
  logger.trace({ "message": "query trace" }, category="app.db.query")
  guard read_entries(path) is [app_entry, db_entry, query_entry] else {
    fail("expect exactly three lines")
  }
  guard app_entry is Object(app_object) else { fail("expect an object") }
  guard app_object.get("fields") is Some({ "message": "app warn", .. }) else {
    fail("expect app warning")
  }
  guard db_entry is Object(db_object) else { fail("expect an object") }
  guard db_object.get("fields") is Some({ "message": "db debug", .. }) else {
    fail("expect db debug")
  }
  guard query_entry is Object(query_object) else { fail("expect an object") }
  guard query_object.get("fields") is Some({ "message": "query trace", .. }) else {
    fail("expect query trace")
  }
}

///|
test "top-level helpers accept category" {
  let path = "_build/test.top.level.category"
  reset_file(path)
  let config = @xlog.Config(level=Warn)
  config.set_category_level("db", Debug)
  let file = @xlog.File(path)
  defer {
    @xlog.global().set_handler(@xlog.Stdout())
    @xlog.global().set_config(@xlog.Config())
    file.close()
  }
  @xlog.global().set_handler(file)
  @xlog.global().set_config(config)
  @xlog.debug({ "message": "hidden without category" })
  @xlog.debug({ "message": "db debug" }, category="db")
  @xlog.info({ "message": "db info" }, category="db")
  @xlog.warn({ "message": "root warn" })
  guard read_entries(path) is [db_debug, db_info, root_warn] else {
    fail("expect exactly three lines")
  }
  guard db_debug is Object(db_debug_object) else { fail("expect an object") }
  guard db_debug_object.get("category") is Some("db") else {
    fail("expect \"category\" is \"db\"")
  }
  guard db_debug_object.get("fields") is Some({ "message": "db debug", .. }) else {
    fail("expect db debug")
  }
  guard db_info is Object(db_info_object) else { fail("expect an object") }
  guard db_info_object.get("category") is Some("db") else {
    fail("expect \"category\" is \"db\"")
  }
  guard db_info_object.get("fields") is Some({ "message": "db info", .. }) else {
    fail("expect db info")
  }
  guard root_warn is Object(root_warn_object) else { fail("expect an object") }
  guard root_warn_object.get("fields") is Some({ "message": "root warn", .. }) else {
    fail("expect root warn")
  }
}

///|
test "global file handler remains alive after setup scope" {
  let path = "_build/test.global.file.handler.lifetime"
  reset_file(path)
  let logger = @xlog.global()
  defer {
    logger.set_handler(@xlog.Stdout())
    logger.set_config(@xlog.Config())
  }
  {
    let file = @xlog.File(path)
    logger.set_handler(file)
  }
  @xlog.info({ "message": "after setup" }, category="lifetime")
  guard read_entries(path) is [entry] else { fail("expect exactly one line") }
  guard entry is Object(object) else { fail("expect an object") }
  guard object.get("category") is Some("lifetime") else {
    fail("expect category")
  }
  guard object.get("fields") is Some({ "message": "after setup", .. }) else {
    fail("expect message")
  }
}

///|
test "config reads MOON_XLOG by default" {
  @env.set_env_var("MOON_XLOG", "debug")
  let config = @xlog.Config::from_env()
  @env.unset_env_var("MOON_XLOG")
  let path = "_build/test.config.default.env"
  reset_file(path)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file, config~)
  logger.debug({ "message": "default env debug" })
  logger.trace({ "message": "default env trace hidden" })
  guard read_entries(path) is [entry] else { fail("expect exactly one line") }
  guard entry is Object(object) else { fail("expect an object") }
  guard object.get("fields") is Some({ "message": "default env debug", .. }) else {
    fail("expect debug message")
  }
}

///|
test "config rejects invalid env directives" {
  let env = "MOON_LOG_TEST_INVALID_CONFIG"
  @env.set_env_var(env, "info,app..db=debug")
  let result : Result[@xlog.Config, @xlog.ConfigError] = try? @xlog.Config::from_env(
    env~,
  )
  @env.unset_env_var(env)
  guard result is Err(_) else {
    fail("expect invalid env directive to be rejected")
  }
}

///|
test "multi destination logger writes to all files" {
  let ps = ["_build/test.multi.sync.0", "_build/test.multi.sync.1"]
  for p in ps {
    reset_file(p)
  }
  let files = ps.map(p => @xlog.File(p))
  defer (for file in files {
    file.close()
  })
  let handlers : Array[&@xlog.Handler] = files.map(file => file)
  let logger = handlers |> @xlog.Multi() |> @xlog.Logger()
  logger.info({ "message": "sync fanout" })
  for p in ps {
    guard read_entries(p) is [line] else { fail("expect exactly one line") }
    guard line is Object(object) else { fail("expect an object") }
    guard object.get("fields") is Some({ "message": "sync fanout", .. }) else {
      fail("expect fanout message")
    }
  }
}
