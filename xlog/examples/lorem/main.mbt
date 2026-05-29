///|
fn emit(event : @xlog.Event?, write : (@xlog.Event) -> Unit) -> Unit {
  if event is Some(event) {
    event.write_object_begin()
    write(event)
    event.write_object_end()
  }
}

///|
fn main {
  let config = @xlog.Config::from_env() catch { _ => @xlog.Config() }
  let logger = @xlog.Logger(@xlog.Stdout(), config~)
  emit(logger.error(category="lorem"), event => {
    event.write_object_field("message", "failed to parse paragraph")
    event.write_object_field("line", 42)
    event.write_object_field("token", "dolor")
  })
  emit(logger.warn(category="lorem"), event => {
    event.write_object_field("message", "using fallback corpus")
    event.write_object_field("source", "embedded")
  })
  emit(logger.info(category="lorem"), event => {
    event.write_object_field("message", "generated lorem paragraph")
    event.write_object_field("words", 128)
    event.write_object_field("seed", "ipsum")
  })
  emit(logger.debug(category="lorem.parser"), event => {
    event.write_object_field("message", "normalized input text")
    event.write_object_field("chars", 738)
    event.write_object_field("language", "latin")
  })
  emit(logger.trace(category="lorem.parser.lexer"), event => {
    event.write_object_field("message", "accepted token")
    event.write_object_field("kind", "word")
    event.write_object_field("value", "ipsum")
  })
  emit(logger.debug(category="lorem.db"), event => {
    event.write_object_field("message", "selected phrase batch")
    event.write_object_field("batch", 7)
    event.write_object_field("rows", 3)
  })
  emit(logger.trace(category="lorem.db"), event => {
    event.write_object_field("message", "phrase candidate")
    event.write_object_field("candidate", "consectetur adipiscing elit")
  })
  emit(logger.info(category="lorem.cache"), event => {
    event.write_object_field("message", "cache warmed")
    event.write_object_field("entries", 12)
  })
  emit(logger.debug(category="lorem.cache"), event => {
    event.write_object_field("message", "cache hit")
    event.write_object_field("key", "paragraph:seed:ipsum")
  })
  emit(logger.warn(category="lorem.net"), event => {
    event.write_object_field("message", "remote corpus unavailable")
    event.write_object_field("host", "example.invalid")
  })
  emit(logger.debug(category="lorem.net"), event => {
    event.write_object_field("message", "retry scheduled")
    event.write_object_field("delay_ms", 250)
  })
  emit(logger.debug(category="lorem.worker"), event => {
    event.write_object_field("message", "scheduled renderer job")
    event.write_object_field("queue", "lorem")
    event.write_object_field("attempt", 1)
  })
  emit(logger.trace(category="lorem.worker"), event => {
    event.write_object_field("message", "renderer job payload")
    event.write_object_field("payload", "sed do eiusmod tempor")
  })
  emit(logger.info(category="lorem.export"), event => {
    event.write_object_field("message", "export completed")
    event.write_object_field("format", "txt")
  })
  emit(logger.debug(category="lorem.export.markdown"), event => {
    event.write_object_field("message", "rendered heading")
    event.write_object_field("level", 2)
  })
  emit(logger.trace(category="lorem.export.markdown"), event => {
    event.write_object_field("message", "rendered span")
    event.write_object_field("style", "emphasis")
  })
  emit(logger.info(category="lorem.ui"), event => {
    event.write_object_field("message", "preview refreshed")
    event.write_object_field("pane", "output")
  })
  emit(logger.debug(category="lorem.ui"), event => {
    event.write_object_field("message", "cursor moved")
    event.write_object_field("row", 3)
    event.write_object_field("col", 18)
  })
}
