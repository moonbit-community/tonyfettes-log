///|
struct Logger {
  writer : &Writer
  mut level : Level
  category : String?
  config : Config?
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
pub fn[W : Writer] Logger::Logger(
  writer : W,
  level? : Level = Info,
  category? : String,
  config? : Config,
) -> Logger {
  let level = match config {
    Some(config) => config.level
    None => level
  }
  Logger::{ writer, level, category, config }
}

///|
pub fn Logger::child(
  self : Logger,
  category? : String,
  level? : Level = self.level,
) -> Logger {
  let category = match (self.category, category) {
    (None, None) => None
    (Some(category), None) | (None, Some(category)) => Some(category)
    (Some(parent), Some(child)) => Some("\{parent}.\{child}")
  }
  Logger::{ ..self, category, level }
}

///|
#callsite(autofill(loc))
pub fn Logger::log(
  self : Logger,
  level : Level,
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  if self.is_level_enabled(level) {
    self.writer.write(
      Entry(level~, category?=self.category, source=loc, message, fields?),
    )
  }
}

///|
fn Logger::is_level_enabled(self : Logger, level : Level) -> Bool {
  let effective = if self.config is Some(config) &&
    self.category is Some(category) {
    config.get_category_level(category).unwrap_or(self.level)
  } else {
    self.level
  }
  level <= effective
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
let default_logger : Ref[Logger?] = Ref(None)

///|
fn default_config() -> Config {
  Config::from_env(env="MOON_SLOG") catch {
    _ => {
      self_log.push(
        Entry(level=Error, category="self_log", "failed to parse MOON_SLOG", fields={
          "env": "MOON_SLOG",
        }),
      )
      Config::new()
    }
  }
}

///|
pub fn default() -> Logger {
  match default_logger.val {
    Some(logger) => logger
    None => {
      let config = default_config()
      let logger = Logger(Stdout(), config~)
      default_logger.val = Some(logger)
      logger
    }
  }
}

///|
pub fn set_default(logger : Logger) -> Unit {
  default_logger.val = Some(logger)
}

///|
#callsite(autofill(loc))
pub fn log(
  level : Level,
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  default().log(level, message, fields?, loc~)
}

///|
#callsite(autofill(loc))
pub fn fatal(
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  log(Fatal, message, fields?, loc~)
}

///|
#callsite(autofill(loc))
pub fn error(
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  log(Error, message, fields?, loc~)
}

///|
#callsite(autofill(loc))
pub fn warn(
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  log(Warn, message, fields?, loc~)
}

///|
#callsite(autofill(loc))
pub fn info(
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  log(Info, message, fields?, loc~)
}

///|
#callsite(autofill(loc))
pub fn debug(
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  log(Debug, message, fields?, loc~)
}

///|
#callsite(autofill(loc))
pub fn trace(
  message : String,
  fields? : Map[String, Json],
  loc~ : SourceLoc,
) -> Unit {
  log(Trace, message, fields?, loc~)
}
