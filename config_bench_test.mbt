///|
fn parse_level_chain_copy(level : StringView) -> @xlog.Level? {
  if level.equal_ignore_ascii_case("fatal") {
    Some(@xlog.Fatal)
  } else if level.equal_ignore_ascii_case("error") {
    Some(@xlog.Error)
  } else if level.equal_ignore_ascii_case("warn") {
    Some(@xlog.Warn)
  } else if level.equal_ignore_ascii_case("info") {
    Some(@xlog.Info)
  } else if level.equal_ignore_ascii_case("debug") {
    Some(@xlog.Debug)
  } else if level.equal_ignore_ascii_case("trace") {
    Some(@xlog.Trace)
  } else {
    None
  }
}

///|
fn parse_level_match_copy(level : StringView) -> @xlog.Level? {
  match level {
    ['F' | 'f', 'A' | 'a', 'T' | 't', 'A' | 'a', 'L' | 'l'] => Some(@xlog.Fatal)
    ['E' | 'e', 'R' | 'r', 'R' | 'r', 'O' | 'o', 'R' | 'r'] => Some(@xlog.Error)
    ['W' | 'w', 'A' | 'a', 'R' | 'r', 'N' | 'n'] => Some(@xlog.Warn)
    ['I' | 'i', 'N' | 'n', 'F' | 'f', 'O' | 'o'] => Some(@xlog.Info)
    ['D' | 'd', 'E' | 'e', 'B' | 'b', 'U' | 'u', 'G' | 'g'] => Some(@xlog.Debug)
    ['T' | 't', 'R' | 'r', 'A' | 'a', 'C' | 'c', 'E' | 'e'] => Some(@xlog.Trace)
    _ => None
  }
}

///|
fn parse_level_lower_then_match(level : StringView) -> @xlog.Level? {
  match level.to_lower() {
    "fatal" => Some(@xlog.Fatal)
    "error" => Some(@xlog.Error)
    "warn" => Some(@xlog.Warn)
    "info" => Some(@xlog.Info)
    "debug" => Some(@xlog.Debug)
    "trace" => Some(@xlog.Trace)
    _ => None
  }
}

///|
test "bench parse level copies" (b : @bench.T) {
  let levels : Array[StringView] = [
    "fatal", "ERROR", "Warn", "info", "Debug", "TRACE", "Fatal", "error", "WARN",
    "Info", "debug", "trace",
  ]
  b.bench(name="equal_ignore_ascii_case", fn() {
    for level in levels {
      ignore(parse_level_chain_copy(level))
    }
  })
  b.bench(name="stringview_pattern", fn() {
    for level in levels {
      ignore(parse_level_match_copy(level))
    }
  })
  b.bench(name="lower_then_match", fn() {
    for level in levels {
      ignore(parse_level_lower_then_match(level))
    }
  })
}
