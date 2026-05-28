#ifdef __cplusplus
extern "C" {
#endif

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>

#ifdef _WIN32
#include <direct.h>
#include <fcntl.h>
#include <io.h>
#include <windows.h>
#else
#include <dirent.h>
#include <fcntl.h>
#include <limits.h>
#include <sys/file.h>
#ifdef __linux__
#include <linux/fs.h>
#include <sys/syscall.h>
#endif
#ifdef __APPLE__
#include <sys/attr.h>
#include <sys/vnode.h>
#endif
#include <unistd.h>
#endif

#include "moonbit.h"

#ifdef _WIN32
typedef FILE_ID_BOTH_DIR_INFO sync_dirent_t;
#elif defined(__APPLE__)
typedef struct {
  uint32_t d_reclen;
  attribute_set_t d_attrs;
  attrreference_t d_name;
  fsobj_type_t d_type;
} sync_dirent_t;
#elif defined(__linux__)
typedef struct {
  uint64_t d_ino;
  int64_t d_off;
  unsigned short d_reclen;
  unsigned char d_type;
  char d_name[];
} sync_dirent_t;
#endif

typedef struct {
  int fd;
} tonyfettes_sync_file_t;

static tonyfettes_sync_file_t *sync_file_from_fd(int fd) {
  tonyfettes_sync_file_t *file =
      (tonyfettes_sync_file_t *)malloc(sizeof(tonyfettes_sync_file_t));
  if (file == NULL) {
    int saved_errno = errno;
#ifdef _WIN32
    _close(fd);
#else
    close(fd);
#endif
    errno = saved_errno;
    return NULL;
  }
  file->fd = fd;
  return file;
}

MOONBIT_FFI_EXPORT tonyfettes_sync_file_t *
tonyfettes_sync_fs_open(moonbit_bytes_t path, int32_t access,
                        int32_t create_mode, int32_t append,
                        int32_t sync, int32_t permission) {
#ifdef _WIN32
  (void)sync;
  static int access_flags[] = {_O_RDONLY, _O_WRONLY, _O_RDWR};
  static int create_modes[] = {
      0, _O_TRUNC, _O_CREAT, _O_CREAT | _O_TRUNC, _O_CREAT | _O_EXCL,
  };
  int flags = access_flags[access] | create_modes[create_mode] | _O_BINARY;
  if (append) {
    flags |= _O_APPEND;
  }
  int fd = _open((const char *)path, flags, permission);
  if (fd < 0) {
    return NULL;
  }
  return sync_file_from_fd(fd);
#else
#ifndef O_DSYNC
#define O_DSYNC O_SYNC
#endif
  static int access_flags[] = {O_RDONLY, O_WRONLY, O_RDWR};
  static int create_modes[] = {
      0, O_TRUNC, O_CREAT, O_CREAT | O_TRUNC, O_CREAT | O_EXCL,
  };
  static int sync_flags[] = {0, O_DSYNC, O_SYNC};
  int flags =
      access_flags[access] | create_modes[create_mode] | sync_flags[sync];
  if (append) {
    flags |= O_APPEND;
  }
#ifdef O_CLOEXEC
  flags |= O_CLOEXEC;
#endif
  int fd = open((const char *)path, flags, (mode_t)permission);
  if (fd < 0) {
    return NULL;
  }
  return sync_file_from_fd(fd);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_is_null(void *ptr) {
  return ptr == NULL;
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_fclose(tonyfettes_sync_file_t *file) {
#ifdef _WIN32
  int ret = _close(file->fd);
#else
  int ret = close(file->fd);
#endif
  free(file);
  return ret;
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_fileno(tonyfettes_sync_file_t *file) {
  return file->fd;
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_fread(tonyfettes_sync_file_t *file, moonbit_bytes_t dst,
                         int32_t offset, int32_t len) {
#ifdef _WIN32
  int n = _read(file->fd, dst + offset, len);
#else
  ssize_t n = read(file->fd, dst + offset, len);
#endif
  if (n < 0) {
    return -1;
  }
  return (int32_t)n;
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_fwrite(tonyfettes_sync_file_t *file, moonbit_bytes_t src,
                          int32_t offset, int32_t len) {
#ifdef _WIN32
  int n = _write(file->fd, src + offset, len);
#else
  ssize_t n = write(file->fd, src + offset, len);
#endif
  if (n < 0) {
    return -1;
  }
  return (int32_t)n;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_fread_at(
    tonyfettes_sync_file_t *file, moonbit_bytes_t dst, int32_t offset,
    int32_t len, int64_t position) {
#ifdef _WIN32
  __int64 old_pos = _lseeki64(file->fd, 0, SEEK_CUR);
  if (old_pos < 0 || _lseeki64(file->fd, position, SEEK_SET) < 0) {
    return -1;
  }
  int32_t n = tonyfettes_sync_fs_fread(file, dst, offset, len);
  int saved_errno = errno;
  if (_lseeki64(file->fd, old_pos, SEEK_SET) < 0 && n >= 0) {
    return -1;
  }
  errno = saved_errno;
  return n;
#else
  ssize_t n = pread(file->fd, dst + offset, len, position);
  return n < 0 ? -1 : (int32_t)n;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_fwrite_at(
    tonyfettes_sync_file_t *file, moonbit_bytes_t src, int32_t offset,
    int32_t len, int64_t position) {
#ifdef _WIN32
  __int64 old_pos = _lseeki64(file->fd, 0, SEEK_CUR);
  if (old_pos < 0 || _lseeki64(file->fd, position, SEEK_SET) < 0) {
    return -1;
  }
  int32_t n = tonyfettes_sync_fs_fwrite(file, src, offset, len);
  int saved_errno = errno;
  if (_lseeki64(file->fd, old_pos, SEEK_SET) < 0 && n >= 0) {
    return -1;
  }
  errno = saved_errno;
  return n;
#else
  ssize_t n = pwrite(file->fd, src + offset, len, position);
  return n < 0 ? -1 : (int32_t)n;
#endif
}

MOONBIT_FFI_EXPORT int64_t
tonyfettes_sync_fs_file_size(tonyfettes_sync_file_t *file) {
#ifdef _WIN32
  struct _stat64 st;
  if (_fstat64(file->fd, &st) < 0) {
    return -1;
  }
  return (int64_t)st.st_size;
#else
  struct stat st;
  if (fstat(file->fd, &st) < 0) {
    return -1;
  }
  return (int64_t)st.st_size;
#endif
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_fsync(tonyfettes_sync_file_t *file, int32_t only_data) {
#ifdef _WIN32
  (void)only_data;
  return _commit(file->fd);
#else
#if defined(__APPLE__)
  (void)only_data;
  return fsync(file->fd);
#else
  return only_data ? fdatasync(file->fd) : fsync(file->fd);
#endif
#endif
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_flock(tonyfettes_sync_file_t *file, int32_t exclusive,
                         int32_t nonblock) {
#ifdef _WIN32
  OVERLAPPED overlapped;
  memset(&overlapped, 0, sizeof(OVERLAPPED));
  overlapped.Offset = 0xfffffffe;
  overlapped.OffsetHigh = 0xffffffff;
  DWORD flags = exclusive ? LOCKFILE_EXCLUSIVE_LOCK : 0;
  if (nonblock) {
    flags |= LOCKFILE_FAIL_IMMEDIATELY;
  }
  HANDLE handle = (HANDLE)_get_osfhandle(file->fd);
  return LockFileEx(handle, flags, 0, 1, 0, &overlapped) ? 0 : -1;
#else
  int op = exclusive ? LOCK_EX : LOCK_SH;
  if (nonblock) {
    op |= LOCK_NB;
  }
  return flock(file->fd, op);
#endif
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_funlock(tonyfettes_sync_file_t *file) {
#ifdef _WIN32
  OVERLAPPED overlapped;
  memset(&overlapped, 0, sizeof(OVERLAPPED));
  overlapped.Offset = 0xfffffffe;
  overlapped.OffsetHigh = 0xffffffff;
  HANDLE handle = (HANDLE)_get_osfhandle(file->fd);
  return UnlockFileEx(handle, 0, 1, 0, &overlapped) ? 0 : -1;
#else
  return flock(file->fd, LOCK_UN);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_dir_buffer_min_size(void) {
#ifdef _WIN32
  return sizeof(sync_dirent_t) + MAX_PATH * 2;
#else
  return sizeof(sync_dirent_t) + NAME_MAX;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_dir_entry_count_mode(void) {
#ifdef __APPLE__
  return 1;
#else
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_readdir(tonyfettes_sync_file_t *file, moonbit_bytes_t out,
                           int32_t len) {
#ifdef _WIN32
  HANDLE handle = (HANDLE)_get_osfhandle(file->fd);
  if (!GetFileInformationByHandleEx(handle, FileIdBothDirectoryInfo, out, len)) {
    if (GetLastError() == ERROR_NO_MORE_FILES) {
      return 0;
    }
    errno = GetLastError();
    return -1;
  }
  return len;
#elif defined(__linux__)
  int ret = syscall(SYS_getdents64, file->fd, out, len);
  return ret < 0 ? -1 : ret;
#elif defined(__APPLE__)
  struct attrlist attr_spec = {
      ATTR_BIT_MAP_COUNT,
      0,
      ATTR_CMN_NAME | ATTR_CMN_RETURNED_ATTRS | ATTR_CMN_OBJTYPE,
      0,
      0,
      0,
      0,
  };
  int ret = getattrlistbulk(file->fd, &attr_spec, out, len, 0);
  return ret < 0 ? -1 : ret;
#else
  (void)file;
  (void)out;
  (void)len;
  errno = ENOSYS;
  return -1;
#endif
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_dir_entry_length(moonbit_bytes_t buf, int32_t offset) {
  sync_dirent_t *ent = (sync_dirent_t *)(buf + offset);
#ifdef _WIN32
  return ent->NextEntryOffset;
#else
  return ent->d_reclen;
#endif
}

MOONBIT_FFI_EXPORT moonbit_bytes_t
tonyfettes_sync_fs_dir_entry_name(moonbit_bytes_t buf, int32_t offset) {
  sync_dirent_t *ent = (sync_dirent_t *)(buf + offset);
#ifdef _WIN32
  int32_t len = ent->FileNameLength;
  char *name = (char *)ent->FileName;
#elif defined(__APPLE__)
  int32_t len = ent->d_name.attr_length - 1;
  char *name = ((char *)&ent->d_name) + ent->d_name.attr_dataoffset;
#else
  int32_t len = (int32_t)strlen(ent->d_name);
  char *name = ent->d_name;
#endif
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, name, len);
  return bytes;
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_dir_entry_is_dir(moonbit_bytes_t buf, int32_t offset) {
  sync_dirent_t *ent = (sync_dirent_t *)(buf + offset);
#ifdef _WIN32
  return (ent->FileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) == 0 &&
         (ent->FileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
#elif defined(__APPLE__)
  if ((ent->d_attrs.commonattr & ATTR_CMN_OBJTYPE) == 0) {
    return -1;
  }
  switch (ent->d_type) {
  case VNON:
    return -1;
  case VDIR:
    return 1;
  default:
    return 0;
  }
#else
  switch (ent->d_type) {
  case DT_UNKNOWN:
    return -1;
  case DT_DIR:
    return 1;
  default:
    return 0;
  }
#endif
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_dir_entry_is_hidden(moonbit_bytes_t buf, int32_t offset) {
  sync_dirent_t *ent = (sync_dirent_t *)(buf + offset);
#ifdef _WIN32
  return (ent->FileAttributes & FILE_ATTRIBUTE_HIDDEN) != 0;
#elif defined(__APPLE__)
  return ((char *)&ent->d_name)[ent->d_name.attr_dataoffset] == '.';
#else
  return ent->d_name[0] == '.';
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_exists(moonbit_bytes_t path) {
  struct stat buffer;
  return stat((const char *)path, &buffer) == 0;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_mkdir(moonbit_bytes_t path,
                                                    int32_t mode) {
#ifdef _WIN32
  (void)mode;
  return _mkdir((const char *)path);
#else
  return mkdir((const char *)path, (mode_t)mode);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_rmdir(moonbit_bytes_t path) {
#ifdef _WIN32
  return _rmdir((const char *)path);
#else
  return rmdir((const char *)path);
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_remove(moonbit_bytes_t path) {
  return remove((const char *)path);
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_rename(moonbit_bytes_t old_path, moonbit_bytes_t new_path,
                          int32_t replace) {
#ifdef _WIN32
  if (!replace && tonyfettes_sync_fs_exists(new_path)) {
    errno = EEXIST;
    return -1;
  }
  return rename((const char *)old_path, (const char *)new_path);
#elif defined(__APPLE__)
  return renameatx_np(AT_FDCWD, (const char *)old_path, AT_FDCWD,
                      (const char *)new_path, replace ? 0 : RENAME_EXCL);
#elif defined(__linux__)
  return syscall(SYS_renameat2, AT_FDCWD, (const char *)old_path, AT_FDCWD,
                 (const char *)new_path, replace ? 0 : RENAME_NOREPLACE);
#else
  if (replace) {
    return rename((const char *)old_path, (const char *)new_path);
  }
  errno = ENOSYS;
  return -1;
#endif
}

static int sync_stat_follow(const char *path, int follow, struct stat *buffer) {
#ifdef _WIN32
  (void)follow;
  return stat(path, buffer);
#else
  return follow ? stat(path, buffer) : lstat(path, buffer);
#endif
}

static int32_t kind_from_mode(mode_t mode) {
#ifdef _WIN32
  if (S_ISDIR(mode)) {
    return 2;
  }
  if (S_ISREG(mode)) {
    return 1;
  }
  return 0;
#else
  if (S_ISREG(mode)) {
    return 1;
  }
  if (S_ISDIR(mode)) {
    return 2;
  }
  if (S_ISLNK(mode)) {
    return 3;
  }
  if (S_ISSOCK(mode)) {
    return 4;
  }
  if (S_ISFIFO(mode)) {
    return 5;
  }
  if (S_ISBLK(mode)) {
    return 6;
  }
  if (S_ISCHR(mode)) {
    return 7;
  }
  return 0;
#endif
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_file_kind(tonyfettes_sync_file_t *file) {
#ifdef _WIN32
  struct _stat64 st;
  if (_fstat64(file->fd, &st) < 0) {
    return 0;
  }
#else
  struct stat st;
  if (fstat(file->fd, &st) < 0) {
    return 0;
  }
#endif
  return kind_from_mode(st.st_mode);
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_kind(moonbit_bytes_t path,
                                                   int32_t follow_symlink) {
  struct stat buffer;
  if (sync_stat_follow((const char *)path, follow_symlink, &buffer) != 0) {
    return -1;
  }
  return kind_from_mode(buffer.st_mode);
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_kind_at(tonyfettes_sync_file_t *file, moonbit_bytes_t name,
                           int32_t follow_symlink) {
#ifdef _WIN32
  (void)file;
  (void)name;
  (void)follow_symlink;
  errno = ENOSYS;
  return -1;
#else
  struct stat buffer;
  if (fstatat(file->fd, (const char *)name, &buffer,
              follow_symlink ? 0 : AT_SYMLINK_NOFOLLOW) != 0) {
    return -1;
  }
  return kind_from_mode(buffer.st_mode);
#endif
}

static int64_t last_atime_sec;
static int32_t last_atime_nsec;
static int64_t last_mtime_sec;
static int32_t last_mtime_nsec;
static int64_t last_ctime_sec;
static int32_t last_ctime_nsec;

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_stat_times(moonbit_bytes_t path, int32_t follow_symlink) {
  struct stat buffer;
  if (sync_stat_follow((const char *)path, follow_symlink, &buffer) != 0) {
    return -1;
  }
#if defined(__APPLE__)
  last_atime_sec = (int64_t)buffer.st_atimespec.tv_sec;
  last_atime_nsec = (int32_t)buffer.st_atimespec.tv_nsec;
  last_mtime_sec = (int64_t)buffer.st_mtimespec.tv_sec;
  last_mtime_nsec = (int32_t)buffer.st_mtimespec.tv_nsec;
  last_ctime_sec = (int64_t)buffer.st_ctimespec.tv_sec;
  last_ctime_nsec = (int32_t)buffer.st_ctimespec.tv_nsec;
#elif defined(_WIN32)
  last_atime_sec = (int64_t)buffer.st_atime;
  last_atime_nsec = 0;
  last_mtime_sec = (int64_t)buffer.st_mtime;
  last_mtime_nsec = 0;
  last_ctime_sec = (int64_t)buffer.st_ctime;
  last_ctime_nsec = 0;
#else
  last_atime_sec = (int64_t)buffer.st_atim.tv_sec;
  last_atime_nsec = (int32_t)buffer.st_atim.tv_nsec;
  last_mtime_sec = (int64_t)buffer.st_mtim.tv_sec;
  last_mtime_nsec = (int32_t)buffer.st_mtim.tv_nsec;
  last_ctime_sec = (int64_t)buffer.st_ctim.tv_sec;
  last_ctime_nsec = (int32_t)buffer.st_ctim.tv_nsec;
#endif
  return 0;
}

MOONBIT_FFI_EXPORT int64_t tonyfettes_sync_fs_atime_sec(void) {
  return last_atime_sec;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_atime_nsec(void) {
  return last_atime_nsec;
}

MOONBIT_FFI_EXPORT int64_t tonyfettes_sync_fs_mtime_sec(void) {
  return last_mtime_sec;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_mtime_nsec(void) {
  return last_mtime_nsec;
}

MOONBIT_FFI_EXPORT int64_t tonyfettes_sync_fs_ctime_sec(void) {
  return last_ctime_sec;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_ctime_nsec(void) {
  return last_ctime_nsec;
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_access(moonbit_bytes_t path,
                                                     int32_t mode) {
#ifdef _WIN32
  return _access((const char *)path, mode) == 0;
#else
  return access((const char *)path, mode) == 0;
#endif
}

MOONBIT_FFI_EXPORT moonbit_bytes_t
tonyfettes_sync_fs_realpath(moonbit_bytes_t path) {
#ifdef _WIN32
  char buffer[MAX_PATH];
  DWORD len = GetFullPathName((const char *)path, MAX_PATH, buffer, NULL);
  if (len == 0 || len >= MAX_PATH) {
    errno = ENOENT;
    return moonbit_make_bytes(0, 0);
  }
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, buffer, len);
  return bytes;
#else
  char *resolved = realpath((const char *)path, NULL);
  if (resolved == NULL) {
    return moonbit_make_bytes(0, 0);
  }
  size_t len = strlen(resolved);
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, resolved, len);
  free(resolved);
  return bytes;
#endif
}

MOONBIT_FFI_EXPORT int32_t tonyfettes_sync_fs_chmod(moonbit_bytes_t path,
                                                    int32_t mode) {
#ifdef _WIN32
  return _chmod((const char *)path, mode);
#else
  return chmod((const char *)path, (mode_t)mode);
#endif
}

MOONBIT_FFI_EXPORT int32_t
tonyfettes_sync_fs_symlink(moonbit_bytes_t target, moonbit_bytes_t path) {
#ifdef _WIN32
  DWORD flags = 0;
  DWORD attrs = GetFileAttributes((const char *)target);
  if (attrs != INVALID_FILE_ATTRIBUTES && (attrs & FILE_ATTRIBUTE_DIRECTORY)) {
    flags |= SYMBOLIC_LINK_FLAG_DIRECTORY;
  }
  return CreateSymbolicLink((const char *)path, (const char *)target, flags)
             ? 0
             : -1;
#else
  return symlink((const char *)target, (const char *)path);
#endif
}

MOONBIT_FFI_EXPORT moonbit_bytes_t
tonyfettes_sync_fs_tmpdir(moonbit_bytes_t prefix) {
#ifdef _WIN32
  char base[MAX_PATH];
  DWORD base_len = GetTempPath(MAX_PATH, base);
  if (base_len == 0 || base_len >= MAX_PATH) {
    errno = ENOENT;
    return moonbit_make_bytes(0, 0);
  }
  char path[MAX_PATH];
  snprintf(path, sizeof(path), "%s%s.%lu.XXXXXX", base, (const char *)prefix,
           (unsigned long)GetCurrentProcessId());
  if (_mktemp(path) == NULL || _mkdir(path) != 0) {
    return moonbit_make_bytes(0, 0);
  }
  size_t len = strlen(path);
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, path, len);
  return bytes;
#else
  const char *base = getenv("TMPDIR");
  if (base == NULL || base[0] == '\0') {
    base = "/tmp";
  }
  char templ[PATH_MAX];
  const char *sep = base[strlen(base) - 1] == '/' ? "" : "/";
  snprintf(templ, sizeof(templ), "%s%s%s.XXXXXX", base, sep,
           (const char *)prefix);
  char *created = mkdtemp(templ);
  if (created == NULL) {
    return moonbit_make_bytes(0, 0);
  }
  size_t len = strlen(created);
  moonbit_bytes_t bytes = moonbit_make_bytes(len, 0);
  memcpy(bytes, created, len);
  return bytes;
#endif
}

#ifdef __cplusplus
}
#endif
