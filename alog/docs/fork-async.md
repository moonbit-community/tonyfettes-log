# Forking `moonbitlang/async` for Background Runtime Threads

## Goal

Build async runtime support that can run in a dedicated OS thread while a normal
synchronous MoonBit program continues on the main thread.

This document is only about the async runtime work. The logger, OTLP encoding,
and logger public API are intentionally out of scope until the runtime thread
model is proven.

The target shape is:

```text
main thread
  synchronous MoonBit code
  C-owned cross-thread queue / wake primitive

runtime thread
  one isolated async runtime instance
  MoonBit async tasks
  async socket/http/tls/fs support
```

The important invariant is that only the runtime owner thread executes MoonBit
code that touches that runtime. Other threads may wake it or submit C-owned
data, but must not touch the runtime's MoonBit heap objects.

## Current Constraints In Upstream `async`

The current `moonbitlang/async` implementation is designed around one logical
runtime:

- `src/internal/coroutine/scheduler.mbt` has a global `scheduler`.
- `src/internal/event_loop/event_loop.mbt` has a global `curr_loop`.
- `src/internal/event_loop/thread_pool.c` has a process-global `pool`.
- Windows IOCP support in `src/internal/event_loop/iocp.c` has a static event
  buffer.
- The README describes the user code model as single-threaded cooperative
  multitasking.

Those facts do not prevent a fork, but they mean the fork must make runtime
state explicit or thread-local before multiple OS threads can safely run async
code.

## Safety Model

The fork should not require atomic reference counts in the MoonBit runtime as a
first step. Instead, it should enforce a stricter ownership boundary:

1. A MoonBit heap object belongs to exactly one runtime owner thread.
2. A MoonBit `String`, `Bytes`, `Array`, `Map`, closure, coroutine, async
   continuation, or user object must not be shared across runtime threads.
3. Cross-thread communication uses only C-owned memory and primitive handles:
   `malloc` buffers, integers, atomics, mutexes, pipes, eventfds, IOCP packets,
   or file descriptors / handles.
4. The receiving runtime thread converts C-owned payloads into MoonBit values
   after dequeueing them.
5. The sending thread may serialize or copy into C memory, then forget the
   MoonBit source object.

This is why `tonyfettes/c` primitives are a good boundary: `thrd`, `atomic`,
`Pointer`, and `malloc/free` can represent data that is not managed by the
MoonBit heap.

## Proposed Runtime Shape

Introduce a runtime object owned by one OS thread:

```text
Runtime
  Scheduler
  EventLoop
  RuntimeThreadPool
  RuntimeWakeEndpoint
  timers
  jobs
  fd table
  platform state
```

External threads receive only a `RuntimeHandle`:

```text
RuntimeHandle
  C-owned queue pointer
  wake fd / eventfd / IOCP handle
  shutdown flag
```

`RuntimeHandle` must be an external C-managed handle. It must not expose the
MoonBit `Runtime` object to other threads.

## Implementation Plan

Each step should be kept small and should leave the fork passing tests before
the next step starts.

### Step 0: Baseline Fork

Create a fork of `moonbitlang/async` and keep behavior identical.

Recommended workflow:

- Keep the upstream package names at first to minimize code churn.
- Run the upstream test suite before touching runtime internals.
- Add a short `FORK_NOTES.md` in the fork explaining the branch goal.

Verification:

```sh
moon check
moon test --target native
moon test --target js
```

Native support is the priority, but JS should keep passing until a step is
explicitly native-only.

### Step 1: Wrap The Global Scheduler

Add a `Runtime` or `RuntimeState` type that owns the existing `Scheduler`.

Initial implementation can still use a single default runtime:

```text
default_runtime.scheduler
```

The purpose of this step is only mechanical: replace direct references to the
global `scheduler` with access through `current_runtime().scheduler`.

Do not introduce threads yet.

Verification:

```sh
moon test src/internal/coroutine --target native
moon test src --target native
```

Add tests:

- `pause` and wake order are unchanged.
- cancellation behavior is unchanged.
- `no_more_work()` still reports the same states.

### Step 2: Move `curr_loop` Into Runtime State

Move `curr_loop` from a package global `Ref[EventLoop?]` into runtime-owned
state.

All places that currently do:

```text
guard curr_loop.val is Some(evloop)
```

should instead resolve the current runtime and then read the runtime's current
event loop.

Still run only one runtime on one thread in this step.

Verification:

```sh
moon test src/internal/event_loop --target native
moon test src/fs --target native
moon test src/socket --target native
moon test src/http --target native
```

### Step 3: Add Runtime-Local Current Context

