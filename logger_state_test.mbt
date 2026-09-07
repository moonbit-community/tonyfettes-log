///|
priv struct Capture {
  messages : Array[Json]
}

///|
impl @xlog.Handler for Capture with fn handle(self, entry) {
  self.messages.push(entry.fields.get("message").unwrap())
}

///|
test "restore preserves handler root level and category configuration" {
  let original = Capture::{ messages: [], }
  let temporary = Capture::{ messages: [], }
  let config = @xlog.Config(level=@xlog.Warn)
  config.set_category_level("app.db", @xlog.Debug)
  let logger = @xlog.Logger(original, config~)
  logger.set_level(@xlog.Error)
  let saved = logger.save()
  logger.set_handler(temporary)
  logger.set_config(@xlog.Config(level=@xlog.Trace))
  logger.info() <? { "message": "temporary" }
  logger.restore(saved)
  logger.warn() <? { "message": "filtered" }
  logger.error() <? { "message": "restored" }
  logger.debug(category="app.db.query") <? { "message": "category restored" }
  assert_eq(original.messages, [
    Json::string("restored"),
    Json::string("category restored"),
  ])
  assert_eq(temporary.messages, [Json::string("temporary")])
}

///|
test "restore removes a temporary configuration and supports nested scopes" {
  let original = Capture::{ messages: [], }
  let logger = @xlog.Logger(original, level=@xlog.Debug)
  let outer = logger.save()
  let config = @xlog.Config(level=@xlog.Fatal)
  config.set_category_level("app", @xlog.Fatal)
  logger.set_config(config)
  let inner = logger.save()
  logger.set_level(@xlog.Trace)
  logger.restore(inner)
  logger.error() <? { "message": "filtered" }
  logger.restore(outer)
  logger.debug(category="app") <? { "message": "restored without config" }
  assert_eq(original.messages, [Json::string("restored without config")])
}
