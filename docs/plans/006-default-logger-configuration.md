# Default logger configuration checkpoint

## Goal

Tighten the `xlog` logging API so generic dispatch helpers stay internal while
the package still lets callers configure the process-wide top-level logging
runtime without installing an arbitrary categorized logger.

## Accepted design

- Remove public `@xlog.log`.
- Make `Logger::log` private/internal.
- Remove public `@xlog.set_default(Logger)`.
- Keep `@xlog.default() -> Logger`, but treat it as the root logger used by
  top-level helpers.
- Add `Logger::set_handler[H : Handler](handler : H)`.
- Add `Logger::set_config(config : Config)`.
- Keep `Logger::set_level(level : Level)`.
- Keep top-level severity helpers accepting `category? : String`.
- Do not add per-call `category?` to `Logger::info/debug/...`; callers with a
  `Logger` should use `child(category=...)` for category context.
- Update top-level category dispatch to use an internal `Logger::log` path
  directly instead of constructing a temporary child logger.

## Target files and surfaces

- `xlog/log.mbt`
- `xlog/log_test.mbt`
- `xlog/pkg.generated.mbti`
- `README.md`
- `xlog/docs/plan.md`

## API and interface diff

- Remove:
  - `pub fn log(Level, String, fields?, category?, loc~)`
  - `pub fn set_default(Logger) -> Unit`
  - `pub fn Logger::log(Self, Level, String, fields?, loc~)`
- Add:
  - `pub fn[H : Handler] Logger::set_handler(Self, H) -> Unit`
  - `pub fn Logger::set_config(Self, Config) -> Unit`
- Existing severity-specific top-level helpers remain public:
  `fatal/error/warn/info/debug/trace(String, fields?, category?, loc~)`.

## Open questions

- None. Compatibility with direct `@xlog.log` callers is intentionally dropped.

## Next implementation step

Update `Logger` mutability and setter methods, hide generic log helpers, update
tests to configure `@xlog.default()` through setters, regenerate the interface,
and commit the result.

## Validation plan

Run from `xlog/`:

```sh
moon fmt .
moon check .
moon test .
moon info .
```

