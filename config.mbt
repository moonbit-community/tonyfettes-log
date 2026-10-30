///|
/// Logging configuration with a root level and category-specific overrides.
///
/// Category overrides are hierarchical: `app.db.query` falls back to `app.db`,
/// then `app`, then the logger's root level.
struct Config {
  mut level : Level
  levels : Map[String, Level]
}

///|
/// Create a configuration with the given root level.
pub fn Config::Config(level~ : Level = Info) -> Config {
  Config::{ level, levels: Map([]), }
}

///|
/// Errors raised when parsing or updating logger configuration.
pub(all) suberror ConfigError {
  /// The category name is empty or contains invalid dot placement.
  InvalidCategory(String)
  /// The configuration string contains an empty or malformed directive.
  InvalidDirective(String)
  /// The level name is not one of the supported `Level` values.
  InvalidLevel(String)
}

///|
/// Read configuration from an environment variable.
///
/// `env` defaults to `MOON_XLOG`. The value is a comma-separated list of
/// directives: either a root level such as `debug`, or a category override such
/// as `app.db=trace`.
pub fn Config::from_env(
  env~ : String = "MOON_XLOG",
  level~ : Level = Info,
) -> Config raise ConfigError {
  let config = Config(level~)
  guard @env.get_env_var(env) is Some(spec) else { config }
  config.parse(spec)
  config
}

///|
/// Set a level override for a category.
///
/// Category names must be non-empty dot-separated segments, with no leading
/// dot, trailing dot, or empty segment.
pub fn Config::set_category_level(
  self : Config,
  category : String,
  level : Level,
) -> Unit raise ConfigError {
  guard is_valid_category(category) else {
    raise ConfigError::InvalidCategory(category)
  }
  self.levels[category] = level
}

///|
fn Config::parse(self : Config, spec : String) -> Unit raise ConfigError {
  if spec.is_blank() {
    return
  }
  for raw in spec.split(",") {
    let directive = raw.trim()
    guard !directive.is_blank() else {
      raise ConfigError::InvalidDirective(raw.to_owned())
    }
    match directive.split_once("=") {
      Some((category, level)) => {
        let category = category.trim().to_owned()
        let level = level.trim()
        let level = parse_level(level)
        self.set_category_level(category, level)
      }
      None => self.level = parse_level(directive)
    }
  }
}

///|
fn parse_level(level : StringView) -> Level raise ConfigError {
  match level {
    ['F' | 'f', 'A' | 'a', 'T' | 't', 'A' | 'a', 'L' | 'l'] => Fatal
    ['E' | 'e', 'R' | 'r', 'R' | 'r', 'O' | 'o', 'R' | 'r'] => Error
    ['W' | 'w', 'A' | 'a', 'R' | 'r', 'N' | 'n'] => Warn
    ['I' | 'i', 'N' | 'n', 'F' | 'f', 'O' | 'o'] => Info
    ['D' | 'd', 'E' | 'e', 'B' | 'b', 'U' | 'u', 'G' | 'g'] => Debug
    ['T' | 't', 'R' | 'r', 'A' | 'a', 'C' | 'c', 'E' | 'e'] => Trace
    _ => raise ConfigError::InvalidLevel(level.to_owned())
  }
}

///|
fn is_valid_category(category : String) -> Bool {
  !category.is_empty() &&
  !category.has_prefix(".") &&
  !category.has_suffix(".") &&
  !category.contains("..")
}

///|
fn Config::get_category_level(self : Config, category : String) -> Level? {
  if self.levels.get(category) is Some(level) {
    return Some(level)
  }
  guard category.rev_split_once(".") is Some((parent, _)) else { None }
  self.get_category_level(parent.to_owned())
}
