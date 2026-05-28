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
  let logger = @xlog.Logger(file, category="app")
  logger.warn("file warning")
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
  guard object.get("message") is Some("file warning") else {
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
test "file logger opens in append mode" {
  let path = "_build/test.file.append"
  reset_file(path)
  {
    let first = @xlog.File(path)
    defer first.close()
    @xlog.Logger(first, category="app").info("first")
  }
  {
    let second = @xlog.File(path)
    defer second.close()
    @xlog.Logger(second, category="app").info("second")
  }
  guard read_entries(path) is [first_entry, second_entry] else {
    fail("expect exactly two lines")
  }
  guard first_entry is Object(first_object) else { fail("expect an object") }
  guard first_object.get("message") is Some("first") else {
    fail("expect first message")
  }
  guard second_entry is Object(second_object) else { fail("expect an object") }
  guard second_object.get("message") is Some("second") else {
    fail("expect second message")
  }
}

///|
test "nested category" {
  let path = "_build/test.category"
  reset_file(path)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file, category="app")
  let db = logger.child(category="db")
  db.info("Query executed")
  guard read_entries(path) is [line] else { fail("expect exactly one line") }
  guard line is Object(object) else { fail("expect an object") }
  guard object.get("category") is Some("app.db") else {
    fail("expect \"category\" is \"app.db\"")
  }
  guard object.get("message") is Some("Query executed") else {
    fail("expect \"message\" is \"Query executed\"")
  }
}

///|
test "child logger level is independent after creation" {
  let path = "_build/test.level"
  reset_file(path)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file, category="app", level=Warn)
  let db = logger.child(category="db")
  db.info("hidden")
  logger.set_level(Info)
  db.info("still hidden")
  logger.info("parent visible")
  db.set_level(Info)
  db.info("child visible")
  guard read_entries(path) is [parent, child] else {
    fail("expect exactly two lines")
  }
  guard parent is Object(parent_object) else { fail("expect an object") }
  guard parent_object.get("category") is Some("app") else {
    fail("expect \"category\" is \"app\"")
  }
  guard parent_object.get("message") is Some("parent visible") else {
    fail("expect parent message")
  }
  guard child is Object(child_object) else { fail("expect an object") }
  guard child_object.get("category") is Some("app.db") else {
    fail("expect \"category\" is \"app.db\"")
  }
  guard child_object.get("message") is Some("child visible") else {
    fail("expect child message")
  }
}

///|
test "config overrides category hierarchy" {
  let path = "_build/test.category.filter"
  reset_file(path)
  let config = @xlog.Config::new(level=Info)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file, category="app", config~)
  let db = logger.child(category="db")
  let query = db.child(category="query")
  let db2 = logger.child(category="db2")
  config.set_category_level("app.db", Debug)
  db.debug("db debug")
  query.trace("query trace hidden")
  db2.debug("db2 debug hidden")
  config.set_category_level("app.db.query", Trace)
  query.trace("query trace")
  guard read_entries(path) is [db_entry, query_entry] else {
    fail("expect exactly two lines")
  }
  guard db_entry is Object(db_object) else { fail("expect an object") }
  guard db_object.get("category") is Some("app.db") else {
    fail("expect \"category\" is \"app.db\"")
  }
  guard db_object.get("message") is Some("db debug") else {
    fail("expect db debug message")
  }
  guard query_entry is Object(query_object) else { fail("expect an object") }
  guard query_object.get("category") is Some("app.db.query") else {
    fail("expect \"category\" is \"app.db.query\"")
  }
  guard query_object.get("message") is Some("query trace") else {
    fail("expect query trace message")
  }
}

///|
test "config rejects invalid categories" {
  let config = @xlog.Config::new()
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
  let logger = @xlog.Logger(file, category="app", config~)
  let db = logger.child(category="db")
  let query = db.child(category="query")
  logger.info("app info hidden")
  logger.warn("app warn")
  db.debug("db debug")
  query.trace("query trace")
  guard read_entries(path) is [app_entry, db_entry, query_entry] else {
    fail("expect exactly three lines")
  }
  guard app_entry is Object(app_object) else { fail("expect an object") }
  guard app_object.get("message") is Some("app warn") else {
    fail("expect app warning")
  }
  guard db_entry is Object(db_object) else { fail("expect an object") }
  guard db_object.get("message") is Some("db debug") else {
    fail("expect db debug")
  }
  guard query_entry is Object(query_object) else { fail("expect an object") }
  guard query_object.get("message") is Some("query trace") else {
    fail("expect query trace")
  }
}

///|
test "config reads MOON_SLOG by default" {
  @env.set_env_var("MOON_SLOG", "debug")
  let config = @xlog.Config::from_env()
  @env.unset_env_var("MOON_SLOG")
  let path = "_build/test.config.default.env"
  reset_file(path)
  let file = @xlog.File(path)
  defer file.close()
  let logger = @xlog.Logger(file, config~)
  logger.debug("default env debug")
  logger.trace("default env trace hidden")
  guard read_entries(path) is [entry] else { fail("expect exactly one line") }
  guard entry is Object(object) else { fail("expect an object") }
  guard object.get("message") is Some("default env debug") else {
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
  let writers : Array[&@xlog.Writer] = files.map(file => file)
  let logger = writers |> @xlog.Multi() |> @xlog.Logger()
  logger.info("sync fanout")
  for p in ps {
    guard read_entries(p) is [line] else { fail("expect exactly one line") }
    guard line is Object(object) else { fail("expect an object") }
    guard object.get("message") is Some("sync fanout") else {
      fail("expect fanout message")
    }
  }
}
