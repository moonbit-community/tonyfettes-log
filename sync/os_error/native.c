#ifdef __cplusplus
extern "C" {
#endif

#include <errno.h>
#include <stdint.h>
#include <string.h>

#ifdef _WIN32
#include <winsock2.h>
#endif

#include "moonbit.h"

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_os_error_get_errno(void) {
  return errno;
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_os_error_is_nonblocking_io_error(int32_t err) {
  return err == EAGAIN
#ifdef EWOULDBLOCK
         || err == EWOULDBLOCK
#endif
#ifdef EINPROGRESS
         || err == EINPROGRESS
#endif
      ;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_os_error_is_EINTR(int32_t err) {
#ifdef EINTR
  return err == EINTR;
#else
  (void)err;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_os_error_is_ENOENT(int32_t err) {
  return err == ENOENT;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_os_error_is_EEXIST(int32_t err) {
  return err == EEXIST;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_os_error_is_EACCES(int32_t err) {
  return err == EACCES;
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_os_error_is_ECONNREFUSED(int32_t err) {
#ifdef ECONNREFUSED
  return err == ECONNREFUSED;
#else
  (void)err;
  return 0;
#endif
}

MOONBIT_FFI_EXPORT moonbit_bytes_t
tonyfettes_sync_os_error_errno_to_string(int32_t err) {
  const char *message = strerror(err);
  size_t len = strlen(message);
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, message, len);
  return bytes;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_os_error_get_ENOTDIR(void) {
#ifdef ENOTDIR
  return ENOTDIR;
#else
  return 0;
#endif
}

#ifdef __cplusplus
}
#endif
