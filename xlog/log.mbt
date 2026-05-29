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
/// Emit a log entry at `level` with `fields` if the level is enabled.
#callsite(autofill(loc))
pub fn Logger::event(
  self : Logger,
  level : Level,
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  if self.is_level_enabled(level, category?) {
    let entry = Entry(level, fields, category?, source=loc)
    self.handler.handle(entry) catch {
      _ => ()
    }
  }
}

///|
/// Emit a `Fatal` entry with `fields` if the level is enabled.
#callsite(autofill(loc))
pub fn Logger::fatal(
  self : Logger,
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  self.event(Fatal, fields, category?, loc~)
}

///|
/// Emit an `Error` entry with `fields` if the level is enabled.
#callsite(autofill(loc))
pub fn Logger::error(
  self : Logger,
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  self.event(Error, fields, category?, loc~)
}

///|
/// Emit a `Warn` entry with `fields` if the level is enabled.
#callsite(autofill(loc))
pub fn Logger::warn(
  self : Logger,
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  self.event(Warn, fields, category?, loc~)
}

///|
/// Emit an `Info` entry with `fields` if the level is enabled.
#callsite(autofill(loc))
pub fn Logger::info(
  self : Logger,
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  self.event(Info, fields, category?, loc~)
}

///|
/// Emit a `Debug` entry with `fields` if the level is enabled.
#callsite(autofill(loc))
pub fn Logger::debug(
  self : Logger,
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  self.event(Debug, fields, category?, loc~)
}

///|
/// Emit a `Trace` entry with `fields` if the level is enabled.
#callsite(autofill(loc))
pub fn Logger::trace(
  self : Logger,
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  self.event(Trace, fields, category?, loc~)
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
/// Emit a log entry at `level` with `fields` through the global logger.
#callsite(autofill(loc))
pub fn event(
  level : Level,
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.event(level, fields, category?, loc~)
}

///|
/// Emit a `Fatal` entry with `fields` through the global logger.
#callsite(autofill(loc))
pub fn fatal(
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.fatal(fields, category?, loc~)
}

///|
/// Emit an `Error` entry with `fields` through the global logger.
#callsite(autofill(loc))
pub fn error(
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.error(fields, category?, loc~)
}

///|
/// Emit a `Warn` entry with `fields` through the global logger.
#callsite(autofill(loc))
pub fn warn(
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.warn(fields, category?, loc~)
}

///|
/// Emit an `Info` entry with `fields` through the global logger.
#callsite(autofill(loc))
pub fn info(
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.info(fields, category?, loc~)
}

///|
/// Emit a `Debug` entry with `fields` through the global logger.
#callsite(autofill(loc))
pub fn debug(
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.debug(fields, category?, loc~)
}

///|
/// Emit a `Trace` entry with `fields` through the global logger.
#callsite(autofill(loc))
pub fn trace(
  fields : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.trace(fields, category?, loc~)
}
