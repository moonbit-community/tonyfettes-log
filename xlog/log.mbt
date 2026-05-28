///|
/// A structured logger that emits entries through a `Handler`.
///
/// Logger calls are best-effort: errors raised by the handler are ignored.
struct Logger {
  mut handler : &Handler
  mut level : Level
  category : String?
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
  category? : String,
  config? : Config,
) -> Logger {
  let level = if config is Some(config) { config.level } else { level }
  Logger::{ handler, level, category, config }
}

///|
/// Create a child logger with an optional appended category segment.
///
/// Parent and child categories are joined with `.`. The child keeps the level
/// it is created with, so later `set_level` calls on the parent do not affect
/// existing children.
pub fn Logger::child(
  self : Logger,
  category? : String,
  level? : Level = self.level,
) -> Logger {
  let category = combine_category(self.category, category)
  Logger::{ ..self, category, level }
}

///|
fn combine_category(parent : String?, child : String?) -> String? {
  match (parent, child) {
    (None, None) => None
    (Some(category), None) | (None, Some(category)) => Some(category)
    (Some(parent), Some(child)) => Some("\{parent}.\{child}")
  }
}

///|
#callsite(autofill(loc))
fn Logger::log(
  self : Logger,
  level : Level,
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  if self.is_level_enabled(level, category?) {
    let category = combine_category(self.category, category)
    self.handler.handle(Entry(level~, category?, source=loc, message, fields?)) catch {
      _ => ()
    }
  }
}

///|
fn Logger::is_level_enabled(
  self : Logger,
  level : Level,
  category? : String,
) -> Bool {
  let category = combine_category(self.category, category)
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
/// Return this logger's category, if it has one.
pub fn Logger::category(self : Logger) -> String? {
  self.category
}

///|
/// Emit a `Fatal` entry.
#callsite(autofill(loc))
pub fn Logger::fatal(
  self : Logger,
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  self.log(Fatal, message, fields?, loc~)
}

///|
/// Emit an `Error` entry.
#callsite(autofill(loc))
pub fn Logger::error(
  self : Logger,
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  self.log(Error, message, fields?, loc~)
}

///|
/// Emit a `Warn` entry.
#callsite(autofill(loc))
pub fn Logger::warn(
  self : Logger,
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  self.log(Warn, message, fields?, loc~)
}

///|
/// Emit an `Info` entry.
#callsite(autofill(loc))
pub fn Logger::info(
  self : Logger,
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  self.log(Info, message, fields?, loc~)
}

///|
/// Emit a `Debug` entry.
#callsite(autofill(loc))
pub fn Logger::debug(
  self : Logger,
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  self.log(Debug, message, fields?, loc~)
}

///|
/// Emit a `Trace` entry.
#callsite(autofill(loc))
pub fn Logger::trace(
  self : Logger,
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  self.log(Trace, message, fields?, loc~)
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
/// Emit a `Fatal` entry with the global logger.
#callsite(autofill(loc))
pub fn fatal(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.log(Fatal, message, fields?, category?, loc~)
}

///|
/// Emit an `Error` entry with the global logger.
#callsite(autofill(loc))
pub fn error(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.log(Error, message, fields?, category?, loc~)
}

///|
/// Emit a `Warn` entry with the global logger.
#callsite(autofill(loc))
pub fn warn(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.log(Warn, message, fields?, category?, loc~)
}

///|
/// Emit an `Info` entry with the global logger.
#callsite(autofill(loc))
pub fn info(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.log(Info, message, fields?, category?, loc~)
}

///|
/// Emit a `Debug` entry with the global logger.
#callsite(autofill(loc))
pub fn debug(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.log(Debug, message, fields?, category?, loc~)
}

///|
/// Emit a `Trace` entry with the global logger.
#callsite(autofill(loc))
pub fn trace(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global_logger.log(Trace, message, fields?, category?, loc~)
}
