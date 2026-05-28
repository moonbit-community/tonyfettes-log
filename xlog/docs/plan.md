# Native append file package checkpoint

## Goal

Add a very small native-only filesystem package under `xlog/internal/fs` for
append-only file output, then use it from `xlog.File` so log entries are appended
directly instead of reading and rewriting the full file.

## Accepted design

- Implement the file primitive as a standalone package:
  `tonyfettes/xlog/internal/fs`.
- Use an explicit-close raw C pointer model:
  - `#external type File` in MoonBit.
  - The C side returns a raw `FILE *` from `fopen`.
  - `File::close` calls `fclose` best-effort and does not raise; callers must
    close explicitly.
  - No GC finalizer or `moonbit_make_external_object`.
- Keep the C implementation strict ISO C:
  - `fopen(path, "ab")` to open or create in append-binary mode.
  - `fwrite` for byte output.
  - `fflush` after each log entry.
  - `fclose` for explicit cleanup.
  - No `O_APPEND`, file descriptors, locks, Windows APIs, errno contracts, or
    OS-specific error classification.
- Model failures as `IOError(String)`, not `OSError(Int, context~)`, because ISO
  C does not provide portable OS error codes with reliable classifier semantics.
- Store the internal file handle privately inside root `xlog.File` as an option
  so root `File::close` can be idempotent and writes after close can be
  self-logged without passing a stale pointer to C.
- Keep logger write calls non-throwing: append/flush failures are caught and
  recorded in `self_log`, matching the current behavior.
- Add an explicit `xlog.File::close()` that closes the underlying internal file
  best-effort.

## Target files and surfaces

- `xlog/moon.pkg`
- `xlog/writer.mbt`
- `xlog/log_test.mbt`
- `xlog/pkg.generated.mbti`
- New `xlog/internal/fs/moon.pkg`
- New `xlog/internal/fs/types.mbt`
- New `xlog/internal/fs/native.mbt`
- New `xlog/internal/fs/native.c`
- New `xlog/internal/fs/pkg.generated.mbti`

## API and interface diff

- Root `xlog.File` remains opaque and still implements `Writer`.
- Root `xlog.File::File(String, format? : Format)` changes from
  `raise @fs.IOError` from `moonbitlang/x/fs` to
  `raise @fs.IOError` from `tonyfettes/xlog/internal/fs`.
- Root `xlog.File::close(Self) -> Unit` is added.
- The internal package exposes:
  - `pub(all) suberror IOError { IOError(String) }`
  - `#external type File`
  - `File::open_append(String) -> File raise IOError`
  - `File::write(File, Bytes) -> Unit raise IOError`
  - `File::write_string(File, String) -> Unit raise IOError`
  - `File::flush(File) -> Unit raise IOError`
  - `File::close(File) -> Unit`
- No GC-managed C handle container is introduced.

## Why existing code cannot be reused as-is

The current `xlog.File.write` reads the entire log file into memory and rewrites
it after appending one rendered entry. That is not a real append-mode file
writer and makes each log call proportional to the existing file size.
`moonbitlang/x/fs` also does not provide the desired small native-only,
append-open file primitive inside this package.

## Open questions

- None for this iteration. Multi-process atomicity, locking, OS-specific error
  codes, and platform-specific append APIs are explicitly out of scope.

## Next implementation step

Create `xlog/internal/fs`, wire `xlog.File` to it, add focused append behavior
coverage, then regenerate generated interfaces.

## Validation plan

Run from `xlog/`:

```sh
moon check
moon test
moon fmt
moon info
```

Review `pkg.generated.mbti` files to ensure only the intended public surface is
exposed.

# Sync I/O split plan

## Goal

Rename the current `log` module to `tonyfettes/xlog` to indicate it remains
based on `moonbitlang/x`, then create a sibling `slog` module that duplicates
the current implementation and replaces file/stdout I/O with
`tonyfettes/sync`.

## Accepted design

