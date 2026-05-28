# Global root logger naming checkpoint

## Goal

Rename the package-level root logger accessor from `default()` to `global()` so
the API name matches its actual semantics: a process-wide mutable root logger
used by top-level logging helpers.

## Accepted design

- Replace public `@xlog.default() -> Logger` with `@xlog.global() -> Logger`.
- Do not keep a `default()` alias; this is still an experiment and the old name
  is misleading.
- Update top-level helper implementations to dispatch through `global()`.
- Update tests and documentation from `default().set_*` to `global().set_*`.
- Rewrite `xlog/README.md` into a concise usage-oriented README while updating
  the naming.

## Target files and surfaces

- `xlog/log.mbt`
- `xlog/log_test.mbt`
- `xlog/log_wbtest.mbt`
- `xlog/pkg.generated.mbti`
- `xlog/README.md`
- `README.md`
- `xlog/docs/plan.md`

## API and interface diff

- Remove:
  - `pub fn default() -> Logger`
- Add:
  - `pub fn global() -> Logger`

## Open questions

- None. The rename is intentional and no compatibility alias will be kept.

## Next implementation step

Rename code and tests, regenerate `pkg.generated.mbti`, compact the README, run
validation, and commit.

## Validation plan

Run from `xlog/`:

```sh
moon fmt .
moon check .
moon test .
moon info .
```

