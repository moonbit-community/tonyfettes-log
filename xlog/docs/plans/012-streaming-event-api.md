# Streaming event API checkpoint

## Goal

Change `xlog` from eager `message, fields?` logging calls to an event-guard API
that can be the left-hand side of the proposed conditional streaming syntax in
`syntax.md`.

## Accepted design

- Make this a breaking API change; do not keep the old eager helpers.
- Level-specific top-level helpers and `Logger` methods return `Event?` instead
  of immediately writing:
  - `@xlog.info(category="app") -> Event?`
  - `logger.info(category="app") -> Event?`
- Add dynamic level entry points:
  - `@xlog.event(Level, category? : String, loc~ : SourceLoc) -> Event?`
  - `Logger::event(Self, Level, category? : String, loc~ : SourceLoc) -> Event?`
- `Event` is an opaque public type. It exposes the future structured object
  streaming protocol:
  - `Event::write_object_begin(Self) -> Unit`
  - `Event::write_object_field[T : ToJson](Self, String, T) -> Unit`
  - `Event::write_object_end(Self) -> Unit`
- `write_object_end` finalizes the event by constructing the existing `Entry`
  shape and passing it to the logger handler. Handler errors remain swallowed
  for ordinary logger-created events.
- Treat a structured field named `"message"` specially: it becomes
  `Entry.message`; other fields go into `Entry.fields`.
- Until conditional structured object syntax exists, tests and examples use the
  equivalent explicit expansion:

  ```moonbit
  if logger.info(category="app") is Some(event) {
    event.write_object_begin()
    event.write_object_field("message", "server started")
    event.write_object_field("port", 8080)
    event.write_object_end()
  }
  ```

## Target files and surfaces

- `xlog/log.mbt`
- `xlog/event.mbt`
- `xlog/entry.mbt`
- `xlog/log_test.mbt`
- `xlog/log_wbtest.mbt`
- `xlog/examples/lorem/main.mbt`
- `xlog/README.md`
- `xlog/pkg.generated.mbti`

## API and interface diff

Remove:

- `fatal/error/warn/info/debug/trace(String, fields?, category?, loc~) -> Unit`
- `Logger::fatal/error/warn/info/debug/trace(Self, String, fields?, category?, loc~) -> Unit`

Add:

- `pub struct Event { private fields }`
- `pub fn Event::write_object_begin(Self) -> Unit`
- `pub fn[T : ToJson] Event::write_object_field(Self, String, T) -> Unit`
- `pub fn Event::write_object_end(Self) -> Unit`
- `pub fn event(Level, category? : String, loc~ : SourceLoc) -> Event?`
- `pub fn Logger::event(Self, Level, category? : String, loc~ : SourceLoc) -> Event?`
- `fatal/error/warn/info/debug/trace(category?, loc~) -> Event?`
- `Logger::fatal/error/warn/info/debug/trace(Self, category?, loc~) -> Event?`

## Open questions

- None. Old eager logging APIs are intentionally removed.

## Next implementation step

Implement `Event`, replace eager helper signatures, update tests/examples/docs,
regenerate the interface, validate, and commit.

## Validation plan

Run from `xlog/`:

```sh
moon fmt .
moon check .
moon test .
moon info .
```
