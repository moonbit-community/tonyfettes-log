# Lorem example

Run from the `xlog` module root:

```sh
moon run examples/lorem
MOON_XLOG=debug moon run examples/lorem
MOON_XLOG='warn,lorem.db=trace,lorem.worker=debug,lorem.parser.lexer=trace' moon run examples/lorem
MOON_XLOG='error,lorem.cache=debug,lorem.export.markdown=trace,lorem.ui=debug' moon run examples/lorem
```

`MOON_XLOG` accepts a default level, plus comma-separated category overrides.
The example uses `lorem`, `lorem.db`, `lorem.parser`, `lorem.parser.lexer`,
`lorem.worker`, `lorem.cache`, `lorem.net`, `lorem.export`,
`lorem.export.markdown`, and `lorem.ui`.
