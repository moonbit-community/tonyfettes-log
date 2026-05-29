///|
/// A structured log event that is written field-by-field.
///
/// `Event` values are returned by logger level methods only when the log site is
/// enabled. Call `write_object_begin`, write each field, then call
/// `write_object_end` to emit the entry.
struct Event {
  logger : Logger
  level : Level
  category : String?
  source : SourceLoc?
  fields : Map[String, Json]
  mut finished : Bool
}

///|
/// Begin writing the structured object for this event.
pub fn Event::write_object_begin(self : Event) -> Unit {
  if !self.finished {
    self.fields.clear()
  }
}

///|
/// Write one structured field.
pub fn[T : ToJson] Event::write_object_field(
  self : Event,
  key : String,
  value : T,
) -> Unit {
  if !self.finished {
    self.fields[key] = value.to_json()
  }
}

///|
/// Finish and emit the event.
///
/// Calling this more than once is safe; only the first call emits.
pub fn Event::write_object_end(self : Event) -> Unit {
  if !self.finished {
    self.finished = true
    self.logger.handler.handle(
      Entry(
        level=self.level,
        category?=self.category,
        source?=self.source,
        fields=self.fields,
      ),
    ) catch {
      _ => ()
    }
  }
}
