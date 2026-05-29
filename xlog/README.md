# xlog

`tonyfettes/xlog` is a native-only structured logger with top-level helpers,
logger instances, categories, structured fields, stdout/file/multi outputs, and
`MOON_XLOG` filtering.

Logger calls are best-effort: output errors are ignored by `Logger`, while
handlers can still report errors when called directly or wrapped.

## Quick Start

Use top-level helpers when passing a logger around would be noisy:

```moonbit
if @xlog.info(category="app") is Some(event) {
  event.write_object_begin()
  event.write_object_field("message", "server started")
  event.write_object_field("port", 8080)
  event.write_object_end()
}
```

Use a `Logger` when you want a specific output:

```moonbit
let logger = @xlog.Logger(@xlog.Stdout())

if logger.debug(category="app.db") is Some(event) {
  event.write_object_begin()
  event.write_object_field("message", "query plan")
  event.write_object_end()
}
```

This API is shaped for a future conditional streaming form where a disabled
event skips evaluating structured fields.

## Levels And Categories

The default level is `Info`. Level order, from least to most verbose:

```text
Fatal Error Warn Info Debug Trace
```

A record is emitted when its level is less than or equal to the effective level.
Category overrides are hierarchical, so `app.db.query` falls back to `app.db`,
then `app`, then the logger's level.

Logger methods and top-level helpers return `None` when their level/category is
disabled, or `Some(event)` when fields should be written:

```moonbit
let logger = @xlog.Logger(@xlog.Stdout())

if logger.info(category="app") is Some(event) {
  event.write_object_begin()
  event.write_object_field("message", "server started")
  event.write_object_end()
}
```

Create separate logger instances when components need independent levels while
sharing the same output handler.

All fields written through an event are user fields. A field named `"message"`
is stored under `fields` like any other field; it is not promoted to top-level
metadata.

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

let logger = @xlog.Logger(@xlog.Stdout(), config~)
if logger.debug(category="app.db") is Some(event) {
  event.write_object_begin()
  event.write_object_field("message", "query plan")
  event.write_object_end()
}
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
@xlog.global().set_handler(file)
if @xlog.info(category="app") is Some(event) {
  event.write_object_begin()
  event.write_object_field("message", "written to file")
  event.write_object_end()
}
```

`File` is native-only and uses a small ISO C `FILE *` stub. The native handle
closes automatically when the handler is no longer reachable; call `close()`
only after removing it from long-lived loggers. It does not provide
multi-process atomic logging guarantees.

`Multi` fans out to several handlers:

```moonbit
let file = @xlog.File("_build/app.log")
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
if @xlog.info(category="app") is Some(event) {
  event.write_object_begin()
  event.write_object_field("message", "top-level record")
  event.write_object_end()
}
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
