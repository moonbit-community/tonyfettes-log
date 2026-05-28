# xlog

`tonyfettes/xlog` is a small native-only structured logger experiment for
MoonBit. It provides synchronous logging to stdout and append-mode files, with
levels, categories, source locations, structured fields, text output, JSON-line
output, and environment-based filtering.

The package is intentionally best-effort: ordinary logging calls do not raise if
the output handler fails. Handlers can report errors when called directly or
when wrapped by another handler, following the same general direction as Go's
`log/slog`.

## Target

`xlog` supports the native backend only.

```moonbit
supported_targets = "native"
```

File output is implemented by `tonyfettes/xlog/internal/fs` with a tiny ISO C
`FILE *` append-mode stub. Files must be closed explicitly by the caller.

## Quick Start

```moonbit
///|
fn main {
  let logger = @xlog.Logger(@xlog.Stdout())
  logger.info("server started", fields={
    "addr": "127.0.0.1:8080",
    "workers": 4,
  })
}
```

By default, a logger starts at `Info`, so `Fatal`, `Error`, `Warn`, and `Info`
records are emitted, while `Debug` and `Trace` records are filtered out.

```moonbit
///|
fn main {
  let logger = @xlog.Logger(@xlog.Stdout(), level=@xlog.Debug)
  logger.debug("debug is visible")
  logger.trace("trace is still hidden")
}
```

## Levels

Levels are ordered from most severe to most verbose:

```text
Fatal < Error < Warn < Info < Debug < Trace
```

A record is emitted when its level is less than or equal to the effective logger
level. With the default `Info` level:

- emitted: `Fatal`, `Error`, `Warn`, `Info`
- filtered: `Debug`, `Trace`

## Output Formats

`Stdout` defaults to human-readable text:

```moonbit
let logger = @xlog.Logger(@xlog.Stdout())
logger.warn("using fallback config", fields={ "source": "default" })
```

`Stdout(format=@xlog.Jsonl)` emits one JSON object per line:

```moonbit
let logger = @xlog.Logger(@xlog.Stdout(format=@xlog.Jsonl))
logger.info("request completed", fields={
  "method": "GET",
  "status": 200,
})
```

`File` defaults to `Jsonl` because that is the safer format for appending log
records to a file:

```moonbit
let file = @xlog.File("_build/app.log")
defer file.close()

let logger = @xlog.Logger(file)
logger.error("write failed", fields={ "path": "/tmp/report.txt" })
```

Use `format=@xlog.Text` when a plain text file is preferred:

```moonbit
let file = @xlog.File("_build/app.log", format=@xlog.Text)
defer file.close()

let logger = @xlog.Logger(file)
logger.info("plain text line")
```

## Entries

Each emitted record is represented as an `Entry`:

```moonbit
pub struct Entry {
  level : Level
  category : String?
  timestamp : @time.ZonedDateTime
  source : SourceLoc?
  message : String
  fields : Map[String, Json]
}
```

The public logging functions use `#callsite(autofill(loc))`, so `source` points
at the callsite that invoked `info`, `warn`, `debug`, and the other severity
methods.

`fields` is a `Map[String, Json]`. String, integer, boolean, array, object, and
other JSON-compatible values can be passed through the usual MoonBit JSON
conversion path:

```moonbit
logger.info("job finished", fields={
  "job": "nightly-index",
  "attempt": 2,
  "cached": true,
})
```

## Categories

A `Logger` may have an optional category. Child loggers extend that category
with dot-separated names:

```moonbit
let app = @xlog.Logger(@xlog.Stdout(), category="app")
let db = app.child(category="db")
let query = db.child(category="query")

app.info("started")       // category: app
db.debug("connected")     // category: app.db
query.trace("selected")   // category: app.db.query
```

`Logger::info`, `Logger::debug`, and the other logger methods do not accept a
per-call category. If you already have a logger, use `child(category=...)` to
make category context explicit.

Top-level helpers are different: they are convenience functions for places
where passing a logger is inconvenient. They accept `category?`:

```moonbit
@xlog.info("migration started", category="db")
@xlog.debug("selected batch", category="db.query")
```

## Configuration

`Config` controls the default level and category-specific overrides:

```moonbit
let config = @xlog.Config::new(level=@xlog.Warn)
config.set_category_level("app.db", @xlog.Debug)
config.set_category_level("app.db.query", @xlog.Trace)

let logger = @xlog.Logger(@xlog.Stdout(), category="app", config~)
let db = logger.child(category="db")
let query = db.child(category="query")

logger.info("hidden")
logger.warn("visible")
db.debug("visible")
query.trace("visible")
```

Category overrides are hierarchical. If `app.db.query` has no override, `xlog`
checks `app.db`, then `app`, then the logger's default level.

Valid category names are non-empty and must not start with `.`, end with `.`, or
contain `..`.

## MOON_XLOG

`Config::from_env()` reads `MOON_XLOG` by default.

```moonbit
let config = @xlog.Config::from_env() catch { _ => @xlog.Config::new() }
let logger = @xlog.Logger(@xlog.Stdout(), category="app", config~)
```

