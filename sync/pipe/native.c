// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

#include <errno.h>
#include <stdint.h>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#else
#include <fcntl.h>
#include <signal.h>
#include <unistd.h>
#endif

#include "moonbit.h"

#ifndef _WIN32
static int set_cloexec(int fd) {
  int flags = fcntl(fd, F_GETFD);
  if (flags < 0) {
    return -1;
  }
  if ((flags & FD_CLOEXEC) == 0 && fcntl(fd, F_SETFD, flags | FD_CLOEXEC) < 0) {
    return -1;
  }
  return 0;
}
#endif

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_pipe_pipe(int32_t *fds) {
#ifdef _WIN32
  return _pipe(fds, 4096, _O_BINARY);
#else
  signal(SIGPIPE, SIG_IGN);
  if (pipe(fds) < 0) {
    return -1;
  }
  if (set_cloexec(fds[0]) < 0 || set_cloexec(fds[1]) < 0) {
    int saved = errno;
    close(fds[0]);
    close(fds[1]);
    errno = saved;
    return -1;
  }
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_pipe_close(int32_t fd) {
#ifdef _WIN32
  return _close(fd);
#else
  return close(fd);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_pipe_read(int32_t fd,
                                                     moonbit_bytes_t dst,
                                                     int32_t offset,
                                                     int32_t len) {
#ifdef _WIN32
  return _read(fd, dst + offset, len);
#else
  return (int32_t)read(fd, dst + offset, len);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_pipe_write(int32_t fd,
                                                      moonbit_bytes_t src,
                                                      int32_t offset,
                                                      int32_t len) {
#ifdef _WIN32
  return _write(fd, src + offset, len);
#else
  return (int32_t)write(fd, src + offset, len);
#endif
}

