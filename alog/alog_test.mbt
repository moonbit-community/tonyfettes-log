///|
async test "pipe" {
  @async.with_task_group() <| root => {
    let (r, w) = @async/io.pipe()
    root.spawn_bg() <| () => {
      defer r.close()
      let text = r.read_all().text()
      let lines = []
      for line in text.split("\n") {
        let trimmed = line.trim()
        if trimmed.is_blank() {
          continue
        }
        lines.push(@json.parse(line))
      }
      guard lines is [line] else { fail("expect exactly one line") }
      guard line is Object(object) else { fail("expect an object") }
      guard object.get("timestamp") is Some(String(_)) else {
        fail("expect \"timestamp\" is some String")
      }
      guard object.get("level") is Some("INFO") else {
        fail("expect \"level\" is \"INFO\"")
      }
      guard object.get("message") is Some("Order 1 created") else {
        fail("expect \"message\" is \"Order 1 created\"")
      }
      guard object.get("fields") is Some({ "order_id": 1, .. }) else {
        fail(
          "expect \"fields\" to contain interpolated value: {\"order_id\":1}",
        )
      }
      guard object.get("category") is None else {
        fail("expect no \"category\" by default")
      }
    }
    root.spawn_bg() <| () => {
      defer w.close()
      @alog.with_logger(@alog.JsonHandler(w)) <| logger => {
        let order_id = 1
        logger.info("Order \{order_id} created", fields={ "order_id": 1 })
      }
    }
  }
}

///|
async test "category" {
  @async.with_task_group() <| root => {
    let (r, w) = @async/io.pipe()
    root.spawn_bg() <| () => {
      defer r.close()
      let text = r.read_all().text()
      let lines = []
      for line in text.split("\n") {
        let trimmed = line.trim()
        if trimmed.is_blank() {
          continue
        }
        lines.push(@json.parse(line))
      }
      guard lines is [line] else { fail("expect exactly one line") }
      guard line is Object(object) else { fail("expect an object") }
      guard object.get("category") is Some("orders") else {
        fail("expect \"category\" is \"orders\"")
      }
      guard object.get("message") is Some("Order created") else {
        fail("expect \"message\" is \"Order created\"")
      }
    }
    root.spawn_bg() <| () => {
      defer w.close()
      @alog.with_logger(@alog.JsonHandler(w), category="orders") <| logger => {
        logger.info("Order created")
      }
    }
  }
}

///|
async test "nested category" {
  @async.with_task_group() <| root => {
    let (r, w) = @async/io.pipe()
    root.spawn_bg() <| () => {
      defer r.close()
      let text = r.read_all().text()
      let lines = []
      for line in text.split("\n") {
        let trimmed = line.trim()
        if trimmed.is_blank() {
          continue
        }
        lines.push(@json.parse(line))
      }
      guard lines is [line] else { fail("expect exactly one line") }
      guard line is Object(object) else { fail("expect an object") }
      guard object.get("category") is Some("app.db") else {
        fail("expect \"category\" is \"app.db\"")
      }
      guard object.get("message") is Some("Query executed") else {
        fail("expect \"message\" is \"Query executed\"")
      }
    }
    root.spawn_bg() <| () => {
      defer w.close()
      @alog.with_logger(@alog.JsonHandler(w), category="app") <| logger => {
        let db = logger.child(category="db")
        db.info("Query executed")
      }
    }
  }
}

///|
async test "set level affects nested loggers" {
  @async.with_task_group() <| root => {
    let (r, w) = @async/io.pipe()
    root.spawn_bg() <| () => {
      defer r.close()
      let text = r.read_all().text()
      let lines = []
      for line in text.split("\n") {
        let trimmed = line.trim()
        if trimmed.is_blank() {
          continue
        }
        lines.push(@json.parse(line))
      }
      guard lines is [line] else { fail("expect exactly one line") }
      guard line is Object(object) else { fail("expect an object") }
      guard object.get("category") is Some("app.db") else {
        fail("expect \"category\" is \"app.db\"")
      }
      guard object.get("message") is Some("visible") else {
        fail("expect only the visible message")
      }
    }
    root.spawn_bg() <| () => {
      defer w.close()
      @alog.with_logger(@alog.JsonHandler(w), category="app", level=@alog.Warn) <| logger => {
        let db = logger.child(category="db")
        db.info("hidden")
        logger.set_level(@alog.Info)
        db.info("visible")
      }
    }
  }
}

///|
async test "text handler" {
  @async.with_task_group() <| root => {
    let (r, w) = @async/io.pipe()
    root.spawn_bg() <| () => {
      defer r.close()
      let text = r.read_all().text()
      guard text.contains("level=INFO") else {
        fail("expect text output to include level")
      }
      guard text.contains("category=text") else {
        fail("expect text output to include category")
      }
      guard text.contains("msg=") && text.contains("Text handler") else {
        fail("expect text output to include message")
      }
      guard text.contains("count=2") else {
        fail("expect text output to include fields")
      }
    }
    root.spawn_bg() <| () => {
      defer w.close()
      @alog.with_logger(@alog.TextHandler(w), category="text") <| logger => {
        logger.info("Text handler", fields={ "count": 2 })
      }
    }
  }
}

///|
async test "mux writes to all writers" {
  @async.with_task_group() <| root => {
    let (r1, w1) = @async/io.pipe()
    let (r2, w2) = @async/io.pipe()
    root.spawn_bg() <| () => {
      defer r1.close()
      inspect(r1.read_all().text(), content="hello mux")
    }
    root.spawn_bg() <| () => {
      defer r2.close()
      inspect(r2.read_all().text(), content="hello mux")
    }
    root.spawn_bg() <| () => {
      defer w1.close()
      defer w2.close()
      let mux = @alog.Mux([w1 as &@async/io.Writer, w2 as &@async/io.Writer])
      mux.write("hello mux")
    }
  }
}

///|
async test "mux writer" {
  let ps = ["_build/test.mux.0", "_build/test.mux.1"]
  let fs : Array[@async/fs.File] = []
  defer (for f in fs {
    f.close()
  })
  for p in ps {
    fs.push(
      @async/fs.open(
        p,
        mode=WriteOnly,
        append=true,
        create_mode=CreateOrTruncate,
      ),
    )
  }
  @alog.with_logger(
    @alog.JsonHandler(@alog.Mux(fs.map(fs => fs as &@async/io.Writer))),
  ) <| logger => {
    logger.info("Hello, world")
    logger.info("Goodbye, world")
  }
  async fn test_file_content(path : String) -> Unit {
    let text = @async/fs.read_file(path).text()
    let lines = []
    for line in text.split("\n") {
      let trimmed = line.trim()
      if trimmed.is_blank() {
        continue
      }
      lines.push(@json.parse(line))
    }
    guard lines is [first, second] else { fail("expect exactly two lines") }
    guard first is Object(first_object) else {
      fail("expect first line is object")
    }
    guard second is Object(second_object) else {
      fail("expect second line is object")
    }
    guard first_object.get("message") is Some("Hello, world") else {
      fail("expect first message")
    }
    guard second_object.get("message") is Some("Goodbye, world") else {
      fail("expect second message")
    }
  }
  for p in ps {
    test_file_content(p)
  }
}
