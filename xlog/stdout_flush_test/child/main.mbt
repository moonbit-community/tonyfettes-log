///|
async fn main {
  let logger = @xlog.Logger(@xlog.Stdout())
  logger.info(category="flush") <? { "message": "stdout flush probe" }
  @async.sleep(2000)
}
