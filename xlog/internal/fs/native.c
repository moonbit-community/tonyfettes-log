#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>

#include "moonbit.h"

MOONBIT_FFI_EXPORT FILE *
tonyfettes_xlog_internal_fs_open_append(moonbit_bytes_t path) {
  return fopen((const char *)path, "ab");
}

MOONBIT_FFI_EXPORT int tonyfettes_xlog_internal_fs_is_null(FILE *file) {
  return file == NULL;
}

MOONBIT_FFI_EXPORT int
tonyfettes_xlog_internal_fs_write(FILE *file, moonbit_bytes_t data) {
  if (file == NULL) {
    return -1;
  }
  int len = Moonbit_array_length(data);
  if (len == 0) {
    return 0;
  }
  size_t written = fwrite(data, 1, (size_t)len, file);
  return written == (size_t)len ? 0 : -1;
}

MOONBIT_FFI_EXPORT int
tonyfettes_xlog_internal_fs_flush(FILE *file) {
  if (file == NULL) {
    return -1;
  }
  return fflush(file) == 0 ? 0 : -1;
}

MOONBIT_FFI_EXPORT void
tonyfettes_xlog_internal_fs_close(FILE *file) {
  if (file == NULL) {
    return;
  }
  (void)fclose(file);
}

#ifdef __cplusplus
}
#endif
