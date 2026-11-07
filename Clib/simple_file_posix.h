/*
 * simple_file_posix.h - POSIX primitives behind SIMPLE_FILE and SIMPLE_FILES.
 *
 * The counterpart of the Win32 calls in platform/windows. Paths arrive from
 * NATIVE_STRING as UTF-8. Failures are returned as errno values, never raised.
 *
 * Durability matches the Windows path: data is flushed before the rename, and
 * the folder entry is flushed after it. On macOS fsync reaches the drive but
 * not its cache, so F_FULLFSYNC is used where the file system supports it.
 */
#ifndef SIMPLE_FILE_POSIX_H
#define SIMPLE_FILE_POSIX_H

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <signal.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#define SFP_SHORT_WRITE 0xFFFF
#define SFP_NO_MORE_FILES 0xFFFE
#define SFP_ATTR_READONLY 0x1u
#define SFP_ATTR_HIDDEN 0x2u
#define SFP_ATTR_DIRECTORY 0x10u
#define SFP_ATTR_NORMAL 0x80u

/* A descriptor can be 0, so a handle is descriptor + 1 and NULL can mean failure. */
#define SFP_HANDLE(fd) ((void *) (intptr_t) ((fd) + 1))
#define SFP_FD(h) ((int) ((intptr_t) (h) - 1))

typedef struct {
	char name [NAME_MAX + 1];
	unsigned int attributes;
} sfp_find_data;

typedef struct {
	DIR *dir;
} sfp_find_handle;

static int sfp_flush (int fd)
{
#ifdef __APPLE__
	if (fcntl (fd, F_FULLFSYNC) == 0) return 0;
	/* Network and some other file systems refuse F_FULLFSYNC. */
#endif
	return (fsync (fd) == 0) ? 0 : errno;
}

static int sfp_write_all (int fd, const char *a_data, int a_count)
{
	size_t left = (size_t) a_count;
	while (left > 0) {
		ssize_t done = write (fd, a_data, left);
		if (done < 0) {
			if (errno == EINTR) continue;
			return errno;
		}
		if (done == 0) return SFP_SHORT_WRITE;
		a_data += done;
		left -= (size_t) done;
	}
	return 0;
}

static int sfp_write_new_file (const char *a_path, const char *a_data, int a_count, const char *a_like)
{
	struct stat like;
	mode_t mode = 0666;
	int use_like = 0;
	int err = 0;
	int fd;

	if (a_like != NULL && stat (a_like, &like) == 0 && S_ISREG (like.st_mode)) {
		mode = like.st_mode & 07777;
		use_like = 1;
	}
	do {
		fd = open (a_path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, mode);
	} while (fd < 0 && errno == EINTR);
	if (fd < 0) return errno;

	/* open applied the umask; a replacement keeps the original's exact mode. */
	if (use_like && fchmod (fd, mode) != 0) err = errno;
	if (err == 0) err = sfp_write_all (fd, a_data, a_count);
	if (err == 0) err = sfp_flush (fd);
	if (close (fd) != 0 && err == 0) err = errno;
	if (err != 0) unlink (a_path);
	return err;
}

static void sfp_flush_parent (const char *a_path)
{
	/* Best effort: the rename has already succeeded. */
	const char *slash = strrchr (a_path, '/');
	size_t length = (slash == NULL) ? 0 : (size_t) (slash - a_path);
	char *folder;
	int fd;

	if (slash == NULL) {
		fd = open (".", O_RDONLY | O_CLOEXEC);
	} else {
		if (length == 0) length = 1; /* the root folder */
		folder = (char *) malloc (length + 1);
		if (folder == NULL) return;
		memcpy (folder, a_path, length);
		folder [length] = '\0';
		fd = open (folder, O_RDONLY | O_CLOEXEC);
		free (folder);
	}
	if (fd >= 0) {
		(void) sfp_flush (fd);
		close (fd);
	}
}

static int sfp_move_replace (const char *a_source, const char *a_target)
{
	if (rename (a_source, a_target) != 0) return errno;
	sfp_flush_parent (a_target);
	return 0;
}

static int sfp_append (const char *a_path, const char *a_data, int a_count)
{
	int err;
	int fd;
	do {
		fd = open (a_path, O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, 0666);
	} while (fd < 0 && errno == EINTR);
	if (fd < 0) return errno;
	err = sfp_write_all (fd, a_data, a_count);
	if (close (fd) != 0 && err == 0) err = errno;
	return err;
}

static int sfp_delete (const char *a_path)
{
	return (unlink (a_path) == 0) ? 0 : errno;
}

static void *sfp_open_read (const char *a_path, int *a_error)
{
	struct stat st;
	int fd;
	do {
		fd = open (a_path, O_RDONLY | O_CLOEXEC);
	} while (fd < 0 && errno == EINTR);
	if (fd < 0) { *a_error = errno; return NULL; }
	/* Opening a folder fails on Windows; keep that outcome here. */
	if (fstat (fd, &st) == 0 && S_ISDIR (st.st_mode)) {
		close (fd);
		*a_error = EISDIR;
		return NULL;
	}
	*a_error = 0;
	return SFP_HANDLE (fd);
}

static int sfp_read (void *a_handle, void *a_buffer, int a_capacity)
{
	ssize_t got;
	do {
		got = read (SFP_FD (a_handle), a_buffer, (size_t) a_capacity);
	} while (got < 0 && errno == EINTR);
	return (got < 0) ? -errno : (int) got;
}

static void sfp_close (void *a_handle)
{
	close (SFP_FD (a_handle));
}

