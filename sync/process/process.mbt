// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

///|
fn encode(s : StringView) -> Bytes {
  @utf8.encode(s)
}

///|
fn make_argv(cmd : StringView, args : ArrayView[String]) -> FixedArray[Bytes?] {
  let argv = FixedArray::make(args.length() + 2, None)
  argv[0] = Some(encode(cmd))
  for i in 0..<args.length() {
    argv[i + 1] = Some(encode(args[i]))
  }
  argv
}

///|
fn make_env(
  extra_env : Map[String, String],
  inherit_env~ : Bool,
) -> FixedArray[Bytes?] {
  let extra_count = extra_env.length()
  match (inherit_env, extra_count) {
    (true, 0) => get_curr_env_ffi()
    (false, 0) => [None]
    (_, n) => {
      let curr_env = if inherit_env { get_curr_env_ffi() } else { [None] }
      let env = FixedArray::make(n + curr_env.length(), None)
      let mut i = 0
      for k, v in extra_env {
        env[i] = Some(encode("\{k}=\{v}"))
        i = i + 1
      }
      curr_env.blit_to(env, src_offset=0, dst_offset=i, len=curr_env.length())
      env
    }
  }
}

///|
fn raw_spawn(
  cmd : StringView,
  args : ArrayView[String],
  extra_env~ : Map[String, String],
  inherit_env~ : Bool,
  stdin~ : &ProcessInput?,
  stdout~ : &ProcessOutput?,
  stderr~ : &ProcessOutput?,
  cwd~ : StringView?,
  context~ : String,
) -> Int raise {
  let stdin_fd = stdin.map(p => p.fd()).unwrap_or(-1)
  let stdout_fd = stdout.map(p => p.fd()).unwrap_or(-1)
  let stderr_fd = stderr.map(p => p.fd()).unwrap_or(-1)
  defer {
    if stdin is Some(p) {
      p.after_spawn()
    }
    if stdout is Some(p) {
      p.after_spawn()
    }
    if stderr is Some(p) {
      p.after_spawn()
    }
  }
  let cwd_bytes = cwd.map(cwd => encode(cwd)).unwrap_or(b"")
  let pid = spawn_ffi(
    encode(cmd),
    make_argv(cmd, args),
    make_env(extra_env, inherit_env~),
    stdin_fd,
    stdout_fd,
    stderr_fd,
    cwd is Some(_),
    cwd_bytes,
  )
  guard pid >= 0 else { raise_os_error(context) }
  pid
}

///|
pub fn spawn_orphan(
  cmd : StringView,
  args : ArrayView[String],
  extra_env? : Map[String, String] = {},
  inherit_env? : Bool = true,
  stdin? : &ProcessInput,
  stdout? : &ProcessOutput,
  stderr? : &ProcessOutput,
  cwd? : StringView,
) -> Int raise {
  raw_spawn(
    cmd,
    args,
    extra_env~,
    inherit_env~,
    stdin~,
    stdout~,
    stderr~,
    cwd~,
    context="@process.spawn_orphan()",
  )
}

///|
pub fn wait_pid(pid : Int) -> Int raise {
  let out = Ref(0)
  check(wait_pid_ffi(pid, out), "@process.wait_pid()")
  out.val
}

///|
pub struct Process {
  pid : Int
  priv mut exit_code : Int?
  priv cancel_handler : CancellationHandler
}

///|
pub fn Process::wait(self : Process) -> Int raise {
  match self.exit_code {
    Some(code) => code
    None => {
      let code = wait_pid(self.pid)
      self.exit_code = Some(code)
      code
    }
  }
}

///|
pub fn Process::try_wait(self : Process) -> Int? raise {
  match self.exit_code {
    Some(code) => Some(code)
    None => {
      let out = Ref(0)
      let ret = try_wait_pid_ffi(self.pid, out)
      if ret < 0 {
        raise_os_error("@process.Process::try_wait()")
      } else if ret == 0 {
        None
      } else {
        self.exit_code = Some(out.val)
        Some(out.val)
      }
    }
  }
}

///|
pub fn Process::cancel(self : Process) -> Unit {
  (self.cancel_handler)(self.pid)
}

