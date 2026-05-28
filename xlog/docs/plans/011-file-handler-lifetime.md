# File handler lifetime checkpoint

## Goal

Make `@xlog.File` safer to install into long-lived handlers such as
`@xlog.global().set_handler(...)` by allowing the underlying native file handle
to stay alive as long as the handler object is reachable.

## Accepted design

- Rework `xlog/internal/fs.File` from a raw `#external` C-managed `FILE *` to a
  GC-managed external object allocated with `moonbit_make_external_object`.
- Keep file I/O itself ISO C based: `fopen`, `fwrite`, `fflush`, and `fclose`.
- Keep explicit `File::close()` as an idempotent, non-raising early-close hook.
- Let the external object finalizer close the file automatically if the caller
  does not explicitly close it.
- Keep write/flush on a closed file reporting `@fs.IOError`.
- Remove the extra optional handle state from public `@xlog.File`; the internal
  fs handle now owns its closed/open state.

## Target files and surfaces

- `xlog/internal/fs/fs.mbt`
- `xlog/internal/fs/native.c`
- `xlog/writer.mbt`
- `xlog/log_test.mbt`
- `xlog/log_wbtest.mbt`
- README/example docs if their close guidance becomes misleading
- generated `pkg.generated.mbti` files through `moon info`

## API/interface diff

- Intended public `tonyfettes/xlog` `.mbti` diff: none.
- Intended public `tonyfettes/xlog/internal/fs` `.mbti` diff: none except the
  implementation detail that `File` is no longer marked `#external`.

## Open questions

- The finalizer closes at GC time, not deterministically at scope exit.
- If a caller explicitly calls `file.close()` while the file handler is still
  installed globally, later writes still fail; this remains caller-controlled
  early close behavior.

## Next implementation step

Change the internal fs native handle to a GC-managed external object and simplify
the `@xlog.File` wrapper to store the handle directly.

## Validation plan

- `moon fmt .`
- `moon check .`
- `moon test .`
- `moon bench --package tonyfettes/xlog --file config_bench_test.mbt`
- `moon info .`