The environment value is comma-separated:

```text
MOON_XLOG=debug
MOON_XLOG=warn,app.db=debug,app.db.query=trace
MOON_XLOG=error,lorem.cache=debug,lorem.export.markdown=trace
```

The first form sets the default level. The second form sets a default level and
then overrides specific categories.

Invalid levels, invalid categories, and malformed directives raise
`ConfigError` from `Config::from_env`. The package-level default logger catches
that error and falls back to `Info`.

## Package-Level Default Logger

`@xlog.default()` returns the process-wide root logger used by top-level helper
functions:

```moonbit
@xlog.info("hello")
@xlog.warn("using default logger", category="app.config")
```

Configure that root logger through setters:

```moonbit
let file = @xlog.File("_build/app.log")
defer file.close()

@xlog.default().set_handler(file)
@xlog.default().set_level(@xlog.Debug)
@xlog.default().set_config(@xlog.Config::from_env() catch { _ => @xlog.Config::new() })

@xlog.debug("debug record", category="app")
```

`default()` is always the root logger. It is not replaced wholesale with another
logger, which avoids accidentally installing a categorized logger as the global
default.

## Handlers

`Handler` is the output boundary:

```moonbit
pub(open) trait Handler {
  fn handle(Self, Entry) -> Unit raise
}
```

Built-in handlers:

- `Stdout(format?)`: writes to standard output.
- `File(path, format?)`: appends to a file and must be explicitly closed.
- `Multi(Array[&Handler])`: fans out to several handlers.

Ordinary logger calls are best-effort. If `handler.handle(entry)` raises,
`Logger` catches and ignores the error:

```moonbit
let file = @xlog.File("_build/app.log")
file.close()

let logger = @xlog.Logger(file)
logger.info("this does not raise")
```

Use a wrapper handler if you need to observe output errors. The wrapper can call
an inner handler, catch the error, record it somewhere else, and then re-raise
or swallow it. `Logger` will still keep ordinary logging calls non-raising.

## Multi

`Multi` attempts every child handler. It collects failures and raises
`MultiError(Array[Error])` after every handler has been attempted:

```moonbit
let stdout = @xlog.Stdout()
let file = @xlog.File("_build/app.log")
defer file.close()

let handlers : Array[&@xlog.Handler] = [stdout, file]
let logger = @xlog.Logger(@xlog.Multi(handlers))
logger.info("written to both handlers")
```

When `Multi` is used through `Logger`, its `MultiError` is swallowed like any
other handler error. When `Multi.handle(entry)` is called directly, callers can
catch and inspect `MultiError`.

## File Output

`File` opens paths in append-only mode and writes one formatted record per
handler call.

```moonbit
let file = @xlog.File("_build/events.jsonl")
defer file.close()

let logger = @xlog.Logger(file)
logger.info("event accepted", fields={ "id": 1001 })
```

Important details:

- The package is native-only.
- The C stub uses ISO C `FILE *` APIs.
- `File::close()` is explicit and does not raise.
- Writes after `close()` fail when the file handler is called directly.
- Logger methods swallow handler errors, including file write errors.
- There is no multi-process atomic logging guarantee.

## Error Types

`ConfigError` reports configuration parsing failures:

```moonbit
pub(all) suberror ConfigError {
  InvalidCategory(String)
  InvalidDirective(String)
  InvalidLevel(String)
}
```

`MultiError` reports handler fanout failures:

```moonbit
pub(all) suberror MultiError {
  MultiError(Array[Error])
}
```

The internal filesystem package also defines `IOError(String)` for native file
open, write, and flush failures. Public `File::File(path)` can raise that error
when opening fails.

## Example

The `examples/lorem` package demonstrates category filtering:

```sh
moon run examples/lorem
MOON_XLOG=debug moon run examples/lorem
MOON_XLOG='warn,lorem.db=trace,lorem.worker=debug,lorem.parser.lexer=trace' moon run examples/lorem
MOON_XLOG='error,lorem.cache=debug,lorem.export.markdown=trace,lorem.ui=debug' moon run examples/lorem
```

Run those commands from the `xlog` module root.

## Public API Summary

Common constructors and functions:

```moonbit
@xlog.Logger(handler, level?, category?, config?)
@xlog.Stdout(format?)
@xlog.File(path, format?)
@xlog.Multi(handlers)
@xlog.Config::new(level?)
@xlog.Config::from_env(env?, level?)
@xlog.default()
```

Logger methods:

```moonbit
logger.fatal(message, fields?)
logger.error(message, fields?)
logger.warn(message, fields?)
logger.info(message, fields?)
logger.debug(message, fields?)
logger.trace(message, fields?)

logger.child(category?, level?)
logger.set_handler(handler)
logger.set_config(config)
logger.set_level(level)
logger.category()
```

Top-level helpers:

```moonbit
@xlog.fatal(message, fields?, category?)
@xlog.error(message, fields?, category?)
@xlog.warn(message, fields?, category?)
@xlog.info(message, fields?, category?)
@xlog.debug(message, fields?, category?)
@xlog.trace(message, fields?, category?)
```
