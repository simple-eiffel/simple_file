note
	description: "[
		Win32 primitives behind SIMPLE_FILE and SIMPLE_FILES: the atomic
		replacing write (temp file in the same folder, FlushFileBuffers,
		MoveFileExW with MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH),
		appends, whole-file reads, 100 ns modification times and one-pass
		directory enumeration (FindFirstFileExW, FindExInfoBasic,
		FIND_FIRST_EX_LARGE_FETCH).

		Every routine takes and returns plain C data (wide paths from
		NATIVE_STRING, buffers from MANAGED_POINTER) and reports failure as a
		Win32 error code, never by raising. Each external that can wait on the
		disk or the network is declared `C blocking inline' so ISE's garbage
		collector can run on the other threads while it waits; those
		routines never touch an Eiffel object, which may move meanwhile.
		Accessors of a buffer already in memory are left unmarked.

		ReplaceFileW is deliberately absent: the debate spikes (RQ-06, D18)
		showed it destroying outside edits that land during the call, at
		times while returning success.

		Implementation support for this library; its features are public
		so the tests can prepare fixtures (folder attributes), but they are
		not part of the stable API.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_FILE_WIN32

feature -- Constants

	Error_file_exists: INTEGER = 80
			-- ERROR_FILE_EXISTS.

	Error_already_exists: INTEGER = 183
			-- ERROR_ALREADY_EXISTS.

	Error_file_not_found: INTEGER = 2
			-- ERROR_FILE_NOT_FOUND.

	Error_no_more_files: INTEGER = 18
			-- ERROR_NO_MORE_FILES.

	Error_short_write: INTEGER = 0xFFFF
			-- Reported when WriteFile wrote fewer bytes than asked without an OS error.

	Attribute_readonly: NATURAL_32 = 0x1
			-- FILE_ATTRIBUTE_READONLY.

	Attribute_directory: NATURAL_32 = 0x10
			-- FILE_ATTRIBUTE_DIRECTORY.

feature -- Writing

	write_new_file (a_path, a_data: POINTER; a_count: INTEGER; a_like_path: POINTER): INTEGER
			-- Create `a_path' (which must not exist: CREATE_NEW), write `a_count'
			-- bytes from `a_data', FlushFileBuffers and close. If `a_like_path' is
			-- not null and names an existing file, the new file takes its HIDDEN,
			-- SYSTEM, ARCHIVE and NOT_CONTENT_INDEXED attributes. On any failure
			-- after creation the new file is deleted. Returns 0 or a Win32 error.
		require
			path_exists: a_path /= default_pointer
			count_non_negative: a_count >= 0
			data_for_count: a_count > 0 implies a_data /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"[
				DWORD l_attr = FILE_ATTRIBUTE_NORMAL;
				DWORD l_like = INVALID_FILE_ATTRIBUTES;
				HANDLE h;
				DWORD l_done = 0;
				DWORD l_err = 0;
				const char *l_p = (const char *) $a_data;
				DWORD l_left = (DWORD) $a_count;
				if ($a_like_path != NULL) {
					l_like = GetFileAttributesW ((LPCWSTR) $a_like_path);
					if (l_like != INVALID_FILE_ATTRIBUTES && !(l_like & FILE_ATTRIBUTE_DIRECTORY)) {
						l_like &= (FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM | FILE_ATTRIBUTE_ARCHIVE | FILE_ATTRIBUTE_NOT_CONTENT_INDEXED);
						if (l_like != 0) l_attr = l_like;
					}
				}
				h = CreateFileW ((LPCWSTR) $a_path, GENERIC_WRITE, 0, NULL, CREATE_NEW, l_attr, NULL);
				if (h == INVALID_HANDLE_VALUE) return (EIF_INTEGER) GetLastError ();
				while (l_left > 0) {
					if (!WriteFile (h, l_p, l_left, &l_done, NULL)) { l_err = GetLastError (); break; }
					if (l_done == 0) { l_err = 0xFFFF; break; }
					l_p += l_done;
					l_left -= l_done;
				}
				if (l_err == 0 && !FlushFileBuffers (h)) l_err = GetLastError ();
				if (!CloseHandle (h) && l_err == 0) l_err = GetLastError ();
				if (l_err != 0) DeleteFileW ((LPCWSTR) $a_path);
				return (EIF_INTEGER) l_err;
			]"
		end

	move_replace (a_source, a_target: POINTER): INTEGER
			-- MoveFileExW (`a_source', `a_target', MOVEFILE_REPLACE_EXISTING |
			-- MOVEFILE_WRITE_THROUGH). Returns 0 or a Win32 error.
		require
			source_exists: a_source /= default_pointer
			target_exists: a_target /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"return MoveFileExW ((LPCWSTR) $a_source, (LPCWSTR) $a_target, MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) ? 0 : (EIF_INTEGER) GetLastError ();"
		end

	append_to_file (a_path, a_data: POINTER; a_count: INTEGER): INTEGER
			-- Open or create `a_path' for appending (OPEN_ALWAYS, FILE_APPEND_DATA,
			-- sharing read and write as the C runtime's "a" mode does), write
			-- `a_count' bytes from `a_data' at the end, close. Not atomic.
			-- Returns 0 or a Win32 error.
		require
			path_exists: a_path /= default_pointer
			count_non_negative: a_count >= 0
			data_for_count: a_count > 0 implies a_data /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"[
				HANDLE h;
				DWORD l_done = 0;
				DWORD l_err = 0;
				const char *l_p = (const char *) $a_data;
				DWORD l_left = (DWORD) $a_count;
				h = CreateFileW ((LPCWSTR) $a_path, FILE_APPEND_DATA | SYNCHRONIZE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
				if (h == INVALID_HANDLE_VALUE) return (EIF_INTEGER) GetLastError ();
				while (l_left > 0) {
					if (!WriteFile (h, l_p, l_left, &l_done, NULL)) { l_err = GetLastError (); break; }
					if (l_done == 0) { l_err = 0xFFFF; break; }
					l_p += l_done;
					l_left -= l_done;
				}
				if (!CloseHandle (h) && l_err == 0) l_err = GetLastError ();
				return (EIF_INTEGER) l_err;
			]"
		end

	delete_file (a_path: POINTER): INTEGER
			-- DeleteFileW. Returns 0 or a Win32 error.
		require
			path_exists: a_path /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"return DeleteFileW ((LPCWSTR) $a_path) ? 0 : (EIF_INTEGER) GetLastError ();"
		end

