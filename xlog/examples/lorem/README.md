# Lorem example

Run from the `xlog` module root:

```sh
moon run examples/lorem
MOON_XLOG=debug moon run examples/lorem
MOON_XLOG='warn,lorem.db=trace,lorem.worker=debug' moon run examples/lorem
```

`MOON_XLOG` accepts a default level, plus comma-separated category overrides.
The example uses `lorem`, `lorem.db`, `lorem.worker`, and `lorem.ui`.
