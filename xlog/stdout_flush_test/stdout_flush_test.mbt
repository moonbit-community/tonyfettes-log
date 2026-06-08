///|
fn module_cwd() -> String {
  let cwd = @env.current_dir().unwrap_or(".")
  if cwd.has_suffix("/xlog/stdout_flush_test") {
    "."
  } else if cwd.has_suffix("/xlog") {
    "stdout_flush_test"
  } else {
    "xlog/stdout_flush_test"
  }
}

///|
async test "stdout handler flushes before child process exits" {
  @async.with_task_group() <| group => {
    let (stdout, pipe) = @process.read_from_process()
    defer stdout.close()
    let child = @process.spawn(
      group,
      "moon",
      ["run", "--target-dir", "_build/child-run", "child"],
      stdout=pipe,
      cwd=module_cwd(),
    )
    let line = @async.with_timeout_opt(1000, () => stdout.read_until("\n"))
    guard line is Some(Some(line)) else {
      child.cancel()
      fail("expected stdout log line before child exits")
    }
    guard child.try_wait() is None else {
      fail("expected child to still be sleeping after stdout read")
    }
    child.cancel()
    guard line.contains("stdout flush probe") else {
      fail("expected flushed stdout line to contain probe message")
    }
  }
}