Add a way to get/set the current runtime for the current OS thread.

There are two viable designs:

- Explicit parameter threading through all internal APIs. This is safest but
  invasive.
- Thread-local current runtime. This is less invasive and probably the right
  fork direction.

For the thread-local design, use a small native stub:

```text
set_current_runtime(Runtime)
clear_current_runtime()
current_runtime() -> Runtime
```

The TLS slot may hold a MoonBit runtime object pointer, but only the owner
thread may set/read/clear that slot. If the C TLS stores the object beyond one
call, it must incref on set and decref on clear, both on the owner thread.

Verification:

- Run the normal suite.
- Add a native smoke test that creates two runtimes sequentially in one process.
- Confirm hooks, timers, and fd cleanup do not leak from the first runtime into
  the second.

### Step 4: Instance-Local Thread Pool

Refactor `src/internal/event_loop/thread_pool.c` so the pool is not a process
global.

Current shape:

```text
global pool
  notify_send
  signal masks
  worker wake state
```

Target shape:

```text
ThreadPool*
  notify_send
  signal masks / old masks where applicable
  worker wake state
```

MoonBit-side worker APIs should carry the pool pointer through `EventLoop`.

Important details:

- A `Worker` should know which `ThreadPool` owns it.
- Destroying one runtime must not destroy another runtime's workers.
- Unix signal handling needs extra care because signal masks are process/thread
  state, not purely runtime-local state.

Verification:

```sh
moon test src/fs --target native
moon test src/process --target native
moon test src/internal/event_loop --target native
```

Add a stress test:

- Runtime A starts a worker job.
- Runtime B starts a worker job.
- Both complete.
- Destroy A.
- B can still start and complete another worker job.

### Step 5: Instance-Local Poll Event Buffers

Remove static shared event buffers from poll backends.

Known Windows issue:

- `iocp.c` has `static OVERLAPPED_ENTRY event_buffer[1024]`.

Audit Unix backends too:

- `epoll.c`
- `kqueue.c`

Target shape:

```text
PollInstance
  platform poll handle
  event buffer
```

`get_event(index)` should become `get_event(instance, index)` or equivalent.

Verification:

- Run event-loop tests.
- Add a test with two runtimes blocked in poll on separate OS threads. Wake
  each runtime independently and assert each receives only its own wake event.

### Step 6: Add A Cross-Thread Wake Primitive

Add a runtime wake endpoint that can be signaled from other threads without
touching MoonBit objects.

Unix options:

- dedicated pipe registered with poll
- `eventfd` on Linux, pipe fallback elsewhere
- kqueue user event on macOS, pipe fallback for portability

Windows option:

- post a custom IOCP packet with `PostQueuedCompletionStatus`

Keep the wake channel separate from worker completion at first. This avoids
rewriting existing worker completion packet encoding too early.

Wake packet kinds:

```text
WakeUser
WakeShutdown
WakeStats
```

The first implementation only needs `WakeUser` and `WakeShutdown`.

Verification:

- Start one runtime on the current thread.
- From a C thread, call `RuntimeHandle::wake(WakeUser)` 10,000 times.
- Runtime counts wake events.
- No MoonBit value crosses the wake boundary.

### Step 7: Add A C-Owned MPSC Queue

Add a minimal C queue for cross-thread payload submission.

Payload shape for tests:

```text
struct packet {
  uint32_t kind;
  uint32_t len;
  uint8_t data[];
}
```

The queue owns every packet. The runtime thread frees packets after processing.

Start with mutex + condition/wake, not a lock-free queue. Correctness is more
important than throughput in this phase.

Verification:

- Main thread submits N packets and wakes runtime.
- Runtime drains packets and checks byte contents.
- Multiple producer C threads submit concurrently.
- Runtime receives exactly all packets.
- Run with AddressSanitizer if available.

### Step 8: Start A Runtime On A New OS Thread

Add an internal native API:

```text
RuntimeThread::start(async () -> Unit) -> RuntimeThread
RuntimeThread::handle(self) -> RuntimeHandle
RuntimeThread::request_shutdown(self)
RuntimeThread::join(self)
```

The OS thread entry should be a static MoonBit function or `FuncRef` with no
captured MoonBit environment. Thread startup data must be C-owned.

Thread entry sequence:

```text
create Runtime on this thread
set current runtime TLS
create EventLoop
publish RuntimeHandle
run async main task
cleanup EventLoop
clear current runtime TLS
mark stopped
```

Open question to verify early:

- Is executing generated MoonBit code from a C-created thread reliable when the
  thread does not receive a MoonBit heap object from another thread?

