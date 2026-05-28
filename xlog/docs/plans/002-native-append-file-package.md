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

