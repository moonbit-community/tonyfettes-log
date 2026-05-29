///|
fn main {
  let config = @xlog.Config::from_env() catch { _ => @xlog.Config() }
  let logger = @xlog.Logger(@xlog.Stdout(), config~)
  logger.error(
    {
      "message": "failed to parse paragraph",
      "line": 42,
      "token": "dolor",
    },
    category="lorem",
  )
  logger.warn(
    { "message": "using fallback corpus", "source": "embedded" },
    category="lorem",
  )
  logger.info(
    { "message": "generated lorem paragraph", "words": 128, "seed": "ipsum" },
    category="lorem",
  )
  logger.debug(
    { "message": "normalized input text", "chars": 738, "language": "latin" },
    category="lorem.parser",
  )
  logger.trace(
    { "message": "accepted token", "kind": "word", "value": "ipsum" },
    category="lorem.parser.lexer",
  )
  logger.debug(
    { "message": "selected phrase batch", "batch": 7, "rows": 3 },
    category="lorem.db",
  )
  logger.trace(
    {
      "message": "phrase candidate",
      "candidate": "consectetur adipiscing elit",
    },
    category="lorem.db",
  )
  logger.info(
    { "message": "cache warmed", "entries": 12 },
    category="lorem.cache",
  )
  logger.debug(
    { "message": "cache hit", "key": "paragraph:seed:ipsum" },
    category="lorem.cache",
  )
  logger.warn(
    { "message": "remote corpus unavailable", "host": "example.invalid" },
    category="lorem.net",
  )
  logger.debug(
    { "message": "retry scheduled", "delay_ms": 250 },
    category="lorem.net",
  )
  logger.debug(
    { "message": "scheduled renderer job", "queue": "lorem", "attempt": 1 },
    category="lorem.worker",
  )
  logger.trace(
    { "message": "renderer job payload", "payload": "sed do eiusmod tempor" },
    category="lorem.worker",
  )
  logger.info(
    { "message": "export completed", "format": "txt" },
    category="lorem.export",
  )
  logger.debug(
    { "message": "rendered heading", "level": 2 },
    category="lorem.export.markdown",
  )
  logger.trace(
    { "message": "rendered span", "style": "emphasis" },
    category="lorem.export.markdown",
  )
  logger.info(
    { "message": "preview refreshed", "pane": "output" },
    category="lorem.ui",
  )
  logger.debug(
    { "message": "cursor moved", "row": 3, "col": 18 },
    category="lorem.ui",
  )
}
