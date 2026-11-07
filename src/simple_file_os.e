note
	description: "[
		Operating system primitives behind SIMPLE_FILE and SIMPLE_FILES: the
		atomic replacing write, appends, whole-file reads, 100 ns modification
		times and one-pass directory enumeration.

		Every routine takes and returns plain C data (paths from NATIVE_STRING,
		buffers from MANAGED_POINTER) and reports failure as an operating system
		error code, never by raising.

		SIMPLE_FILE_PRIMITIVES is the effective class. One exists per platform,
		in platform/windows and platform/posix, and the ECF selects it at compile
		time, so no platform's system headers reach another platform's build.

		Implementation support for this library; its features are public
		so the tests can prepare fixtures, but they are not part of the stable API.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIMPLE_FILE_OS

feature -- Constants

	Error_file_exists: INTEGER
			-- Code for a file that already exists.
		deferred
		end

	Error_already_exists: INTEGER
			-- Code for an entry that already exists.
		deferred
		end

	Error_file_not_found: INTEGER
			-- Code for a file that does not exist.
		deferred
		end

	Error_no_more_files: INTEGER
			-- Code left by `find_next' at the end of a listing.
		deferred
		end

	Error_short_write: INTEGER
			-- Code for a write that wrote fewer bytes than asked without an OS error.
		deferred
		end

	Attribute_readonly: NATURAL_32
			-- Attribute bit of a read-only entry.
		deferred
		end

	Attribute_directory: NATURAL_32
			-- Attribute bit of a directory.
		deferred
		end

feature -- Writing

	write_new_file (a_path, a_data: POINTER; a_count: INTEGER; a_like_path: POINTER): INTEGER
			-- Create `a_path', which must not exist, write `a_count' bytes from
			-- `a_data', flush to the device and close. If `a_like_path' is not null
			-- and names an existing file, the new file takes its attributes or mode.
			-- On any failure after creation the new file is deleted.
			-- Returns 0 or an OS error.
		require
			path_exists: a_path /= default_pointer
			count_non_negative: a_count >= 0
			data_for_count: a_count > 0 implies a_data /= default_pointer
		deferred
		end

	move_replace (a_source, a_target: POINTER): INTEGER
			-- Atomically replace `a_target' with `a_source', flushed through to the
			-- device. Returns 0 or an OS error.
		require
			source_exists: a_source /= default_pointer
			target_exists: a_target /= default_pointer
		deferred
		end

	append_to_file (a_path, a_data: POINTER; a_count: INTEGER): INTEGER
			-- Open or create `a_path' for appending, write `a_count' bytes from
			-- `a_data' at the end, close. Not atomic. Returns 0 or an OS error.
		require
			path_exists: a_path /= default_pointer
			count_non_negative: a_count >= 0
			data_for_count: a_count > 0 implies a_data /= default_pointer
		deferred
		end

	delete_file (a_path: POINTER): INTEGER
			-- Delete the file at `a_path'. Returns 0 or an OS error.
		require
			path_exists: a_path /= default_pointer
		deferred
		end

feature -- Reading

	open_for_read (a_path, a_error: POINTER): POINTER
			-- Handle on the existing file `a_path' opened for reading. Null on
			-- failure, with the OS error stored as a 32-bit integer at `a_error'.
		require
			path_exists: a_path /= default_pointer
			error_exists: a_error /= default_pointer
		deferred
		end

	read_chunk (a_handle, a_buffer: POINTER; a_capacity: INTEGER): INTEGER
			-- Read up to `a_capacity' bytes into `a_buffer'. Returns the number
			-- read (0 at end of file) or minus an OS error.
		require
			handle_exists: a_handle /= default_pointer
			buffer_exists: a_buffer /= default_pointer
			capacity_positive: a_capacity > 0
		deferred
		end

	close_handle (a_handle: POINTER)
			-- Close `a_handle'.
		require
			handle_exists: a_handle /= default_pointer
		deferred
		end

feature -- Status

	attributes (a_path: POINTER): INTEGER_64
			-- Attribute bits of `a_path', or -1 on failure.
		require
			path_exists: a_path /= default_pointer
		deferred
		end

	set_attributes (a_path: POINTER; a_attributes: NATURAL_32): INTEGER
			-- Set the attributes of `a_path'. Returns 0 or an OS error.
		require
			path_exists: a_path /= default_pointer
		deferred
		end

	last_write_100ns (a_path: POINTER): INTEGER_64
			-- Last write time of `a_path' as 100 ns ticks since 1601-01-01 UTC,
			-- or -1 on failure.
		require
			path_exists: a_path /= default_pointer
		deferred
		end

feature -- Enumeration

	directory_pattern (a_directory: READABLE_STRING_32): STRING_32
			-- What `find_first' needs in order to list `a_directory'.
		deferred
		end

	find_data_size: INTEGER
			-- Bytes needed by the `a_data' buffer of `find_first' and `find_next'.
		deferred
		end

	find_first (a_pattern, a_data, a_error: POINTER): POINTER
			-- Start listing the directory given by `a_pattern', filling `a_data'.
			-- Null on failure, with the OS error stored as a 32-bit integer at `a_error'.
		require
			pattern_exists: a_pattern /= default_pointer
			data_exists: a_data /= default_pointer
			error_exists: a_error /= default_pointer
		deferred
		end

	find_next (a_handle, a_data, a_error: POINTER): BOOLEAN
			-- Next entry into `a_data'. False at the end or on failure, with the OS
			-- error (`Error_no_more_files' at the end) stored at `a_error'.
		require
			handle_exists: a_handle /= default_pointer
			data_exists: a_data /= default_pointer
			error_exists: a_error /= default_pointer
		deferred
		end

	find_close (a_handle: POINTER)
			-- End the listing `a_handle'.
		require
			handle_exists: a_handle /= default_pointer
		deferred
		end

	find_data_name (a_data: POINTER): POINTER
			-- Address of the null-terminated entry name inside `a_data'.
		require
			data_exists: a_data /= default_pointer
		deferred
		end

	find_data_attributes (a_data: POINTER): NATURAL_32
			-- Attribute bits of the entry in `a_data'.
		require
			data_exists: a_data /= default_pointer
		deferred
		end

feature -- Process and errors

	current_process_id: NATURAL_32
			-- Id of this process.
		deferred
		end

	is_owner_running (a_pid: NATURAL_32; a_file: POINTER): BOOLEAN
			-- May process `a_pid' be the running process that created `a_file'?
			-- One that exists but may not be queried counts as running.
		require
			file_exists: a_file /= default_pointer
		deferred
		end

	performance_counter: INTEGER_64
			-- A fast counter, used to vary temporary names.
		deferred
		end

	error_text (a_code: INTEGER): STRING_32
			-- System message for `a_code', naming the code.
		deferred
		ensure
			names_code: Result.has_substring (a_code.out)
		end

note
	copyright: "Copyright (c) 2024-2026, Larry Rix"
	license: "MIT License"

end
