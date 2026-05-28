# MoonBit Logger Experiments

This repository collects three current attempts at a MoonBit logging package.
They share the same basic log vocabulary: levels, entries, structured fields,
source locations, category names, text output, and JSON-line output. The main
difference is the I/O model each implementation is exploring.

## Directory Map

| Directory | Package | Main idea |
| --- | --- | --- |
| `xlog/` | `tonyfettes/xlog` | Original synchronous logger built directly on `moonbitlang/x` file and stdout APIs. |
| `slog/` | `tonyfettes/slog` | Sync-backed logger that keeps the core logger/config model but writes through `tonyfettes/sync` writers. |
| `alog/` | `tonyfettes/alog` | Async-scoped logger that queues entries and writes them with `moonbitlang/async` I/O. |

The generated interfaces in each package (`pkg.generated.mbti`) are the best
quick reference for the public surface of each experiment.

## `xlog`: `moonbitlang/x` Baseline

`xlog` is the baseline implementation. It exposes a `Logger`, a `Handler` trait,
`Stdout`, `File`, `Multi`, `Format`, `Config`, and package-level default logger
functions such as `info` and `debug`. The package-level default root logger is
configured through `global().set_handler(...)`, `global().set_config(...)`, and
`global().set_level(...)`.

Strengths:

- Broadest compatibility with the first logger API shape.
- Includes file and stdout sinks as first-class public types.
- Supports `MOON_XLOG` parsing, default levels, and hierarchical category
  overrides.
- Useful as a regression baseline for behavior and tests.

Tradeoffs:

- The file writer is native-only and keeps an explicit append-mode file handle,
  so callers must close it explicitly.
- Output concerns and sink ownership are bundled into the logger package.
- It depends on `moonbitlang/x` for I/O.

## `slog`: Sync Writer Experiment

`slog` keeps the same core `Logger`, `Level`, `Entry`, and `Config` concepts,
but changes the output boundary from a package-owned `Writer` sink to `Handler`
implementations over `tonyfettes/sync/io.Writer`.

Its public output types are `TextHandler`, `JsonHandler`, and `MultiHandler`.
The default logger writes to `@sync/stdio.stdout`, while tests demonstrate file
logging by opening sync files and passing them to handlers.

Strengths:

- Better separation between logging and I/O ownership.
- Works with existing `tonyfettes/sync` writers instead of inventing logger
  owned file/stdout wrappers.
- Keeps the configuration and category filtering behavior from the baseline.
- Avoids the `xlog` file read-append-rewrite strategy when callers provide an
  append-mode sync file.

Tradeoffs:

- The public surface is not source-compatible with `xlog` sink construction:
  `File`, `Stdout`, `Format`, `Writer`, and `Multi` are replaced by handlers.
- Callers own file lifecycle and closing.
- Timestamps still use `moonbitlang/x/time`, so the package is not fully
  detached from `moonbitlang/x`.

## `alog`: Async Scoped Experiment

`alog` is a different shape. It provides `with_logger(handler, fn, ...)`, creates
an async queue, runs a background task that drains log entries, and gives the
callback a scoped `Logger`.

Handlers write to `moonbitlang/async/io.Writer`; `Mux` fans writes out to
multiple async writers. Unlike `xlog` and `slog`, `alog` does not currently
include `Config`, package-level default logging functions, or environment-based
filtering.

Strengths:

- Natural fit for async applications and async file/socket writers.
- Scoped lifecycle makes flushing explicit: accepted entries are drained before
  `with_logger` returns.
- Queueing separates log call sites from the actual write operation.
- `Mux` supports fan-out to multiple async writers.

Tradeoffs:

- It is not a drop-in replacement for the sync logger API.
- Filtering is simpler: only logger level and child level behavior are present.
- It depends on the current `moonbitlang/async` runtime model. The notes in
  `alog/docs/fork-async.md` call out broader runtime-thread work before treating
  this as a cross-thread logging foundation.
- The queue is unbounded, and enqueue failure is currently ignored at the call
  site.

## Rubric

Scores are `1` to `5`, where `5` is the strongest fit. The weighted total is
biased toward choosing a production-ready synchronous logger. If the goal is an
async-first logger, increase the weight of async lifecycle and backpressure.

| Criterion | Weight | `xlog` | `slog` | `alog` | Notes |
| --- | ---: | ---: | ---: | ---: | --- |
| Runtime model fit for sync logging | 15 | 4 | 5 | 2 | `slog` aligns with the sync package; `alog` is intentionally async-scoped. |
| Public API clarity and size | 15 | 3 | 4 | 3 | `slog` has a smaller sink surface; `xlog` is familiar but bundles more concepts. |
| Sink flexibility | 15 | 3 | 5 | 4 | `slog` accepts any sync writer; `alog` accepts async writers; `xlog` centers its own writers. |
| File/stdout write quality | 15 | 4 | 4 | 4 | `xlog` now uses a native append-mode file handler; `slog` and `alog` rely on writers supplied by callers. |
| Filtering and configuration | 10 | 5 | 5 | 2 | `xlog` and `slog` have env parsing and hierarchical category overrides. |
| Async lifecycle and backpressure | 10 | 1 | 2 | 4 | `alog` has scoped drain behavior, but still needs clearer queue/backpressure policy. |
| Test coverage for current behavior | 10 | 4 | 4 | 4 | All three have focused tests for core behavior; they exercise different I/O models. |
| Publishing risk and implementation complexity | 10 | 3 | 4 | 2 | `alog` carries more runtime-model risk; `slog` is the narrowest sync evolution. |
| **Weighted total** | **100** | **68** | **84** | **63** | Higher is better for the synchronous logger goal. |

## Decision Guide

- Use `xlog` as the behavior baseline and compatibility reference.
- Prefer `slog` as the main synchronous logger direction if the goal is a
  reusable package with cleaner sink ownership and better write primitives.
- Keep `alog` as the async experiment. It is promising for async applications,
  but it should not be judged by sync logger compatibility alone.

## Open Questions

- Should `slog` reintroduce convenience constructors such as `File` or `Stdout`,
  or should it keep file/stdout lifecycle fully outside the logger package?
- Should `slog` keep using `moonbitlang/x/time`, or should timestamp handling
  move to a dependency that matches the sync package direction?
- Should `alog` add config/env filtering, bounded queues, or explicit drop/error
  handling before it is considered a package candidate?
- Should `MOON_XLOG` and `MOON_SLOG` stay experiment-specific, or should the
  eventual package converge on one environment variable name?
