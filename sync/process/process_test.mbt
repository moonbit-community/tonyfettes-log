// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
fn cleanup_process_test_dir(path : String) -> Unit {
  @fs.rmdir(path, recursive=true) catch {
    _ => ()
  }
}

///|
test "run exit code" {
  inspect(@process.run("sh", ["-c", "exit 42"]), content="42")
}

///|
test "collect stdout" {
  let (code, out) = @process.collect_stdout("sh", ["-c", "printf hello"])
  inspect(code, content="0")
  inspect(out.text(), content="hello")
}

///|
test "collect stderr" {
  let (code, err) = @process.collect_stderr("sh", ["-c", "printf err >&2"])
  inspect(code, content="0")
  inspect(err.text(), content="err")
}

///|
test "collect output" {
  let (code, out, err) = @process.collect_output("sh", [
    "-c", "printf out; printf err >&2",
  ])
  inspect(code, content="0")
  inspect(out.text(), content="out")
  inspect(err.text(), content="err")
}

///|
test "collect output merged" {
  let (code, out) = @process.collect_output_merged("sh", [
    "-c", "printf out; printf err >&2",
  ])
  inspect(code, content="0")
  inspect(out.text(), content="outerr")
}

///|
test "collect large stderr" {
  let (code, out, err) = @process.collect_output("sh", [
    "-c", "dd if=/dev/zero bs=1024 count=1024 1>&2 2>/dev/null",
  ])
  inspect(code, content="0")
  inspect(out.binary().length(), content="0")
  inspect(err.binary().length(), content="1048576")
}

///|
test "collect stderr with stdout redirect" {
  let dir = @fs.tmpdir(prefix="sync-process-collect-stderr")
  defer cleanup_process_test_dir(dir)
  let output = "\{dir}/stdout.txt"
  let (code, err) = @process.collect_stderr(
    "sh",
    ["-c", "printf out; printf err >&2"],
    stdout=@process.redirect_to_file(output, create_mode=CreateOrTruncate),
  )
  inspect(code, content="0")
  inspect(err.text(), content="err")
  inspect(@fs.read_file(output).text(), content="out")
}

///|
test "extra env" {
  let (code, out) = @process.collect_stdout(
    "sh",
    ["-c", "printf %s \"$MAGIC_VAR\""],
    extra_env={ "MAGIC_VAR": "MAGIC_VALUE" },
  )
  inspect(code, content="0")
  inspect(out.text(), content="MAGIC_VALUE")
}

///|
test "run without inherited env" {
  let (code, out) = @process.collect_stdout(
    "/usr/bin/env",
    [],
    inherit_env=false,
  )
  inspect(code, content="0")
  inspect(out.text(), content="")
}

///|
test "extra env without inherited env dump" {
  let (code, out) = @process.collect_stdout(
    "/usr/bin/env",
    [],
    extra_env={
      "MAGIC_VAR_1": "MAGIC_VALUE_1",
      "MAGIC_VAR_2": "MAGIC_VALUE_2",
      "MAGIC_VAR_3": "MAGIC_VALUE_3",
      "MAGIC_VAR_4": "MAGIC_VALUE_4",
    },
    inherit_env=false,
  )
  inspect(code, content="0")
  let lines = out
    .text()
    .replace_all(old="\r\n", new="\n")
    .trim(char_set="\n\r ")
    .split("\n")
    .to_array()
  lines.sort()
  json_inspect(lines, content=[
    "MAGIC_VAR_1=MAGIC_VALUE_1", "MAGIC_VAR_2=MAGIC_VALUE_2", "MAGIC_VAR_3=MAGIC_VALUE_3",
    "MAGIC_VAR_4=MAGIC_VALUE_4",
  ])
}

///|
test "redirect file" {
  let dir = @fs.tmpdir(prefix="sync-process-redirect")
  defer cleanup_process_test_dir(dir)
  let input = "\{dir}/in.txt"
  let output = "\{dir}/out.txt"
  @fs.write_file(input, "abcd", create_mode=CreateNew)
  let code = @process.run(
    "cat",
    [],
    stdin=@process.redirect_from_file(input),
    stdout=@process.redirect_to_file(output, create_mode=CreateOrTruncate),
  )
  inspect(code, content="0")
  inspect(@fs.read_file(output).text(), content="abcd")
}

///|
test "redirect_to_file append" {
  let dir = @fs.tmpdir(prefix="sync-process-append")
  defer cleanup_process_test_dir(dir)
  let output = "\{dir}/out.txt"
  inspect(
    @process.run(
      "sh",
      ["-c", "printf ab"],
      stdout=@process.redirect_to_file(output, create_mode=CreateOrTruncate),
    ),
    content="0",
  )
  inspect(
    @process.run(
      "sh",
      ["-c", "printf cd"],
      stdout=@process.redirect_to_file(
        output,
        append=true,
        create_mode=OpenExisting,
      ),
    ),
    content="0",
  )
  inspect(@fs.read_file(output).text(), content="abcd")
}

///|
test "collect stdout from redirected stdin" {
  let dir = @fs.tmpdir(prefix="sync-process-stdin")
  defer cleanup_process_test_dir(dir)
  let input = "\{dir}/in.txt"
  @fs.write_file(input, "stdin payload", create_mode=CreateNew)
  let (code, out) = @process.collect_stdout(
    "cat",
    [],
    stdin=@process.redirect_from_file(input),
  )
  inspect(code, content="0")
  inspect(out.text(), content="stdin payload")
}

