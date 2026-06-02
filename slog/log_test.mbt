///|
fn read_entries(path : String) -> Array[Json] raise {
  let text = @sync/fs.read_file(path).text()
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
  if @sync/fs.exists(path) {
    @sync/fs.remove(path) catch {
      _ => ()
    }
  }
}

///|
fn open_log_file(path : String) -> @sync/fs.File raise {
  reset_file(path)
  @sync/fs.open(path, mode=WriteOnly, create_mode=OpenOrCreate, append=true)
}

///|
test "json handler writes JSON line" {
  let path = "_build/test.json.handler"
  let file = open_log_file(path)
  let logger = @slog.Logger(
    @slog.JsonHandler(file as &@sync/io.Writer),
    category="app",
  )
  logger.warn("file warning")
  file.close()
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
test "text handler writes text line" {
  let path = "_build/test.text.handler"
  let file = open_log_file(path)
  let logger = @slog.Logger(@slog.TextHandler(file), category="app")
  logger.warn("text warning", fields={ "kind": "text" })
  file.close()
  let text = @sync/fs.read_file(path).text()
  guard text.contains("level=WARN") else {
    fail("expect text line to include level")
  }
  guard text.contains("category=app") else {
    fail("expect text line to include category")
  }
  guard text.contains("msg=\"text warning\"") else {
    fail("expect text line to include message")
  }
  guard text.contains("kind=") else {
    fail("expect text line to include fields")
  }
}

///|
test "nested category" {
  let path = "_build/test.category"
  let file = open_log_file(path)
  let logger = @slog.Logger(
    @slog.JsonHandler(file as &@sync/io.Writer),
    category="app",
  )
  let db = logger.child(category="db")
  db.info("Query executed")
  file.close()
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
  let file = open_log_file(path)
  let logger = @slog.Logger(
    @slog.JsonHandler(file as &@sync/io.Writer),
    category="app",
    level=Warn,
  )
  let db = logger.child(category="db")
  db.info("hidden")
  logger.set_level(Info)
  db.info("still hidden")
  logger.info("parent visible")
  db.set_level(Info)
  db.info("child visible")
  file.close()
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
  let file = open_log_file(path)
  let config = @slog.Config::new(level=Info)
  let logger = @slog.Logger(
    @slog.JsonHandler(file as &@sync/io.Writer),
    category="app",
    config~,
  )
  let db = logger.child(category="db")
  let query = db.child(category="query")
  let db2 = logger.child(category="db2")
  config.set_category_level("app.db", Debug)
  db.debug("db debug")
  query.trace("query trace hidden")
  db2.debug("db2 debug hidden")
  config.set_category_level("app.db.query", Trace)
  query.trace("query trace")
  file.close()
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
  let config = @slog.Config::new()
  for category in ["", ".app", "app.", "app..db"] {
    let result : Result[Unit, @slog.ConfigError] = try
      config.set_category_level(category, Debug)
    catch {
      err => Err(err)
    } noraise {
      value => Ok(value)
    }
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
  let config = @slog.Config::from_env(env~)
  @env.unset_env_var(env)
  let path = "_build/test.config.env"
  let file = open_log_file(path)
  let logger = @slog.Logger(
    @slog.JsonHandler(file as &@sync/io.Writer),
    category="app",
    config~,
  )
  let db = logger.child(category="db")
  let query = db.child(category="query")
  logger.info("app info hidden")
  logger.warn("app warn")
  db.debug("db debug")
  query.trace("query trace")
  file.close()
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
  let config = @slog.Config::from_env()
  @env.unset_env_var("MOON_SLOG")
  let path = "_build/test.config.default.env"
  let file = open_log_file(path)
  let logger = @slog.Logger(
    @slog.JsonHandler(file as &@sync/io.Writer),
    config~,
  )
  logger.debug("default env debug")
  logger.trace("default env trace hidden")
  file.close()
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
  let result : Result[@slog.Config, @slog.ConfigError] = try
    @slog.Config::from_env(env~)
  catch {
    err => Err(err)
  } noraise {
    value => Ok(value)
  }
  @env.unset_env_var(env)
  guard result is Err(_) else {
    fail("expect invalid env directive to be rejected")
  }
}

///|
test "multi destination logger writes to all files" {
  let ps = ["_build/test.multi.sync.0", "_build/test.multi.sync.1"]
  let files = ps.map(open_log_file)
  let handlers = files.map(file => {
    @slog.JsonHandler(file as &@sync/io.Writer) as &@slog.Handler
  })
  let logger = @slog.Logger(@slog.MultiHandler(handlers))
  logger.info("sync fanout")
  for file in files {
    file.close()
  }
  for p in ps {
    guard read_entries(p) is [line] else { fail("expect exactly one line") }
    guard line is Object(object) else { fail("expect an object") }
    guard object.get("message") is Some("sync fanout") else {
      fail("expect fanout message")
    }
  }
}
