# Top-level category checkpoint

## Goal

Add category support to the top-level `@xlog.log/info/debug/warn/error/fatal`
helpers so callers can use the process default logger without manually creating
a child logger for one-off categorized records.

## Accepted design

- Add an optional `category? : String` parameter to top-level `log` and the
  level-specific helpers.
- When `category` is omitted, keep the existing behavior and call the default
  logger directly.
- When `category` is present, use `default().child(category~)` for the emitted
  record so existing `Entry.category` output and `Config` category filtering are
  reused.
- Keep `Logger::log` and `Logger::info/debug/...` unchanged.
- Do not add category validation on top-level helpers in this change; category
  strings continue to be interpreted by the existing logger/config behavior.

## Target files and surfaces

- `xlog/log.mbt`
- `xlog/log_test.mbt`
- `xlog/pkg.generated.mbti`
- `xlog/docs/plan.md`

## API and interface diff

- Top-level functions gain `category? : String`:
  - `log(Level, String, fields?, category?, loc~)`
  - `fatal/error/warn/info/debug/trace(String, fields?, category?, loc~)`
- Existing calls without `category` remain source-compatible.
- Generated `pkg.generated.mbti` is expected to reflect only those top-level
  signature additions.

## Open questions

- None. Streaming `<+` support remains out of scope for this change.

## Next implementation step

Update the top-level forwarding functions, add a black-box test through
`set_default`, regenerate the interface, and commit the result.

## Validation plan

Run from `xlog/`:

```sh
moon fmt .
moon check .
moon test .
moon info .
```

