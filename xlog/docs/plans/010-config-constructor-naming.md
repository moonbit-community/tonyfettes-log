# Config constructor naming checkpoint

## Goal

Rename `Config::new` to the type-named constructor `Config::Config` so it
matches the rest of the xlog constructor surface (`Logger::Logger`,
`Stdout::Stdout`, `File::File`).

## Accepted design

- Replace `pub fn Config::new(level? : Level = Info)` with
  `pub fn Config::Config(level? : Level = Info)`.
- Update internal and external package call sites from `Config::new(...)` to
  `Config(...)` / `@xlog.Config(...)`.
- Do not keep a `Config::new` alias.
- Include the currently-uncommitted cleanup where top-level helpers dispatch
  directly through the package-private `global_logger`.

## Target files and surfaces

- `xlog/config.mbt`
- `xlog/log.mbt`
- `xlog/log_test.mbt`
- `xlog/log_wbtest.mbt`
- `xlog/examples/lorem/main.mbt`
- `xlog/README.md`
- `xlog/pkg.generated.mbti`
- `xlog/docs/plan.md`

## API and interface diff

- Remove:
  - `pub fn Config::new(level? : Level) -> Self`
- Add:
  - `pub struct Config { private fields }`
  - `pub fn Config::Config(level? : Level) -> Self`
- Generated interface changes `Config` from opaque `type Config` to a public
  struct with private fields, matching the other type-named constructors in
  `xlog`.

## Open questions

- None. The old name is intentionally removed.

## Next implementation step

Apply the rename, update documentation, regenerate the interface, run
validation, and commit.

## Validation plan

Run from `xlog/`:

```sh
moon fmt .
moon check .
moon test .
moon info .
```

