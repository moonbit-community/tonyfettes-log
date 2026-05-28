///|
pub async fn[T, H : Handler] with_logger(
  handler : H,
  f : async (Logger) -> T,
  level? : Level = Info,
  category? : String,
) -> T {
  @async.with_task_group() <| group => {
    let q : @aqueue.Queue[Entry] = @aqueue.Queue(kind=Unbounded)
    let task : @async.Task[Unit] = group.spawn() <| () => {
      try {
        for ;; {
          let entry = q.get()
          handler.handle(entry)
        }
      } catch {
        @aqueue.QueueAlreadyClosed => ()
        err => raise err
      }
    }
    // If `f` raises, drain the queue before re-raising so accepted entries are
    // still written instead of being cancelled with the task group.
    let value = try? f(Logger::new(q, level~, category?))
    q.close()
    task.wait()
    value.unwrap_or_error()
  }
}
