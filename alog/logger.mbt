///|
struct Logger {
  q : @aqueue.Queue[Entry]
  level : Ref[Level]
  category : String?
}

///|
fn Logger::new(
  q : @aqueue.Queue[Entry],
  level? : Level = Info,
  category? : String,
) -> Logger {
  Logger::{ q, level: Ref(level), category }
}

///|
pub fn Logger::child(
  self : Logger,
  category? : String,
  level? : Level,
) -> Logger {
  let category = match (self.category, category) {
    (None, None) => None
    (Some(category), None) | (None, Some(category)) => Some(category)
    (Some(parent), Some(child)) => Some("\{parent}.\{child}")
  }
  let level = match level {
    Some(level) => Ref(level)
    None => self.level
  }
  Logger::{ q: self.q, level, category }
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
    guard (try? self.q.try_put(
        Entry(level~, category?=self.category, source=loc, message, fields?),
      ))
      is Ok(true)
  }
}

///|
fn Logger::is_level_enabled(self : Logger, level : Level) -> Bool {
  level <= self.level.val
}

///|
pub fn Logger::set_level(self : Logger, level : Level) -> Unit {
  self.level.val = level
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