feature -- Reading

	open_for_read (a_path, a_error: POINTER): POINTER
			-- CreateFileW (GENERIC_READ, sharing read, write and delete,
			-- OPEN_EXISTING). Null on failure, with the Win32 error stored as a
			-- 32-bit integer at `a_error'.
		require
			path_exists: a_path /= default_pointer
			error_exists: a_error /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"[
				HANDLE h = CreateFileW ((LPCWSTR) $a_path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
				if (h == INVALID_HANDLE_VALUE) { *((EIF_INTEGER *) $a_error) = (EIF_INTEGER) GetLastError (); return NULL; }
				*((EIF_INTEGER *) $a_error) = 0;
				return (EIF_POINTER) h;
			]"
		end

	read_chunk (a_handle, a_buffer: POINTER; a_capacity: INTEGER): INTEGER
			-- ReadFile up to `a_capacity' bytes into `a_buffer'. Returns the
			-- number read (0 at end of file) or minus a Win32 error.
		require
			handle_exists: a_handle /= default_pointer
			buffer_exists: a_buffer /= default_pointer
			capacity_positive: a_capacity > 0
		external
			"C blocking inline use <windows.h>"
		alias
			"[
				DWORD l_done = 0;
				if (!ReadFile ((HANDLE) $a_handle, $a_buffer, (DWORD) $a_capacity, &l_done, NULL)) return -(EIF_INTEGER) GetLastError ();
				return (EIF_INTEGER) l_done;
			]"
		end

	close_handle (a_handle: POINTER)
			-- CloseHandle on a handle opened for reading.
		require
			handle_exists: a_handle /= default_pointer
		external
			"C inline use <windows.h>"
		alias
			"CloseHandle ((HANDLE) $a_handle);"
		end

