// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <io.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
typedef HANDLE sync_fd_t;
#else
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
typedef int SOCKET;
typedef int sync_fd_t;
#endif

#include "moonbit.h"

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_event_loop_get_platform(void) {
#ifdef _WIN32
  return 2;
#elif defined(__APPLE__)
  return 1;
#else
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_event_loop_read(
    sync_fd_t fd, moonbit_bytes_t buf, int32_t offset, int32_t len) {
#ifdef _WIN32
  return _read((int)fd, buf + offset, len);
#else
  return (int32_t)read(fd, buf + offset, len);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_event_loop_write(
    sync_fd_t fd, moonbit_bytes_t buf, int32_t offset, int32_t len) {
#ifdef _WIN32
  return _write((int)fd, buf + offset, len);
#else
  return (int32_t)write(fd, buf + offset, len);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_event_loop_bind(
    sync_fd_t fd, struct sockaddr *addr) {
  return bind((SOCKET)fd, addr, Moonbit_array_length(addr));
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_event_loop_connect(
    sync_fd_t fd, struct sockaddr *addr) {
  return connect((SOCKET)fd, addr, Moonbit_array_length(addr));
}

MOONBIT_FFI_EXPORT sync_fd_t tonyfettes_sync_event_loop_accept(
    sync_fd_t fd, struct sockaddr *addr) {
  socklen_t socklen =
      addr->sa_family == AF_INET ? sizeof(struct sockaddr_in)
                                 : sizeof(struct sockaddr_in6);
  sync_fd_t conn = (sync_fd_t)accept((SOCKET)fd, addr, &socklen);
#ifndef _WIN32
#ifdef FD_CLOEXEC
  if (conn >= 0) {
    int flags = fcntl(conn, F_GETFD);
    if (flags >= 0) {
      (void)fcntl(conn, F_SETFD, flags | FD_CLOEXEC);
    }
  }
#endif
#endif
  return conn;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_event_loop_recvfrom(
    sync_fd_t fd, moonbit_bytes_t buf, int32_t offset, int32_t len,
    struct sockaddr *addr) {
  socklen_t addr_size =
      addr->sa_family == AF_INET ? sizeof(struct sockaddr_in)
                                 : sizeof(struct sockaddr_in6);
  return (int32_t)recvfrom((SOCKET)fd, buf + offset, len, 0, addr, &addr_size);
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_event_loop_sendto(
    sync_fd_t fd, moonbit_bytes_t buf, int32_t offset, int32_t len,
    struct sockaddr *addr) {
  socklen_t addr_len =
      addr->sa_family == AF_INET ? sizeof(struct sockaddr_in)
                                 : sizeof(struct sockaddr_in6);
  return (int32_t)sendto((SOCKET)fd, buf + offset, len, 0, addr, addr_len);
}

#ifdef _WIN32
typedef ADDRINFOW addrinfo_t;
#else
typedef struct addrinfo addrinfo_t;
#endif

static int last_gai_error = 0;

MOONBIT_FFI_EXPORT addrinfo_t *
tonyfettes_sync_event_loop_getaddrinfo(void *hostname) {
  addrinfo_t hint;
  memset(&hint, 0, sizeof(hint));
  hint.ai_flags = AI_ADDRCONFIG;
  hint.ai_family = AF_UNSPEC;
  addrinfo_t *result = NULL;
#ifdef _WIN32
  last_gai_error = GetAddrInfoW((LPCWSTR)hostname, NULL, &hint, &result);
#else
  last_gai_error = getaddrinfo((const char *)hostname, NULL, &hint, &result);
  if (last_gai_error == EAI_SYSTEM) {
    errno = errno;
  }
#endif
  return last_gai_error == 0 ? result : NULL;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_event_loop_getaddrinfo_error(void) {
  return last_gai_error;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t
tonyfettes_sync_event_loop_gai_error(int32_t code) {
#ifdef _WIN32
  const char *msg = "getaddrinfo failed";
#else
  const char *msg = gai_strerror(code);
#endif
  size_t len = strlen(msg);
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, msg, len);
  return bytes;
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_event_loop_kind_of_fd(sync_fd_t fd) {
#ifdef _WIN32
  (void)fd;
  errno = ENOSYS;
  return -1;
#else
  struct stat st;
  if (fstat(fd, &st) < 0) {
    return -1;
  }
  if (S_ISREG(st.st_mode))
    return 1;
  if (S_ISDIR(st.st_mode))
    return 2;
  if (S_ISLNK(st.st_mode))
    return 3;
  if (S_ISSOCK(st.st_mode))
    return 4;
  if (S_ISFIFO(st.st_mode))
    return 5;
  if (S_ISBLK(st.st_mode))
    return 6;
  if (S_ISCHR(st.st_mode))
    return 7;
  return 0;
#endif
}
