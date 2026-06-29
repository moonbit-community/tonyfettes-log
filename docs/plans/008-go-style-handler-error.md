# Go-style handler error checkpoint

## Goal

Replace `xlog`'s ad hoc internal `self_log` write-failure reporting with a
Go `log/slog`-style handler error model: handlers may report output failures,
while ordinary logger calls remain best-effort and do not surface those errors
to application code.

## Accepted design

- Change `Handler::handle(Self, Entry)` to `Handler::handle(Self, Entry) raise`.
- Keep `Logger` severity methods non-raising; internal `Logger::log` catches and
  ignores handler errors.
- Change `File` handler to let `IOError` propagate from its `handle` method
  instead of catching and pushing to `self_log`.
- Remove the `self_log` storage entirely; invalid `MOON_XLOG` falls back to the
  default config without side-channel logging.
- Keep `Stdout` as a non-raising implementation of the raising handler trait.
- Make `Multi` attempt every child handler, collect all errors, and raise a
  `MultiError(Array[Error])` after all enabled children were attempted.
- Do not add an `ErrorHandler` trait in this change.

## Target files and surfaces

- `xlog/writer.mbt`
- `xlog/log.mbt`
- `xlog/log_wbtest.mbt`
- `xlog/pkg.generated.mbti`
- `xlog/docs/plan.md`

## API and interface diff

- `pub(open) trait Handler` changes from:
  - `fn handle(Self, Entry) -> Unit`
  to:
  - `fn handle(Self, Entry) -> Unit raise`
- Add:
  - `pub(all) suberror MultiError { MultiError(Array[Error]) }`
- Remove internal `self_log`; no public API is removed for this point because it
  was package-private.

## Open questions

- None. Handler error observation is intentionally left to wrapper handlers,
  matching the Go pattern.

## Next implementation step

Finish the existing partial handler-error changes, remove `self_log`, update
white-box tests for direct handler errors and logger swallowing behavior,
regenerate the interface, and commit.

## Validation plan

Run from `xlog/`:

```sh
moon fmt .
moon check .
moon test .
moon info .
```

