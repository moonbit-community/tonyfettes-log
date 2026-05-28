# xlog

`tonyfettes/xlog` is a native-only structured logger with top-level helpers,
logger instances, categories, structured fields, stdout/file/multi outputs, and
`MOON_XLOG` filtering.

Logger calls are best-effort: output errors are ignored by `Logger`, while
handlers can still report errors when called directly or wrapped.

## Quick Start

Use top-level helpers when passing a logger around would be noisy:

```moonbit
@xlog.info("server started", category="app", fields={ "port": 8080 })
@xlog.debug("query plan", category="app.db")
```

Use a `Logger` when you want explicit category context or a specific output:

```moonbit
let logger = @xlog.Logger(@xlog.Stdout(), category="app")
let db = logger.child(category="db")

logger.info("server started")
db.debug("query plan")
```

## Levels And Categories

The default level is `Info`. Level order, from least to most verbose:

```text
Fatal Error Warn Info Debug Trace
```

A record is emitted when its level is less than or equal to the effective level.
Category overrides are hierarchical, so `app.db.query` falls back to `app.db`,
then `app`, then the logger's level.

Child loggers append category segments:

```moonbit
let app = @xlog.Logger(@xlog.Stdout(), category="app")
let db = app.child(category="db") // app.db
```

Logger methods do not take per-call categories. Use `child(category=...)` for
logger instances, and `category="..."` for top-level helpers.

## Configuration

`Config::from_env()` reads `MOON_XLOG` by default:

```sh
MOON_XLOG=debug
MOON_XLOG='warn,app.db=debug,app.db.query=trace'
```

You can also build config directly:

```moonbit
let config = @xlog.Config(level=@xlog.Warn)
config.set_category_level("app.db", @xlog.Debug)

let logger = @xlog.Logger(@xlog.Stdout(), category="app", config~)
```

Invalid levels, invalid directives, and invalid categories raise `ConfigError`.
The package global logger catches invalid `MOON_XLOG` and falls back to `Info`.

## Outputs

`Stdout` defaults to text output. Use `Jsonl` for one JSON object per line:

```moonbit
@xlog.global().set_handler(@xlog.Stdout())
@xlog.global().set_handler(@xlog.Stdout(format=@xlog.Jsonl))
```

`File` opens an append-mode file and defaults to `Jsonl`:

```moonbit
let file = @xlog.File("_build/app.log")
defer file.close()

@xlog.global().set_handler(file)
@xlog.info("written to file", category="app")
```

`File` is native-only, uses a small ISO C `FILE *` stub, requires explicit
`close()`, and does not provide multi-process atomic logging guarantees.

`Multi` fans out to several handlers:

```moonbit
let file = @xlog.File("_build/app.log")
defer file.close()

let handlers : Array[&@xlog.Handler] = [@xlog.Stdout(), file]
@xlog.global().set_handler(@xlog.Multi(handlers))
```

`Multi` attempts every child handler. Direct `Multi.handle(entry)` calls can
raise `MultiError(Array[Error])`; ordinary logger calls swallow that error.

## Global Logger

Top-level helpers use `@xlog.global()`, a process-wide root logger:

```moonbit
let config = @xlog.Config::from_env() catch { _ => @xlog.Config() }

@xlog.global().set_config(config)
@xlog.global().set_level(@xlog.Debug)
@xlog.info("top-level record", category="app")
```

`global()` is a root logger, not a replaceable default logger. Configure it with
`set_handler`, `set_config`, and `set_level`.

## Example

The `examples/lorem` package demonstrates category filtering:

```sh
moon run examples/lorem
MOON_XLOG=debug moon run examples/lorem
MOON_XLOG='warn,lorem.db=trace,lorem.worker=debug,lorem.parser.lexer=trace' moon run examples/lorem
```
