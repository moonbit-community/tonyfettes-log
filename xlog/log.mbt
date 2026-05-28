///|
struct Logger {
  mut handler : &Handler
  mut level : Level
  category : String?
  mut config : Config?
}

///|
pub(all) enum Level {
  Fatal
  Error
  Warn
  Info
  Debug
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
pub fn[H : Handler] Logger::Logger(
  handler : H,
  level? : Level = Info,
  category? : String,
  config? : Config,
) -> Logger {
  let level = match config {
    Some(config) => config.level
    None => level
  }
  Logger::{ handler, level, category, config }
}

///|
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
pub fn[H : Handler] Logger::set_handler(self : Logger, handler : H) -> Unit {
  self.handler = handler
}

///|
pub fn Logger::set_config(self : Logger, config : Config) -> Unit {
  self.config = Some(config)
  self.level = config.level
}

///|
pub fn Logger::set_level(self : Logger, level : Level) -> Unit {
  self.level = level
}

///|
pub fn Logger::category(self : Logger) -> String? {
  self.category
}

///|
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
    _ => Config::new()
  }
}

///|
let global_logger : Logger = Logger(Stdout(), config=default_config())

///|
pub fn global() -> Logger {
  global_logger
}

///|
#callsite(autofill(loc))
pub fn fatal(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global().log(Fatal, message, fields?, category?, loc~)
}

///|
#callsite(autofill(loc))
pub fn error(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global().log(Error, message, fields?, category?, loc~)
}

///|
#callsite(autofill(loc))
pub fn warn(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global().log(Warn, message, fields?, category?, loc~)
}

///|
#callsite(autofill(loc))
pub fn info(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global().log(Info, message, fields?, category?, loc~)
}

///|
#callsite(autofill(loc))
pub fn debug(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global().log(Debug, message, fields?, category?, loc~)
}

///|
#callsite(autofill(loc))
pub fn trace(
  message : String,
  fields? : Map[String, Json],
  category? : String,
  loc~ : SourceLoc,
) -> Unit {
  global().log(Trace, message, fields?, category?, loc~)
}