static long long sfp_attributes (const char *a_path)
{
	struct stat st;
	const char *base = strrchr (a_path, '/');
	unsigned int result = 0;

	if (stat (a_path, &st) != 0) return -1;
	base = (base == NULL) ? a_path : base + 1;
	if (S_ISDIR (st.st_mode)) result |= SFP_ATTR_DIRECTORY;
	if ((st.st_mode & 0222) == 0) result |= SFP_ATTR_READONLY;
	if (base [0] == '.' && base [1] != '\0' && strcmp (base, "..") != 0) result |= SFP_ATTR_HIDDEN;
	if (result == 0) result = SFP_ATTR_NORMAL;
	return (long long) result;
}

static int sfp_set_attributes (const char *a_path, unsigned int a_attributes)
{
	/* Only read-only has a POSIX meaning here. */
	struct stat st;
	mode_t mode;
	if (stat (a_path, &st) != 0) return errno;
	mode = st.st_mode & 07777;
	mode = (a_attributes & SFP_ATTR_READONLY) ? (mode & ~((mode_t) 0222)) : (mode | S_IWUSR);
	return (chmod (a_path, mode) == 0) ? 0 : errno;
}

static long long sfp_last_write_100ns (const char *a_path)
{
	struct stat st;
	long long seconds;
	long long nanoseconds;
	if (stat (a_path, &st) != 0) return -1;
#ifdef __APPLE__
	seconds = (long long) st.st_mtimespec.tv_sec;
	nanoseconds = (long long) st.st_mtimespec.tv_nsec;
#else
	seconds = (long long) st.st_mtim.tv_sec;
	nanoseconds = (long long) st.st_mtim.tv_nsec;
#endif
	/* 11644473600 seconds separate 1601-01-01 from 1970-01-01. */
	return (seconds + 11644473600LL) * 10000000LL + nanoseconds / 100;
}

static void sfp_fill_find_data (DIR *a_dir, struct dirent *a_entry, sfp_find_data *a_data)
{
	struct stat st;
	size_t length = strlen (a_entry->d_name);
	unsigned int is_folder = 0;

	if (length > NAME_MAX) length = NAME_MAX;
	memcpy (a_data->name, a_entry->d_name, length);
	a_data->name [length] = '\0';

#ifdef DT_DIR
	if (a_entry->d_type == DT_DIR) {
		is_folder = 1;
	} else if (a_entry->d_type == DT_LNK || a_entry->d_type == DT_UNKNOWN) {
		/* A link to a folder lists as a folder, as a Windows folder link does. */
		is_folder = (fstatat (dirfd (a_dir), a_entry->d_name, &st, 0) == 0) && S_ISDIR (st.st_mode);
	}
#else
	is_folder = (fstatat (dirfd (a_dir), a_entry->d_name, &st, 0) == 0) && S_ISDIR (st.st_mode);
#endif
	a_data->attributes = is_folder ? SFP_ATTR_DIRECTORY : SFP_ATTR_NORMAL;
}

static int sfp_find_next (void *a_handle, void *a_data, int *a_error)
{
	sfp_find_handle *h = (sfp_find_handle *) a_handle;
	struct dirent *entry;
	errno = 0;
	entry = readdir (h->dir);
	if (entry == NULL) {
		*a_error = (errno == 0) ? SFP_NO_MORE_FILES : errno;
		return 0;
	}
	sfp_fill_find_data (h->dir, entry, (sfp_find_data *) a_data);
	*a_error = 0;
	return 1;
}

static void sfp_find_close (void *a_handle)
{
	sfp_find_handle *h = (sfp_find_handle *) a_handle;
	closedir (h->dir);
	free (h);
}

static void *sfp_find_first (const char *a_directory, void *a_data, int *a_error)
{
	sfp_find_handle *h;
	DIR *dir = opendir (a_directory);
	if (dir == NULL) { *a_error = errno; return NULL; }
	h = (sfp_find_handle *) malloc (sizeof (sfp_find_handle));
	if (h == NULL) { closedir (dir); *a_error = ENOMEM; return NULL; }
	h->dir = dir;
	if (!sfp_find_next (h, a_data, a_error)) {
		/* Even an empty folder lists "." and "..", so this is a real failure. */
		sfp_find_close (h);
		return NULL;
	}
	return h;
}

static int sfp_read_block (const char *a_path, void *a_dest, long long a_offset, int a_count)
{
	FILE *f = fopen (a_path, "rb");
	size_t n;
	if (f == NULL) return -1;
	if (fseeko (f, (off_t) a_offset, SEEK_SET) != 0) { fclose (f); return -2; }
	n = fread (a_dest, 1, (size_t) a_count, f);
	fclose (f);
	return (int) n;
}

static int sfp_write_block (const char *a_path, const void *a_source, int a_count, int a_append)
{
	FILE *f = fopen (a_path, a_append ? "ab" : "wb");
	size_t n;
	if (f == NULL) return -1;
	n = fwrite (a_source, 1, (size_t) a_count, f);
	if (fclose (f) != 0) return -1;
	return (int) n;
}

static int sfp_is_process_running (unsigned int a_pid)
{
	/* A process that exists but may not be signalled counts as running. */
	if (kill ((pid_t) a_pid, 0) == 0) return 1;
	return errno == EPERM;
}

static long long sfp_counter (void)
{
	struct timespec ts;
	clock_gettime (CLOCK_MONOTONIC, &ts);
	return (long long) ts.tv_sec * 1000000000LL + (long long) ts.tv_nsec;
}

#endif /* SIMPLE_FILE_POSIX_H */