### Current module: `/Users/haoxiang/Workspace/moonbit/log`

- Rename `moon.mod` from `tonyfettes/slog` to `tonyfettes/xlog`.
- Update black-box test package aliases from `@slog` to `@xlog`.
- Regenerate `pkg.generated.mbti` with `moon info`.
- Keep the public logging API and current `moonbitlang/x` I/O behavior
  otherwise unchanged.

### New module: `/Users/haoxiang/Workspace/moonbit/feihaoxiang/slog`

- Duplicate the current log implementation into `../feihaoxiang/slog`,
  excluding `.git`, `_build`, and `.mooncakes`.
- Keep the module name `tonyfettes/slog`.
- Keep `moonbitlang/x/time` for timestamps.
- Replace file/stdout I/O in `writer.mbt` with `tonyfettes/sync`:
  - `Stdout.write` writes rendered log lines to `@sync/stdio.stdout`.
  - `File::File` validates or creates the target with
    `@sync/fs.open(..., create_mode=OpenOrCreate, append=true)` and closes it.
  - `File.write` appends with
    `@sync/fs.write_file(..., create_mode=OpenOrCreate, append=true)`.
  - Logging calls remain non-throwing by catching sync write failures into the
    existing `self_log`.
- Add package imports for:
  - `tonyfettes/sync/io`
  - `tonyfettes/sync/fs`
  - `tonyfettes/sync/stdio`
- Add a local `moon.work` with members `"."` and `"../sync"` so the module
  validates against the local sync checkout before registry publishing.

## Target files and surfaces

- `log/moon.mod`
- `log/moon.pkg`
- `log/log_test.mbt`
- `log/pkg.generated.mbti`
- `feihaoxiang/slog/*` duplicated module files
- `feihaoxiang/slog/moon.mod`
- `feihaoxiang/slog/moon.pkg`
- `feihaoxiang/slog/writer.mbt`
- `feihaoxiang/slog/log_test.mbt`
- `feihaoxiang/slog/pkg.generated.mbti`
- `feihaoxiang/slog/moon.work`

## API and interface diff

- Current module generated interface changes package line from:
  `package "tonyfettes/slog"`
  to:
  `package "tonyfettes/xlog"`
- New sync-backed module generated interface remains:
  `package "tonyfettes/slog"`
- Public logging names should remain the same:
  `Logger`, `File`, `Stdout`, `Multi`, `Writer`, `Entry`, `Config`, `Level`,
  and package-level logging functions.
- `File::File` in the sync-backed module may broaden from
  `raise @x/fs.IOError` to an untyped `raise`, because `tonyfettes/sync/fs`
  exposes untyped file/OS errors.
- No concrete `tonyfettes/sync` file or stdio type should leak through public
  `File` or `Stdout` fields.

## Why existing code cannot be reused as-is

The current `File.write` reads the whole log file, appends one rendered entry in
memory, and rewrites the whole file on every log call. That is not a suitable
sync I/O foundation for logging because append throughput becomes proportional
to existing file size, and concurrent or multi-process appends can lose data.
`tonyfettes/sync/fs` provides native append-mode writes and sync-capable file
handles, which are the right lower-level primitive.

## Open questions

- Whether the sync-backed `File` should keep opening and closing per log write
  for minimal API churn, or own a persistent `@sync/fs.File` later with an
  explicit close/lifecycle API.
- Whether `Stdout` should later support stderr as a first-class destination.
- Whether sync-backed write failures should stay hidden in `self_log` long term
  or become configurable.

## Next implementation step

After explicit confirmation, apply the module rename in `log`, duplicate the
module into `../feihaoxiang/slog`, then convert the duplicated `writer.mbt` to
use `tonyfettes/sync`.

## Validation plan

Run these in both `log` and `../feihaoxiang/slog`:

```sh
moon check
moon test
moon fmt
moon info
```

For `../feihaoxiang/slog`, validate through its local `moon.work` so
`tonyfettes/sync` resolves from `../sync`.
