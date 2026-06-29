///|
fn main {
  let config = @xlog.Config::from_env() catch { _ => @xlog.Config() }
  let logger = @xlog.Logger(@xlog.Stdout(), config~)
  logger.error(category="lorem") <?
    { "message": "failed to parse paragraph", "line": 42, "token": "dolor" }
  logger.warn(category="lorem") <?
    { "message": "using fallback corpus", "source": "embedded" }
  logger.info(category="lorem") <?
    { "message": "generated lorem paragraph", "words": 128, "seed": "ipsum" }
  logger.debug(category="lorem.parser") <?
    { "message": "normalized input text", "chars": 738, "language": "latin" }
  logger.trace(category="lorem.parser.lexer") <?
    { "message": "accepted token", "kind": "word", "value": "ipsum" }
  logger.debug(category="lorem.db") <?
    { "message": "selected phrase batch", "batch": 7, "rows": 3 }
  logger.trace(category="lorem.db") <?
    {
      "message": "phrase candidate",
      "candidate": "consectetur adipiscing elit",
    }
  logger.info(category="lorem.cache") <?
    { "message": "cache warmed", "entries": 12 }
  logger.debug(category="lorem.cache") <?
    { "message": "cache hit", "key": "paragraph:seed:ipsum" }
  logger.warn(category="lorem.net") <?
    { "message": "remote corpus unavailable", "host": "example.invalid" }
  logger.debug(category="lorem.net") <?
    { "message": "retry scheduled", "delay_ms": 250 }
  logger.debug(category="lorem.worker") <?
    { "message": "scheduled renderer job", "queue": "lorem", "attempt": 1 }
  logger.trace(category="lorem.worker") <?
    { "message": "renderer job payload", "payload": "sed do eiusmod tempor" }
  logger.info(category="lorem.export") <?
    { "message": "export completed", "format": "txt" }
  logger.debug(category="lorem.export.markdown") <?
    { "message": "rendered heading", "level": 2 }
  logger.trace(category="lorem.export.markdown") <?
    { "message": "rendered span", "style": "emphasis" }
  logger.info(category="lorem.ui") <?
    { "message": "preview refreshed", "pane": "output" }
  logger.debug(category="lorem.ui") <?
    { "message": "cursor moved", "row": 3, "col": 18 }
  @xlog.global().set_handler(@xlog.Stdout())
  @xlog.global().set_config(config)
  @xlog.info(category="lorem.cli") <?
    { "message": "started lorem command", "mode": "preview" }
  @xlog.debug(category="lorem.cli") <?
    { "message": "parsed command flags", "count": 3 }
  @xlog.warn(category="lorem.cli") <?
    { "message": "using default output width", "columns": 80 }
}
