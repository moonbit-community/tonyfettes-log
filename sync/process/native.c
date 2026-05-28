// Copyright 2026
//
// Licensed under the Apache License, Version 2.0.

#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#include <process.h>
#include <windows.h>
#else
#include <fcntl.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

#include "moonbit.h"

#ifndef _WIN32
extern char **environ;

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

static const char *find_env(char **envp, const char *name) {
  size_t len = strlen(name);
  for (char **cursor = envp; cursor && *cursor; ++cursor) {
    if (strncmp(*cursor, name, len) == 0 && (*cursor)[len] == '=') {
      return *cursor + len + 1;
    }
  }
  return NULL;
}

static void write_exec_error(int fd, int err) {
  while (write(fd, &err, sizeof(err)) < 0 && errno == EINTR) {
  }
}

static void exec_with_path(const char *cmd, char **argv, char **envp) {
  if (strchr(cmd, '/')) {
    execve(cmd, argv, envp);
    return;
  }
  const char *path = find_env(envp, "PATH");
  if (!path || path[0] == '\0') {
    path = "/usr/bin:/bin";
  }
  int saved_errno = ENOENT;
  const char *start = path;
  while (1) {
    const char *end = strchr(start, ':');
    size_t dir_len = end ? (size_t)(end - start) : strlen(start);
    const char *dir = dir_len == 0 ? "." : start;
    if (dir_len == 0) {
      dir_len = 1;
    }
    size_t cmd_len = strlen(cmd);
    char *full = (char *)malloc(dir_len + 1 + cmd_len + 1);
    if (!full) {
      errno = ENOMEM;
      return;
    }
    memcpy(full, dir, dir_len);
    full[dir_len] = '/';
    memcpy(full + dir_len + 1, cmd, cmd_len + 1);
    execve(full, argv, envp);
    int err = errno;
    free(full);
    if (err == EACCES) {
      saved_errno = EACCES;
    } else if (err != ENOENT && err != ENOTDIR) {
      saved_errno = err;
    }
    if (!end) {
      errno = saved_errno;
      return;
    }
    start = end + 1;
  }
}
#endif

