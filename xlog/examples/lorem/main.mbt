///|
fn main {
  let config = @xlog.Config::from_env() catch { _ => @xlog.Config::new() }
  let logger = @xlog.Logger(@xlog.Stdout(), category="lorem", config~)
  let db = logger.child(category="db")
  let worker = logger.child(category="worker")
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
  db.debug("selected phrase batch", fields={ "batch": 7, "rows": 3 })
  db.trace("phrase candidate", fields={
    "candidate": "consectetur adipiscing elit",
  })
  worker.debug("scheduled renderer job", fields={
    "queue": "lorem",
    "attempt": 1,
  })
  worker.trace("renderer job payload", fields={
    "payload": "sed do eiusmod tempor",
  })
  ui.info("preview refreshed", fields={ "pane": "output" })
}
