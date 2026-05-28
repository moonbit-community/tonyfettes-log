///|
pub struct Entry {
  level : Level
  category : String?
  timestamp : @x/time.ZonedDateTime
  source : SourceLoc?
  message : String
  fields : Map[String, Json]
}

///|
fn Entry::Entry(
  level~ : Level,
  category? : String,
  source? : SourceLoc,
  timestamp? : Int64 = @env.now().reinterpret_as_int64(),
  message : String,
  fields? : Map[String, Json] = {},
) -> Entry {
  let timestamp = try! @x/time.unix(
    timestamp / 1_000,
    nanosecond=(timestamp % 1_000).to_int() * 1_000_000,
  )
  Entry::{ level, category, timestamp, source, message, fields }
}

///|
pub impl ToJson for Entry with fn to_json(self : Entry) -> Json {
  let object : Map[String, Json] = {
    "timestamp": self.timestamp.to_string(),
    "level": self.level.to_string(),
    "message": self.message,
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
  let msg = self.message.escape()
  logger <+ "timestamp=\{self.timestamp} level=\{self.level}"
  if self.category is Some(category) {
    logger <+ " category=\{category}"
  }
  if self.source is Some(source) {
    logger <+ " source=\{source}"
  }
  logger <+ " msg=\{msg}"
  for key, value in self.fields {
    logger <+ " \{key}=\{value.stringify()}"
  }
}
