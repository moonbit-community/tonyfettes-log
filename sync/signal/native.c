// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

#include <stdint.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <signal.h>
#endif

#include "moonbit.h"

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_signal_sigint(void) {
#ifdef _WIN32
  return CTRL_C_EVENT;
#else
  return SIGINT;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_signal_sigterm(void) {
#ifdef _WIN32
  return -1;
#else
  return SIGTERM;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_signal_sighup(void) {
#ifdef _WIN32
  return CTRL_CLOSE_EVENT;
#else
  return SIGHUP;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_signal_sigbreak(void) {
#ifdef _WIN32
  return CTRL_BREAK_EVENT;
#else
  return -1;
#endif
}

