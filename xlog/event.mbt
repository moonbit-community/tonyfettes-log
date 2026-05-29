///|
/// A structured log event that is written field-by-field.
///
/// `Event` values are returned by logger level methods only when the log site is
/// enabled. Call `write_object_begin`, write each field, then call
/// `write_object_end` to emit the entry.
struct Event {
  logger : Logger
  entry : Entry
}

///|
/// Begin writing the structured object for this event.
pub fn Event::write_object_begin(self : Event) -> Unit {
  self.entry.fields.clear()
}

///|
/// Write one structured field.
pub fn[T : ToJson] Event::write_object_field(
  self : Event,
  key : String,
  value : T,
) -> Unit {
  self.entry.fields[key] = value.to_json()
}

///|
/// Finish and emit the event.
pub fn Event::write_object_end(self : Event) -> Unit {
  self.logger.handler.handle(self.entry) catch {
    _ => ()
  }
}
