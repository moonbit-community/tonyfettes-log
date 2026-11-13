#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>

#include "moonbit.h"

typedef struct {
  FILE *file;
} tonyfettes_xlog_internal_fs_file_t;

static void
tonyfettes_xlog_internal_fs_close_handle(
  tonyfettes_xlog_internal_fs_file_t *handle) {
  if (handle == NULL || handle->file == NULL) {
    return;
  }
  (void)fclose(handle->file);
  handle->file = NULL;
}

static void
tonyfettes_xlog_internal_fs_file_finalizer(void *ptr) {
  tonyfettes_xlog_internal_fs_close_handle(
    (tonyfettes_xlog_internal_fs_file_t *)ptr);
}

MOONBIT_FFI_EXPORT tonyfettes_xlog_internal_fs_file_t *
tonyfettes_xlog_internal_fs_open_append(moonbit_bytes_t path) {
  tonyfettes_xlog_internal_fs_file_t *handle =
    (tonyfettes_xlog_internal_fs_file_t *)moonbit_make_external_object(
      tonyfettes_xlog_internal_fs_file_finalizer,
      sizeof(tonyfettes_xlog_internal_fs_file_t));
  handle->file = fopen((const char *)path, "ab");
  return handle;
}

MOONBIT_FFI_EXPORT int
tonyfettes_xlog_internal_fs_is_null(
  tonyfettes_xlog_internal_fs_file_t *handle) {
  return handle == NULL || handle->file == NULL;
}

MOONBIT_FFI_EXPORT int
tonyfettes_xlog_internal_fs_write(
  tonyfettes_xlog_internal_fs_file_t *handle,
  moonbit_bytes_t data) {
  if (handle == NULL || handle->file == NULL) {
    return -1;
  }
  int len = Moonbit_array_length(data);
  if (len == 0) {
    return 0;
  }
  size_t written = fwrite(data, 1, (size_t)len, handle->file);
  return written == (size_t)len ? 0 : -1;
}

MOONBIT_FFI_EXPORT int
tonyfettes_xlog_internal_fs_stderr_write(moonbit_bytes_t data) {
  int len = Moonbit_array_length(data);
  if (len == 0) {
    return 0;
  }
  size_t written = fwrite(data, 1, (size_t)len, stderr);
  if (written != (size_t)len) {
    return -1;
  }
  return fflush(stderr) == 0 ? 0 : -1;
}

MOONBIT_FFI_EXPORT int
tonyfettes_xlog_internal_fs_flush(
  tonyfettes_xlog_internal_fs_file_t *handle) {
  if (handle == NULL || handle->file == NULL) {
    return -1;
  }
  return fflush(handle->file) == 0 ? 0 : -1;
}

MOONBIT_FFI_EXPORT void
tonyfettes_xlog_internal_fs_close(
  tonyfettes_xlog_internal_fs_file_t *handle) {
  tonyfettes_xlog_internal_fs_close_handle(handle);
}

#ifdef __cplusplus
}
#endif
