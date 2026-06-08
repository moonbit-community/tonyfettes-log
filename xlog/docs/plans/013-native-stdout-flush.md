# Native stdout flush checkpoint

## Goal

Make `xlog.Stdout` flush after each emitted log entry. The current
implementation uses MoonBit `println`, which does not explicitly flush stdout.

## Accepted design

- Keep the root `Stdout` public API unchanged.
- Add a private native stdout primitive in the root `xlog` package.
- Render each entry in MoonBit using the existing `Format` behavior.
- Encode the rendered line to UTF-8 bytes before crossing the FFI boundary.
- Write stdout in C using `fwrite`, append one newline with `fputc`, and call
  `fflush(stdout)` before returning.
- Report write or flush failure as `@fs.IOError`; ordinary logger calls already
  swallow handler errors, while direct `Stdout.handle` calls can observe them.
- Do not extend `xlog/internal/fs`, so its generated interface stays focused on
  file handling.

## Target files and surfaces

- `xlog/moon.pkg`
- `xlog/writer.mbt`
- `xlog/pkg.generated.mbti`
- New `xlog/native.c`

## API and interface diff

- `Stdout::Stdout(format? : Format) -> Stdout` remains unchanged.
- `Stdout` remains opaque and continues to implement `Handler`.
- `Handler` remains `fn handle(Self, Entry) -> Unit raise`.
- `xlog/pkg.generated.mbti` is expected to have no public API changes.

## Why existing code cannot be reused as-is

`println` does not provide an explicit flush point. The sibling `sync/stdio`
writer exposes fd writes but not stdout flushing, and extending
`xlog/internal/fs` would expose stdout operations through an internal package
whose current responsibility is file handles.

## Open questions

- None. Stderr support, buffering configuration, and OS-specific stdout handles
  are out of scope for this change.

## Next implementation step

Add the private native stdout FFI and replace `Stdout.handle`'s `println` calls
with the flushed write path.

## Validation plan

Run from `xlog/`:

```sh
moon check
moon test
moon fmt
moon info
```

Review `xlog/pkg.generated.mbti` for unintended public API changes.