feature -- Status

	attributes (a_path: POINTER): INTEGER_64
			-- GetFileAttributesW, or -1 on failure.
		require
			path_exists: a_path /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"[
				DWORD a = GetFileAttributesW ((LPCWSTR) $a_path);
				return (a == INVALID_FILE_ATTRIBUTES) ? (EIF_INTEGER_64) -1 : (EIF_INTEGER_64) a;
			]"
		end

	set_attributes (a_path: POINTER; a_attributes: NATURAL_32): INTEGER
			-- SetFileAttributesW. Returns 0 or a Win32 error.
		require
			path_exists: a_path /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"return SetFileAttributesW ((LPCWSTR) $a_path, (DWORD) $a_attributes) ? 0 : (EIF_INTEGER) GetLastError ();"
		end

	last_write_100ns (a_path: POINTER): INTEGER_64
			-- ftLastWriteTime of `a_path' as 100 ns ticks since 1601-01-01 UTC
			-- (a Windows FILETIME), or -1 on failure.
		require
			path_exists: a_path /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"[
				WIN32_FILE_ATTRIBUTE_DATA d;
				if (!GetFileAttributesExW ((LPCWSTR) $a_path, GetFileExInfoStandard, &d)) return (EIF_INTEGER_64) -1;
				return (EIF_INTEGER_64) ((((unsigned __int64) d.ftLastWriteTime.dwHighDateTime) << 32) | d.ftLastWriteTime.dwLowDateTime);
			]"
		end

feature -- Enumeration

	find_data_size: INTEGER
			-- sizeof (WIN32_FIND_DATAW).
		external
			"C inline use <windows.h>"
		alias
			"return (EIF_INTEGER) sizeof (WIN32_FIND_DATAW);"
		end

	find_first (a_pattern, a_data, a_error: POINTER): POINTER
			-- FindFirstFileExW (`a_pattern', FindExInfoBasic, FindExSearchNameMatch,
			-- FIND_FIRST_EX_LARGE_FETCH) filling `a_data'. Null on failure, with the
			-- Win32 error stored as a 32-bit integer at `a_error'.
		require
			pattern_exists: a_pattern /= default_pointer
			data_exists: a_data /= default_pointer
			error_exists: a_error /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"[
				#ifndef FIND_FIRST_EX_LARGE_FETCH
				#define FIND_FIRST_EX_LARGE_FETCH 2
				#endif
				HANDLE h = FindFirstFileExW ((LPCWSTR) $a_pattern, FindExInfoBasic, (LPWIN32_FIND_DATAW) $a_data, FindExSearchNameMatch, NULL, FIND_FIRST_EX_LARGE_FETCH);
				if (h == INVALID_HANDLE_VALUE) { *((EIF_INTEGER *) $a_error) = (EIF_INTEGER) GetLastError (); return NULL; }
				*((EIF_INTEGER *) $a_error) = 0;
				return (EIF_POINTER) h;
			]"
		end

	find_next (a_handle, a_data, a_error: POINTER): BOOLEAN
			-- FindNextFileW. False at the end or on failure, with the Win32 error
			-- (ERROR_NO_MORE_FILES at the end) stored at `a_error'.
		require
			handle_exists: a_handle /= default_pointer
			data_exists: a_data /= default_pointer
			error_exists: a_error /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"[
				if (FindNextFileW ((HANDLE) $a_handle, (LPWIN32_FIND_DATAW) $a_data)) { *((EIF_INTEGER *) $a_error) = 0; return EIF_TRUE; }
				*((EIF_INTEGER *) $a_error) = (EIF_INTEGER) GetLastError ();
				return EIF_FALSE;
			]"
		end

	find_close (a_handle: POINTER)
			-- FindClose.
		require
			handle_exists: a_handle /= default_pointer
		external
			"C inline use <windows.h>"
		alias
			"FindClose ((HANDLE) $a_handle);"
		end

	find_data_name (a_data: POINTER): POINTER
			-- Address of the null-terminated cFileName inside `a_data'.
		require
			data_exists: a_data /= default_pointer
		external
			"C inline use <windows.h>"
		alias
			"return (EIF_POINTER) ((LPWIN32_FIND_DATAW) $a_data)->cFileName;"
		end

	find_data_attributes (a_data: POINTER): NATURAL_32
			-- dwFileAttributes of `a_data'.
		require
			data_exists: a_data /= default_pointer
		external
			"C inline use <windows.h>"
		alias
			"return (EIF_NATURAL_32) ((LPWIN32_FIND_DATAW) $a_data)->dwFileAttributes;"
		end

feature -- Process and errors

	current_process_id: NATURAL_32
			-- GetCurrentProcessId.
		external
			"C inline use <windows.h>"
		alias
			"return (EIF_NATURAL_32) GetCurrentProcessId ();"
		end

	is_owner_running (a_pid: NATURAL_32; a_file: POINTER): BOOLEAN
			-- Is process `a_pid' running and older than file `a_file', so that
			-- it may be the process that created it? A process started after
			-- the file was created reuses the id of a dead owner and does not
			-- count. One that exists but may not be queried counts as running.
		require
			file_exists: a_file /= default_pointer
		external
			"C blocking inline use <windows.h>"
		alias
			"[
				#ifndef PROCESS_QUERY_LIMITED_INFORMATION
				#define PROCESS_QUERY_LIMITED_INFORMATION 0x1000
				#endif
				DWORD l_code = 0;
				FILETIME l_created, l_exited, l_kernel, l_user;
				WIN32_FILE_ATTRIBUTE_DATA d;
				EIF_BOOLEAN l_result = EIF_TRUE;
				HANDLE h = OpenProcess (PROCESS_QUERY_LIMITED_INFORMATION, FALSE, (DWORD) $a_pid);
				if (h == NULL) return (GetLastError () == ERROR_ACCESS_DENIED) ? EIF_TRUE : EIF_FALSE;
				if (GetExitCodeProcess (h, &l_code) && l_code != STILL_ACTIVE) {
					l_result = EIF_FALSE;
				} else if (GetProcessTimes (h, &l_created, &l_exited, &l_kernel, &l_user) && GetFileAttributesExW ((LPCWSTR) $a_file, GetFileExInfoStandard, &d)) {
					if (CompareFileTime (&l_created, &d.ftCreationTime) > 0) l_result = EIF_FALSE;
				}
				CloseHandle (h);
				return l_result;
			]"
		end

	performance_counter: INTEGER_64
			-- QueryPerformanceCounter, used to vary temporary names.
		external
			"C inline use <windows.h>"
		alias
			"[
				LARGE_INTEGER c;
				QueryPerformanceCounter (&c);
				return (EIF_INTEGER_64) c.QuadPart;
			]"
		end

	format_message (a_code: INTEGER; a_buffer: POINTER; a_capacity: INTEGER): INTEGER
			-- FormatMessageW text of Win32 error `a_code' into `a_buffer' (room for
			-- `a_capacity' wide characters), trailing line breaks and period removed.
			-- Returns the number of wide characters written (0 if none known).
		require
			buffer_exists: a_buffer /= default_pointer
			capacity_positive: a_capacity > 1
		external
			"C inline use <windows.h>"
		alias
			"[
				WCHAR *b = (WCHAR *) $a_buffer;
				DWORD n = FormatMessageW (FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS, NULL, (DWORD) $a_code, 0, b, (DWORD) $a_capacity, NULL);
				while (n > 0 && (b [n - 1] == L'\r' || b [n - 1] == L'\n' || b [n - 1] == L' ' || b [n - 1] == L'.')) n--;
				b [n] = 0;
				return (EIF_INTEGER) n;
			]"
		end

	error_text (a_code: INTEGER): STRING_32
			-- "<system message> (Win32 error `a_code')".
		local
			l_buffer: MANAGED_POINTER
			l_count: INTEGER
		do
			create l_buffer.make (1024)
			l_count := format_message (a_code, l_buffer.item, 512)
			if l_count > 0 then
				Result := (create {NATIVE_STRING}.make_from_pointer (l_buffer.item)).string
				Result.append ({STRING_32} " ")
			else
				create Result.make_empty
			end
			Result.append ({STRING_32} "(Win32 error ")
			Result.append (a_code.out)
			Result.append_character (')')
		ensure
			names_code: Result.has_substring (a_code.out)
		end

note
	copyright: "Copyright (c) 2024-2026, Larry Rix"
	license: "MIT License"

end