`tonyfettes/c` has tests that call MoonBit function pointers from C11 threads,
but this step must add a stronger test that allocates MoonBit objects only on
the runtime thread while the main thread also allocates unrelated MoonBit
objects.

Verification:

- Runtime thread runs `sleep` / timer task and exits.
- Runtime thread runs a local TCP or HTTP client task and exits.
- Main thread repeatedly allocates and drops arrays/strings while runtime
  thread is active.
- No MoonBit object is passed between threads.

### Step 9: Runtime Shutdown Semantics

Define shutdown before building real users on top.

Recommended semantics:

1. `request_shutdown` posts `WakeShutdown`.
2. Runtime stops accepting new C queue packets.
3. Runtime drains already accepted packets.
4. Runtime cancels or joins async tasks according to runtime policy.
5. Runtime exits the event loop and closes fds/handles.
6. `join` waits for OS thread termination.

Do not expose a generic `flush` API at this layer. Shutdown is lifecycle, not a
normal operation.

Verification:

- shutdown while idle
- shutdown while sleeping
- shutdown while blocked in HTTP/socket connect
- shutdown while worker thread job is active
- repeated start/shutdown cycles

### Step 10: Public API Boundary

Keep most of the above internal until stable.

Potential public surface:

```text
RuntimeThread
RuntimeHandle
RuntimeThread::start
RuntimeThread::request_shutdown
RuntimeThread::join
```

Do not expose scheduler, event loop, worker pool, poll instance, or raw MoonBit
runtime objects.

## Windows Plan

Windows should use IOCP as the runtime wake target.

Current IOCP backend already has the right basic mechanism:

```text
CreateIoCompletionPort
GetQueuedCompletionStatusEx
PostQueuedCompletionStatus
```

Required changes:

1. Move `event_buffer` into the IOCP instance.
2. Add `poll_post_custom(instance, tag)` or equivalent.
3. Teach Windows `poll()` to distinguish:
   - real fd/handle IO completions
   - thread-pool job completions
   - custom runtime wake packets
   - shutdown packets
4. Refcount or once-initialize Winsock. Current event loop calls WSA init and
   cleanup per loop; multiple concurrent runtimes need shared lifecycle
   handling.

Prefer one IOCP per runtime. Do not share one IOCP across runtime threads in
the first version.

## Unix Plan

Unix can use a dedicated wake pipe per runtime.

Initial plan:

```text
runtime.wake_recv registered with poll
runtime_handle.wake_send written by foreign threads
```

The payload can be a fixed-size `uint64_t` tag. The runtime drains until the
pipe would block.

Linux can later use `eventfd` for lower overhead, but a pipe is portable across
Linux and macOS and matches existing async style.

Signal handling is the hardest Unix global. The first fork should keep signal
handling owned by the main async runtime only, or disable async signal support
for background runtimes until it is explicitly designed.

## Global-State Audit Checklist

Before declaring multi-runtime support done, audit and classify every package
global:

- scheduler state
- current event loop
- event-loop hooks
- thread pool state
- poll event buffers
- WSA state on Windows
- OpenSSL load/init state
- stdio registration hooks
- socket interface cache
- signal handler state
- any `Ref[...]`, `Map`, or mutable `Array` in internal packages

Each global should become one of:

- immutable constant
- process-global with synchronization / once-init
- runtime-local field
- owner-thread-only TLS value
- removed

## CI / Test Matrix

Minimum test matrix:

```sh
moon check --target native
moon test --target native
moon test src/internal/coroutine --target native
moon test src/internal/event_loop --target native
moon test src/http --target native
```

Platform matrix:

- macOS native
- Linux native
- Windows native

Optional but valuable:

- AddressSanitizer for C queue and handle lifetime
- ThreadSanitizer for C primitive synchronization
- stress test that runs two runtime threads while the main thread allocates and
  drops MoonBit objects

## Stop Conditions

Stop and reconsider if any of these are observed:

- a MoonBit heap object must cross runtime threads to make the API ergonomic
- generated MoonBit code cannot reliably run from a C-created thread
- global runtime state cannot be made runtime-local without rewriting most of
  async/http/tls/socket
- Windows IOCP requires sharing one completion port across runtimes
- signal handling cannot be isolated well enough for background runtimes

If one of these happens, the sidecar-process design becomes the safer route.

## Relationship To Logger Work

The logger should wait until this runtime work proves:

- a background runtime thread can run async tasks independently
- another thread can submit C-owned packets and wake it
- shutdown works on macOS, Linux, and Windows
- no MoonBit heap object is shared across threads

Only after that should the logger decide whether its OTel exporter runs inside
this in-process runtime or in a separate sidecar process.