///|
pub fn spawn(
  cmd : StringView,
  args : ArrayView[String],
  extra_env? : Map[String, String] = {},
  inherit_env? : Bool = true,
  stdin? : &ProcessInput,
  stdout? : &ProcessOutput,
  stderr? : &ProcessOutput,
  cwd? : StringView,
  cancel_handler? : CancellationHandler = graceful_cancel(timeout=5000),
  no_wait? : Bool = false,
) -> Process raise {
  let _no_wait = no_wait
  let pid = raw_spawn(
    cmd,
    args,
    extra_env~,
    inherit_env~,
    stdin~,
    stdout~,
    stderr~,
    cwd~,
    context="@process.spawn()",
  )
  { pid, exit_code: None, cancel_handler }
}

///|
pub fn run(
  cmd : StringView,
  args : ArrayView[String],
  extra_env? : Map[String, String] = {},
  inherit_env? : Bool = true,
  stdin? : &ProcessInput,
  stdout? : &ProcessOutput,
  stderr? : &ProcessOutput,
  cwd? : StringView,
  cancel_handler? : CancellationHandler = graceful_cancel(timeout=5000),
) -> Int raise {
  spawn(
    cmd,
    args,
    extra_env~,
    inherit_env~,
    stdin?,
    stdout?,
    stderr?,
    cwd?,
    cancel_handler~,
  ).wait()
}

///|
fn cleanup_dir(path : String) -> Unit {
  @fs.rmdir(path, recursive=true) catch {
    _ => ()
  }
}

///|
pub fn collect_stdout(
  cmd : StringView,
  args : ArrayView[String],
  extra_env? : Map[String, String] = {},
  inherit_env? : Bool = true,
  stdin? : &ProcessInput,
  stderr? : &ProcessOutput,
  cwd? : StringView,
) -> (Int, &@io.Data) raise {
  let dir = @fs.tmpdir(prefix="sync-process-stdout")
  defer cleanup_dir(dir)
  let path = "\{dir}/stdout"
  let code = run(
    cmd,
    args,
    extra_env~,
    inherit_env~,
    stdin?,
    stdout=redirect_to_file(path, create_mode=CreateOrTruncate),
    stderr?,
    cwd?,
  )
  (code, @fs.read_file(path))
}

///|
pub fn collect_stderr(
  cmd : StringView,
  args : ArrayView[String],
  extra_env? : Map[String, String] = {},
  inherit_env? : Bool = true,
  stdin? : &ProcessInput,
  stdout? : &ProcessOutput,
  cwd? : StringView,
) -> (Int, &@io.Data) raise {
  let dir = @fs.tmpdir(prefix="sync-process-stderr")
  defer cleanup_dir(dir)
  let path = "\{dir}/stderr"
  let code = run(
    cmd,
    args,
    extra_env~,
    inherit_env~,
    stdin?,
    stdout?,
    stderr=redirect_to_file(path, create_mode=CreateOrTruncate),
    cwd?,
  )
  (code, @fs.read_file(path))
}

///|
pub fn collect_output(
  cmd : StringView,
  args : ArrayView[String],
  extra_env? : Map[String, String] = {},
  inherit_env? : Bool = true,
  stdin? : &ProcessInput,
  cwd? : StringView,
) -> (Int, &@io.Data, &@io.Data) raise {
  let dir = @fs.tmpdir(prefix="sync-process-output")
  defer cleanup_dir(dir)
  let stdout_path = "\{dir}/stdout"
  let stderr_path = "\{dir}/stderr"
  let code = run(
    cmd,
    args,
    extra_env~,
    inherit_env~,
    stdin?,
    stdout=redirect_to_file(stdout_path, create_mode=CreateOrTruncate),
    stderr=redirect_to_file(stderr_path, create_mode=CreateOrTruncate),
    cwd?,
  )
  (code, @fs.read_file(stdout_path), @fs.read_file(stderr_path))
}

///|
pub fn collect_output_merged(
  cmd : StringView,
  args : Array[String],
  extra_env? : Map[String, String] = {},
  inherit_env? : Bool = true,
  stdin? : &ProcessInput,
  cwd? : StringView,
) -> (Int, &@io.Data) raise {
  let dir = @fs.tmpdir(prefix="sync-process-output-merged")
  defer cleanup_dir(dir)
  let path = "\{dir}/output"
  let output = redirect_to_file(path, create_mode=CreateOrTruncate)
  let code = run(
    cmd,
    args,
    extra_env~,
    inherit_env~,
    stdin?,
    stdout=output,
    stderr=output,
    cwd?,
  )
  (code, @fs.read_file(path))
}
