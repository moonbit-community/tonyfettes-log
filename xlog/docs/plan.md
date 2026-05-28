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
