# MOON_XLOG environment checkpoint

## Goal

Make `xlog` use `MOON_XLOG` as its default environment variable, so the
experiment-specific logger name matches the module name and does not conflict
with `slog`.

## Accepted design

- Change `Config::from_env()` default `env` from `MOON_SLOG` to `MOON_XLOG`.
- Change the package default logger to read `MOON_XLOG`.
- Update self-log parse failure metadata/messages to mention `MOON_XLOG`.
- Update tests and the `examples/lorem` README to use `MOON_XLOG`.
- Do not add a `MOON_SLOG` fallback in `xlog`.

## Target files and surfaces

- `xlog/config.mbt`
- `xlog/log.mbt`
- `xlog/log_test.mbt`
- `xlog/log_wbtest.mbt`
- `xlog/examples/lorem/README.md`
- `xlog/docs/plan.md`

## API and interface diff

- `Config::from_env(env? : String, ...)` keeps the same signature.
- Behavior changes only when `env` is omitted: it now reads `MOON_XLOG`.
- `Config::from_env(env="...")` remains unchanged for custom environment
  variable names.

## Validation plan

Run from `xlog/`:

```sh
moon fmt .
moon check .
moon test .
moon run examples/lorem
MOON_XLOG=debug moon run examples/lorem
```

