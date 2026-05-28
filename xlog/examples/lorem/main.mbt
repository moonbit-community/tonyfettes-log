///|
fn main {
  let config = @xlog.Config::from_env() catch { _ => @xlog.Config::new() }
  let logger = @xlog.Logger(@xlog.Stdout(), category="lorem", config~)
  let db = logger.child(category="db")
  let parser = logger.child(category="parser")
  let lexer = parser.child(category="lexer")
  let worker = logger.child(category="worker")
  let cache = logger.child(category="cache")
  let net = logger.child(category="net")
  let exporter = logger.child(category="export")
  let markdown = exporter.child(category="markdown")
  let ui = logger.child(category="ui")
  logger.error("failed to parse paragraph", fields={
    "line": 42,
    "token": "dolor",
  })
  logger.warn("using fallback corpus", fields={ "source": "embedded" })
  logger.info("generated lorem paragraph", fields={
    "words": 128,
    "seed": "ipsum",
  })
  parser.debug("normalized input text", fields={
    "chars": 738,
    "language": "latin",
  })
  lexer.trace("accepted token", fields={ "kind": "word", "value": "ipsum" })
  db.debug("selected phrase batch", fields={ "batch": 7, "rows": 3 })
  db.trace("phrase candidate", fields={
    "candidate": "consectetur adipiscing elit",
  })
  cache.info("cache warmed", fields={ "entries": 12 })
  cache.debug("cache hit", fields={ "key": "paragraph:seed:ipsum" })
  net.warn("remote corpus unavailable", fields={ "host": "example.invalid" })
  net.debug("retry scheduled", fields={ "delay_ms": 250 })
  worker.debug("scheduled renderer job", fields={
    "queue": "lorem",
    "attempt": 1,
  })
  worker.trace("renderer job payload", fields={
    "payload": "sed do eiusmod tempor",
  })
  exporter.info("export completed", fields={ "format": "txt" })
  markdown.debug("rendered heading", fields={ "level": 2 })
  markdown.trace("rendered span", fields={ "style": "emphasis" })
  ui.info("preview refreshed", fields={ "pane": "output" })
  ui.debug("cursor moved", fields={ "row": 3, "col": 18 })
}
