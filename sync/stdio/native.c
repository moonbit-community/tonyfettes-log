// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

#include <stdint.h>

#ifdef _WIN32
#include <io.h>
#else
#include <signal.h>
#include <unistd.h>
#endif

#include "moonbit.h"

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_stdio_read(int32_t fd,
                                                      moonbit_bytes_t dst,
                                                      int32_t offset,
                                                      int32_t len) {
#ifdef _WIN32
  return _read(fd, dst + offset, len);
#else
  return (int32_t)read(fd, dst + offset, len);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_stdio_write(int32_t fd,
                                                       moonbit_bytes_t src,
                                                       int32_t offset,
                                                       int32_t len) {
#ifndef _WIN32
  signal(SIGPIPE, SIG_IGN);
#endif
#ifdef _WIN32
  return _write(fd, src + offset, len);
#else
  return (int32_t)write(fd, src + offset, len);
#endif
}

