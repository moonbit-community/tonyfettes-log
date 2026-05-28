# Eager default logger checkpoint

## Goal

Replace the lazy optional default logger cell with a single eager root
`Logger`, matching the current API model where callers configure the root logger
through setters instead of replacing it wholesale.

## Accepted design

- Change `default_logger` from `Ref[Logger?]` to a direct package-level
  `Logger`.
- Keep `default() -> Logger`; it simply returns the global root logger.
- Read `MOON_XLOG` during package initialization through `default_config()`
  instead of on first `default()` call.
- Move the internal `self_log` storage before eager default initialization so
  invalid `MOON_XLOG` fallback can still report through the same internal
  self-log path without depending on cross-file initialization order.
- Update tests that previously reset `default_logger.val = None`; tests should
  configure and restore the root logger through `set_handler`, `set_config`, and
  `set_level`.
- Keep public API unchanged from the previous checkpoint.

## Target files and surfaces

- `xlog/log.mbt`
- `xlog/writer.mbt`
- `xlog/log_wbtest.mbt`
- `xlog/docs/plan.md`

## API and interface diff

- No intended public `.mbti` diff.
- `@xlog.default()` still returns `Logger`.

## Open questions

- None. Tests can still validate `default_config()` behavior directly, but they
  no longer force the already-initialized default root logger to reread
  environment variables.

## Next implementation step

Replace the lazy `Ref[Logger?]`, update white-box tests, run validation, confirm
`pkg.generated.mbti` is unchanged, and commit.

## Validation plan

Run from `xlog/`:

```sh
moon fmt .
moon check .
moon test .
moon info .
```