MOONBIT_FFI_EXPORT moonbit_bytes_t *tonyfettes_sync_process_get_curr_env(void) {
#ifdef _WIN32
  moonbit_bytes_t *result = (moonbit_bytes_t *)moonbit_make_ref_array(1, 0);
  result[0] = 0;
  return result;
#else
  int len = 0;
  for (char **cursor = environ; *cursor; ++cursor) {
    ++len;
  }
  moonbit_bytes_t *result = (moonbit_bytes_t *)moonbit_make_ref_array(len + 1, 0);
  for (int i = 0; i < len; ++i) {
    char *entry = environ[i];
    int entry_len = (int)strlen(entry);
    moonbit_bytes_t bytes = moonbit_make_bytes(entry_len, 0);
    memcpy(bytes, entry, entry_len);
    result[i] = bytes;
  }
  result[len] = 0;
  return result;
#endif
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_process_spawn(moonbit_bytes_t cmd, moonbit_bytes_t *argv,
                              moonbit_bytes_t *envp, int32_t stdin_fd,
                              int32_t stdout_fd, int32_t stderr_fd,
                              int32_t has_cwd, moonbit_bytes_t cwd) {
#ifdef _WIN32
  (void)cmd;
  (void)argv;
  (void)envp;
  (void)stdin_fd;
  (void)stdout_fd;
  (void)stderr_fd;
  (void)has_cwd;
  (void)cwd;
  errno = ENOSYS;
  return -1;
#else
  signal(SIGPIPE, SIG_IGN);
  int errpipe[2];
  if (pipe(errpipe) < 0) {
    return -1;
  }
  if (set_cloexec(errpipe[1]) < 0) {
    int saved = errno;
    close(errpipe[0]);
    close(errpipe[1]);
    errno = saved;
    return -1;
  }
  pid_t pid = fork();
  if (pid < 0) {
    int saved = errno;
    close(errpipe[0]);
    close(errpipe[1]);
    errno = saved;
    return -1;
  }
  if (pid == 0) {
    close(errpipe[0]);
    if (has_cwd && chdir((const char *)cwd) < 0) {
      write_exec_error(errpipe[1], errno);
      _exit(127);
    }
    if (stdin_fd >= 0 && dup2(stdin_fd, STDIN_FILENO) < 0) {
      write_exec_error(errpipe[1], errno);
      _exit(127);
    }
    if (stdout_fd >= 0 && dup2(stdout_fd, STDOUT_FILENO) < 0) {
      write_exec_error(errpipe[1], errno);
      _exit(127);
    }
    if (stderr_fd >= 0 && dup2(stderr_fd, STDERR_FILENO) < 0) {
      write_exec_error(errpipe[1], errno);
      _exit(127);
    }
    exec_with_path((const char *)cmd, (char **)argv, (char **)envp);
    write_exec_error(errpipe[1], errno);
    _exit(127);
  }
  close(errpipe[1]);
  int child_errno = 0;
  ssize_t n = read(errpipe[0], &child_errno, sizeof(child_errno));
  close(errpipe[0]);
  if (n > 0) {
    int status;
    while (waitpid(pid, &status, 0) < 0 && errno == EINTR) {
    }
    errno = child_errno;
    return -1;
  }
  return (int32_t)pid;
#endif
}

static int status_to_exit_code(int status) {
#ifdef _WIN32
  return status;
#else
  if (WIFEXITED(status)) {
    return WEXITSTATUS(status);
  }
  if (WIFSIGNALED(status)) {
    return 128 + WTERMSIG(status);
  }
  return status;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_process_wait_pid(int32_t pid,
                                                            int32_t *out) {
#ifdef _WIN32
  (void)pid;
  (void)out;
  errno = ENOSYS;
  return -1;
#else
  int status;
  pid_t ret;
  do {
    ret = waitpid((pid_t)pid, &status, 0);
  } while (ret < 0 && errno == EINTR);
  if (ret < 0) {
    return -1;
  }
  *out = status_to_exit_code(status);
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_process_try_wait_pid(int32_t pid,
                                                                int32_t *out) {
#ifdef _WIN32
  (void)pid;
  (void)out;
  errno = ENOSYS;
  return -1;
#else
  int status;
  pid_t ret = waitpid((pid_t)pid, &status, WNOHANG);
  if (ret < 0) {
    return -1;
  }
  if (ret == 0) {
    return 0;
  }
  *out = status_to_exit_code(status);
  return 1;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_process_terminate(int32_t pid,
                                                             int32_t sig) {
#ifdef _WIN32
  (void)pid;
  (void)sig;
  errno = ENOSYS;
  return -1;
#else
  return kill((pid_t)pid, sig);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_process_kill(int32_t pid) {
#ifdef _WIN32
  (void)pid;
  errno = ENOSYS;
  return -1;
#else
  return kill((pid_t)pid, SIGKILL);
#endif
}

MOONBIT_FFI_EXPORT void tonyfettes_sync_process_sleep_millis(int32_t ms) {
#ifdef _WIN32
  Sleep((DWORD)ms);
#else
  if (ms <= 0) {
    return;
  }
  struct timespec ts;
  ts.tv_sec = ms / 1000;
  ts.tv_nsec = (long)(ms % 1000) * 1000000L;
  while (nanosleep(&ts, &ts) < 0 && errno == EINTR) {
  }
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_process_pipe(int32_t *fds) {
#ifdef _WIN32
  return _pipe(fds, 4096, _O_BINARY);
#else
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

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_process_close(int32_t fd) {
#ifdef _WIN32
  return _close(fd);
#else
  return close(fd);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_process_read(int32_t fd,
                                                        moonbit_bytes_t dst,
                                                        int32_t offset,
                                                        int32_t len) {
#ifdef _WIN32
  return _read(fd, dst + offset, len);
#else
  return (int32_t)read(fd, dst + offset, len);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_process_write(int32_t fd,
                                                         moonbit_bytes_t src,
                                                         int32_t offset,
                                                         int32_t len) {
#ifdef _WIN32
  return _write(fd, src + offset, len);
#else
  return (int32_t)write(fd, src + offset, len);
#endif
}