///|
test "redirect pipe" {
  let (cat_read, we_write) = @process.write_to_process()
  let (we_read, cat_write) = @process.read_from_process()
  defer we_read.close()
  let process = @process.spawn("cat", [], stdin=cat_read, stdout=cat_write)
  we_write.write("abcd\n")
  we_write.write("defg\n")
  we_write.close()
  inspect(
    we_read.read_all().text(),
    content=(
      #|abcd
      #|defg
      #|
    ),
  )
  inspect(process.wait(), content="0")
}

///|
test "read_from_process pipe" {
  let (r, w) = @process.read_from_process()
  defer r.close()
  let process = @process.spawn("sh", ["-c", "printf pipe"], stdout=w)
  inspect(r.read_all().text(), content="pipe")
  inspect(process.wait(), content="0")
}

///|
test "merge stdout and stderr to same pipe" {
  let (r, w) = @pipe.pipe()
  defer r.close()
  let process = @process.spawn(
    "sh",
    ["-c", "printf abcd; printf efgh >&2"],
    stdout=w,
    stderr=w,
  )
  inspect(process.wait(), content="0")
  w.close()
  inspect(r.read_all().text(), content="abcdefgh")
}

///|
test "merge multiple process output" {
  let (r, w) = @pipe.pipe()
  defer r.close()
  let p1 = @process.spawn("sh", ["-c", "printf 'abcd\n'"], stdout=w)
  let p2 = @process.spawn("sh", ["-c", "sleep 1; printf 'efgh\n'"], stdout=w)
  inspect(p1.wait(), content="0")
  inspect(p2.wait(), content="0")
  w.close()
  inspect(
    r.read_all().text(),
    content=(
      #|abcd
      #|efgh
      #|
    ),
  )
}

///|
test "spawn wait and try_wait" {
  let process = @process.spawn("sh", ["-c", "exit 7"])
  inspect(process.wait(), content="7")
  inspect(process.wait(), content="7")
  guard process.try_wait() is Some(code)
  inspect(code, content="7")
}

///|
test "try_wait running process" {
  let process = @process.spawn(
    "sleep",
    ["5"],
    cancel_handler=@process.hard_cancel(),
  )
  assert_true(process.try_wait() is None)
  process.cancel()
  assert_true(process.wait() != 0)
}

///|
test "graceful cancel process" {
  let (r, w) = @process.read_from_process()
  defer r.close()
  let process = @process.spawn(
    "sh",
    [
      "-c", "trap 'printf terminated; exit 0' TERM; printf ready; while :; do :; done",
    ],
    stdout=w,
    cancel_handler=@process.graceful_cancel(timeout=250, signal=@signal.SIGTERM),
  )
  inspect(@utf8.decode(r.read_exactly(5)), content="ready")
  process.cancel()
  inspect(r.read_all().text(), content="terminated")
  inspect(process.wait(), content="0")
}

///|
test "hard cancel process" {
  let (r, w) = @process.read_from_process()
  defer r.close()
  let process = @process.spawn(
    "sh",
    ["-c", "printf ready; sleep 10; printf after"],
    stdout=w,
    cancel_handler=@process.hard_cancel(),
  )
  inspect(@utf8.decode(r.read_exactly(5)), content="ready")
  process.cancel()
  inspect(r.read_all().text(), content="")
  assert_true(process.wait() != 0)
}

///|
test "wait_pid" {
  let pid = @process.spawn_orphan("sh", ["-c", "exit 42"])
  inspect(@process.wait_pid(pid), content="42")
}

///|
test "cwd" {
  let dir = @fs.tmpdir(prefix="sync-process-cwd")
  defer cleanup_process_test_dir(dir)
  @fs.write_file("\{dir}/marker", "", create_mode=CreateNew)
  let (code, out) = @process.collect_stdout(
    "sh",
    ["-c", "test -f marker && printf ok"],
    cwd=dir,
  )
  inspect(code, content="0")
  inspect(out.text(), content="ok")
}

///|
test "extra env without inherit" {
  let (code, out) = @process.collect_stdout(
    "sh",
    [
      "-c", "printf '%s:%s' \"$MAGIC_VAR\" \"${SYNC_PROCESS_SHOULD_NOT_LEAK-unset}\"",
    ],
    extra_env={ "MAGIC_VAR": "MAGIC_VALUE" },
    inherit_env=false,
  )
  inspect(code, content="0")
  inspect(out.text(), content="MAGIC_VALUE:unset")
}

///|
test "missing command raises os_error" {
  let result = try? @process.run("sync-command-that-does-not-exist", [])
  guard result is Err(@os_error.OSError(_) as err) else {
    fail("result is not OSError")
  }
  assert_true(err.is_ENOENT())
}

///|
test "missing cwd raises os_error" {
  let result = try? @process.run(
    "sh",
    ["-c", "printf unreachable"],
    cwd="/tmp/sync-cwd-does-not-exist",
  )
  guard result is Err(@os_error.OSError(_) as err) else {
    fail("result is not OSError")
  }
  assert_true(err.is_ENOENT())
}
