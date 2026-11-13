///|
/// A minimal example that routes log output to standard error.
fn main {
  let config = @xlog.Config::from_env() catch { _ => @xlog.Config() }
  let logger = @xlog.Logger(@xlog.Stderr(), config~)
  logger.error(category="stderr") <?
    { "message": "example error on stderr", "line": 42 }
  logger.info(category="stderr") <?
    { "message": "example info on stderr", "words": 128 }
  @xlog.global().set_handler(@xlog.Stderr(format=@xlog.Text))
  @xlog.warn(category="stderr") <? { "message": "text format on stderr" }
}
