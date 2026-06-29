# Handler naming checkpoint

## Goal

Rename the root `xlog` logging destination abstraction from `Writer` to
`Handler` so the naming matches the sibling `slog` and `alog` logger
experiments.

## Accepted design

- Rename `pub(open) trait Writer` to `pub(open) trait Handler`.
- Rename the trait method from `write(Self, Entry)` to `handle(Self, Entry)`,
  matching `slog` and `alog`.
- Update `Logger` internals from `writer` to `handler`.
- Update `Logger::Logger` generic bound from `[W : Writer]` to `[H : Handler]`.
- Update `Stdout`, `File`, and `Multi` to implement `Handler`.
- Keep `Multi` named `Multi`; do not rename it to `MultiHandler` in this
  change.

## Target files and surfaces

- `xlog/writer.mbt`
- `xlog/log.mbt`
- `xlog/log_test.mbt`
- `xlog/log_wbtest.mbt`
- `xlog/pkg.generated.mbti`
- `xlog/docs/plan.md`

## API and interface diff

- Remove `pub(open) trait Writer`.
- Add `pub(open) trait Handler { fn handle(Self, Entry) -> Unit }`.
- `Logger::Logger` generated signature changes from `[W : Writer]` to
  `[H : Handler]`.
- `File`, `Stdout`, and `Multi` generated impls change from `Writer` to
  `Handler`.

## Open questions

- None. The scope is limited to the `xlog` naming surface.

## Next implementation step

Apply the rename in `xlog`, update tests, regenerate `pkg.generated.mbti`, and
run scoped validation.

## Validation plan

Run from `xlog/`:

```sh
moon fmt .
moon check .
moon test .
moon info .
```

