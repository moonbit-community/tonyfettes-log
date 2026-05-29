///|
/// A structured logger that emits entries through a `Handler`.
///
/// Logger calls are best-effort: errors raised by the handler are ignored.
struct Logger {
  mut handler : &Handler
  mut level : Level
  mut config : Config?
}

///|
/// Log levels ordered from most severe to most verbose.
///
/// A record is emitted when its level is less than or equal to the effective
/// logger level.
pub(all) enum Level {
  /// A fatal failure.
  Fatal
  /// An error that should be investigated.
  Error
  /// A warning about a degraded or unexpected condition.
  Warn
  /// General operational information.
  Info
  /// Detailed diagnostic information.
  Debug
  /// Very verbose diagnostic information.
  Trace
} derive(Eq, Compare)

///|
pub impl Show for Level with fn to_string(self) -> String {
  match self {
    Fatal => "FATAL"
    Error => "ERROR"
    Warn => "WARN"
    Info => "INFO"
    Debug => "DEBUG"
    Trace => "TRACE"
  }
}

///|
pub impl Show for Level with fn output(self, logger) -> Unit {
  logger.write_string(self.to_string())
}

///|
/// Create a logger that writes to `handler`.
///
/// The default level is `Info`. When `config` is provided, its root level is
/// used as the logger level and category-specific overrides are consulted for
/// each entry.
pub fn[H : Handler] Logger::Logger(
  handler : H,
  level? : Level = Info,
  config? : Config,
) -> Logger {
  let level = if config is Some(config) { config.level } else { level }
  Logger::{ handler, level, config }
}

///|
fn Logger::is_level_enabled(
  self : Logger,
  level : Level,
  category? : String,
) -> Bool {
  self.is_level_enabled_for_category(level, category)
}

///|
fn Logger::is_level_enabled_for_category(
  self : Logger,
  level : Level,
  category : String?,
) -> Bool {
  let effective = if self.config is Some(config) &&
    category is Some(category) &&
    config.get_category_level(category) is Some(level) {
    level
  } else {
    self.level
  }
  level <= effective
}

///|
/// Replace the handler used by this logger.
pub fn[H : Handler] Logger::set_handler(self : Logger, handler : H) -> Unit {
  self.handler = handler
}

///|
/// Install a configuration object and reset the logger's root level from it.
pub fn Logger::set_config(self : Logger, config : Config) -> Unit {
  self.config = Some(config)
  self.level = config.level
}

///|
/// Set the logger's root level.
///
/// Category-specific overrides from an installed `Config` still take
/// precedence for matching categories.
pub fn Logger::set_level(self : Logger, level : Level) -> Unit {
  self.level = level
}

///|
/// Start a log event at `level` if it is enabled.
#callsite(autofill(loc))
pub fn Logger::event(
  self : Logger,
  level : Level,
  category? : String,
  loc~ : SourceLoc,
) -> Event? {
  if self.is_level_enabled(level, category?) {
    Some(Event::{
      logger: self,
      level,
      category,
      source: Some(loc),
      fields: {},
      finished: false,
    })
  } else {
    None
  }
}

///|
/// Start a `Fatal` event if it is enabled.
#callsite(autofill(loc))
pub fn Logger::fatal(
  self : Logger,
  category? : String,
  loc~ : SourceLoc,
) -> Event? {
  self.event(Fatal, category?, loc~)
}

///|
/// Start an `Error` event if it is enabled.
#callsite(autofill(loc))
pub fn Logger::error(
  self : Logger,
  category? : String,
  loc~ : SourceLoc,
) -> Event? {
  self.event(Error, category?, loc~)
}

///|
/// Start a `Warn` event if it is enabled.
#callsite(autofill(loc))
pub fn Logger::warn(
  self : Logger,
  category? : String,
  loc~ : SourceLoc,
) -> Event? {
  self.event(Warn, category?, loc~)
}

///|
/// Start an `Info` event if it is enabled.
#callsite(autofill(loc))
pub fn Logger::info(
  self : Logger,
  category? : String,
  loc~ : SourceLoc,
) -> Event? {
  self.event(Info, category?, loc~)
}

///|
/// Start a `Debug` event if it is enabled.
#callsite(autofill(loc))
pub fn Logger::debug(
  self : Logger,
  category? : String,
  loc~ : SourceLoc,
) -> Event? {
  self.event(Debug, category?, loc~)
}

///|
/// Start a `Trace` event if it is enabled.
#callsite(autofill(loc))
pub fn Logger::trace(
  self : Logger,
  category? : String,
  loc~ : SourceLoc,
) -> Event? {
  self.event(Trace, category?, loc~)
}

///|
fn default_config() -> Config {
  Config::from_env(env="MOON_XLOG") catch {
    _ => Config()
  }
}

///|
let global_logger : Logger = Logger(Stdout(), config=default_config())

///|
/// Return the process-wide root logger used by top-level logging helpers.
///
/// The returned logger can be configured with `set_handler`, `set_config`, and
/// `set_level`.
pub fn global() -> Logger {
  global_logger
}

///|
/// Start a log event at `level` with the global logger if it is enabled.
#callsite(autofill(loc))
pub fn event(level : Level, category? : String, loc~ : SourceLoc) -> Event? {
  global_logger.event(level, category?, loc~)
}

///|
/// Start a `Fatal` event with the global logger if it is enabled.
#callsite(autofill(loc))
pub fn fatal(category? : String, loc~ : SourceLoc) -> Event? {
  global_logger.fatal(category?, loc~)
}

///|
/// Start an `Error` event with the global logger if it is enabled.
#callsite(autofill(loc))
pub fn error(category? : String, loc~ : SourceLoc) -> Event? {
  global_logger.error(category?, loc~)
}

///|
/// Start a `Warn` event with the global logger if it is enabled.
#callsite(autofill(loc))
pub fn warn(category? : String, loc~ : SourceLoc) -> Event? {
  global_logger.warn(category?, loc~)
}

///|
/// Start an `Info` event with the global logger if it is enabled.
#callsite(autofill(loc))
pub fn info(category? : String, loc~ : SourceLoc) -> Event? {
  global_logger.info(category?, loc~)
}

///|
/// Start a `Debug` event with the global logger if it is enabled.
#callsite(autofill(loc))
pub fn debug(category? : String, loc~ : SourceLoc) -> Event? {
  global_logger.debug(category?, loc~)
}

///|
/// Start a `Trace` event with the global logger if it is enabled.
#callsite(autofill(loc))
pub fn trace(category? : String, loc~ : SourceLoc) -> Event? {
  global_logger.trace(category?, loc~)
}
