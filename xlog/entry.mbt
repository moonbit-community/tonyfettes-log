///|
/// A structured log record passed to handlers.
pub struct Entry {
  /// The severity level of the record.
  level : Level
  /// The optional category associated with the record.
  category : String?
  /// The timestamp captured when the record was created.
  timestamp : @x/time.ZonedDateTime
  /// The source location captured from the logging callsite, if available.
  source : SourceLoc?
  /// Structured fields attached to the record.
  fields : Map[String, Json]
}

///|
fn Entry::Entry(
  level : Level,
  fields : Map[String, Json],
  category? : String,
  source? : SourceLoc,
  timestamp? : Int64 = @env.now().reinterpret_as_int64(),
) -> Entry {
  let timestamp = try! @x/time.unix(
    timestamp / 1_000,
    nanosecond=(timestamp % 1_000).to_int() * 1_000_000,
  )
  Entry::{ level, category, timestamp, source, fields }
}

///|
pub impl ToJson for Entry with fn to_json(self : Entry) -> Json {
  let object : Map[String, Json] = {
    "timestamp": self.timestamp.to_string(),
    "level": self.level.to_string(),
    "fields": self.fields.to_json(),
  }
  if self.category is Some(category) {
    object["category"] = Json::string(category)
  }
  if self.source is Some(source) {
    object["source"] = Json::string(source.to_string())
  }
  Json::object(object)
}

///|
pub impl Show for Entry with fn output(self, logger) -> Unit {
  logger <+ "timestamp=\{self.timestamp} level=\{self.level}"
  if self.category is Some(category) {
    logger <+ " category=\{category}"
  }
  if self.source is Some(source) {
    logger <+ " source=\{source}"
  }
  for key, value in self.fields {
    logger <+ " \{key}=\{value.stringify()}"
  }
}
