#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>

#include "moonbit.h"

MOONBIT_FFI_EXPORT int32_t
tonyfettes_xlog_stdout_write_line(moonbit_bytes_t data) {
  int32_t len = Moonbit_array_length(data);
  if (len > 0 && fwrite(data, 1, (size_t)len, stdout) != (size_t)len) {
    return -1;
  }
  if (fputc('\n', stdout) == EOF) {
    return -1;
  }
  return fflush(stdout) == 0 ? 0 : -1;
}

#ifdef __cplusplus
}
#endif
