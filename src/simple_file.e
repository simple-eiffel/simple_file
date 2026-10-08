note
	description: "[
		Simple file and directory operations wrapper.

		Replacing writes (`write_text', `write_bytes', `write_lines',
		`write_text_utf_8') are atomic: the new content goes to a temporary
		file in the same folder, is flushed to disk (FlushFileBuffers) and
		then renamed over the target with MoveFileExW (REPLACE_EXISTING |
		WRITE_THROUGH). A process killed mid-write leaves the old content or
		the new, never an empty or partial file (0 of 500 kills lost in the
		RQ-06 spikes; 112 of 200 emptied with the 1.0 truncate-then-write).
		A kill can leave a `.~sf*.tmp' file behind in that folder.
		ReplaceFileW is never used: it can destroy outside edits that land
		during the call while returning success (RQ-06, D18). An outside
		edit made between a caller's read and its write is still replaced,
		as with any whole-file save.

		Appends (`append_text', `append_line') are not atomic, by design: an
		append extends the file in place.

		Every write and create attempts the real operation and reports a
		failure through the Boolean result and `last_error' / `last_error_code'.
		Nothing is refused on the strength of a folder's ReadOnly attribute,
		which Windows does not honor on directories (OneDrive sets it).

		A path holding a ':' other than a drive letter's names an NTFS
		alternate data stream ("John 3:16.md" is stream "16.md" of a file
		"John 3"); every write and create refuses such a path with an error
		(see `is_stream_path'). Use {SIMPLE_FILES}.file_safe_name to turn
		arbitrary text into a file name.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_FILE

create
	make,
	make_with_path

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
			-- Create file object for `a_path'.
		require
			path_not_empty: not a_path.is_empty
		do
			create internal_path.make_from_string (a_path.to_string_32)
			reset_error
		ensure
			path_set: not internal_path.is_empty
			path_model_matches: path_model.count = a_path.count
			no_error: not has_error
		end

	make_with_path (a_path: PATH)
			-- Create file object for `a_path'.
		require
			path_not_empty: not a_path.is_empty
		do
			internal_path := a_path
			reset_error
		ensure
			path_set: internal_path = a_path
			no_error: not has_error
		end

feature -- Model Queries (for contracts)

	path_model: MML_SEQUENCE [CHARACTER_32]
			-- Model of the path as character sequence.
		local
			l_name: STRING_32
			l_seq: MML_SEQUENCE [CHARACTER_32]
			i: INTEGER
		do
			l_name := internal_path.name
			create l_seq
			from i := 1 until i > l_name.count loop
				l_seq := l_seq & l_name.item (i)
				i := i + 1
			end
			Result := l_seq
		ensure
			count_matches: Result.count = internal_path.name.count
		end

	bytes_model: MML_SEQUENCE [NATURAL_8]
			-- Model of file content as byte sequence.
			-- Empty if file doesn't exist or isn't readable.
		local
			l_file: RAW_FILE
			l_seq: MML_SEQUENCE [NATURAL_8]
		do
			create l_seq
			create l_file.make_with_path (internal_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				from until l_file.end_of_file loop
					l_file.read_natural_8
					if not l_file.end_of_file then
						l_seq := l_seq & l_file.last_natural_8
					end
				end
				l_file.close
			end
			Result := l_seq
		end

	lines_model: MML_SEQUENCE [STRING_32]
			-- Model of file content as sequence of lines.
			-- Empty if file doesn't exist or isn't readable.
		local
			l_file: PLAIN_TEXT_FILE
			l_seq: MML_SEQUENCE [STRING_32]
		do
			create l_seq
			create l_file.make_with_path (internal_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_file.set_utf8_encoding
				from
					l_file.read_line
				until
					l_file.exhausted
				loop
					l_seq := l_seq & l_file.last_string.to_string_32
					l_file.read_line
				end
				l_file.close
			end
			Result := l_seq
		end

	entries_model: MML_SET [STRING_32]
			-- Model of directory entries as a set.
			-- Empty if not a directory or doesn't exist.
		local
			l_dir: DIRECTORY
			l_set: MML_SET [STRING_32]
		do
			create l_set
			create l_dir.make_with_path (internal_path)
			if l_dir.exists then
				l_dir.open_read
				from
					l_dir.readentry
				until
					not attached l_dir.last_entry_32 as l_entry
				loop
					if not l_entry.same_string (".") and not l_entry.same_string ("..") then
						l_set := l_set & l_entry
					end
					l_dir.readentry
				end
				l_dir.close
			end
			Result := l_set
		end

feature -- File Status

	exists,
	is_present,
	found: BOOLEAN
			-- Does file or directory exist?
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_path (internal_path)
			Result := l_file.exists
		end

	is_readable: BOOLEAN
			-- Can file be read?
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_path (internal_path)
			Result := l_file.exists and then l_file.is_readable
		end

	is_writable: BOOLEAN
			-- Can file be written?
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_path (internal_path)
			Result := l_file.exists and then l_file.is_writable
		end

	is_executable: BOOLEAN
			-- Can file be executed?
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_path (internal_path)
			Result := l_file.exists and then l_file.is_executable
		end

	is_directory: BOOLEAN
			-- Is this a directory?
		local
			l_dir: DIRECTORY
		do
			create l_dir.make_with_path (internal_path)
			Result := l_dir.exists
		end

	is_file: BOOLEAN
			-- Is this a regular file (not directory)?
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_path (internal_path)
			Result := l_file.exists and then l_file.is_plain
		end

	is_symlink: BOOLEAN
			-- Is this a symbolic link?
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_path (internal_path)
			if l_file.path_exists then
				Result := l_file.is_symlink
			end
		end

	is_stream_path: BOOLEAN
			-- Does the path name an NTFS alternate data stream, that is, does
			-- it hold a ':' other than a drive letter's? Windows reads
			-- "notes\John 3:16.md" as stream "16.md" of a file "John 3", so
			-- every write and create refuses such a path.
		local
			l_name: STRING_32
			l_start: INTEGER
		do
			l_name := internal_path.name
			l_start := 1
			if l_name.starts_with ({STRING_32} "\\?\") or l_name.starts_with ({STRING_32} "\\.\") then
				l_start := 5
			end
			if l_name.count > l_start and then is_ascii_letter (l_name [l_start]) and then l_name [l_start + 1] = ':' then
				l_start := l_start + 2
			end
			Result := l_start <= l_name.count and then l_name.index_of (':', l_start) > 0
		end

feature -- File Metadata

	size,
	length,
	byte_count: INTEGER_64
			-- Size in bytes (0 if file doesn't exist).
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_path (internal_path)
			if l_file.exists then
				Result := l_file.count
			end
		end

	modified_timestamp: INTEGER
			-- Modification timestamp (seconds since epoch).
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_path (internal_path)
			if l_file.exists then
				Result := l_file.date
			end
		end

	modified_time_100ns: INTEGER_64
			-- Last-write time at full NTFS precision: 100 ns ticks since
			-- 1601-01-01 UTC (a Windows FILETIME, from GetFileAttributesExW).
			-- 0 if the path does not exist or cannot be queried.
			-- `modified_timestamp' is the same instant cut to whole seconds,
			-- which misses a second edit inside the same second.
		local
			l_path: NATIVE_STRING
		do
			create l_path.make (internal_path.name)
			Result := win32.last_write_100ns (l_path.item).max (0)
		ensure
			non_negative: Result >= 0
		end

	accessed_timestamp: INTEGER
			-- Access timestamp (seconds since epoch).
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_path (internal_path)
			if l_file.exists then
				Result := l_file.access_date
			end
		end

	extension: STRING_32
			-- File extension (e.g., "txt"), empty if none.
		local
			l_name: STRING_32
			l_dot: INTEGER
		do
			l_name := file_name
			l_dot := l_name.last_index_of ('.', l_name.count)
			if l_dot > 1 and l_dot < l_name.count then
				Result := l_name.substring (l_dot + 1, l_name.count)
			else
				create Result.make_empty
			end
		end

	base_name: STRING_32
			-- File name without extension.
		local
			l_name: STRING_32
			l_dot: INTEGER
		do
			l_name := file_name
			l_dot := l_name.last_index_of ('.', l_name.count)
			if l_dot > 1 then
				Result := l_name.substring (1, l_dot - 1)
			else
				Result := l_name.twin
			end
		end

	file_name: STRING_32
			-- Full file name with extension.
		do
			if attached internal_path.entry as l_entry then
				Result := l_entry.name
			else
				Result := internal_path.name
			end
		end

	parent_path: STRING_32
			-- Parent directory path.
		do
			Result := internal_path.parent.name
		end

	path: PATH
			-- Full PATH object.
		do
			Result := internal_path
		end

	path_string: STRING_32
			-- Full path as string.
		do
			Result := internal_path.name
		end

feature -- Read Operations

	read_text,
	get_content,
	load,
	read_all,
	content: STRING_32
			-- Read entire file as text, one CHARACTER_32 per byte: the bytes
			-- are NOT decoded from UTF-8 (a two-byte UTF-8 character comes
			-- back as two characters), CR LF becomes LF and a final line break
			-- is dropped. Kept as in 1.0 because clients convert the result
			-- with `to_string_8' or their own UTF-8 decoder. For decoded text,
			-- byte-faithful, use `read_text_utf_8'.
		local
			l_file: PLAIN_TEXT_FILE
			l_first: BOOLEAN
		do
			reset_error
			create Result.make_empty
			create l_file.make_with_path (internal_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_file.set_utf8_encoding
				l_first := True
				from
				until
					l_file.exhausted
				loop
					l_file.read_line
					if not l_file.exhausted or else not l_file.last_string.is_empty then
						if not l_first then
							Result.append_character ('%N')
						end
						l_first := False
						Result.append_string_general (l_file.last_string)
					end
				end
				l_file.close
			else
				set_error ({STRING_32} "File not readable: " + internal_path.name)
			end
		end

	read_text_utf_8: STRING_32
			-- Entire file decoded from UTF-8, exactly as stored: line endings
			-- and a final line break are kept, only a leading UTF-8 byte order
			-- mark (EF BB BF) is dropped. Each invalid UTF-8 byte becomes
			-- U+FFFD and is reported through `last_error'. A file that cannot
			-- be opened or read gives an empty result and an error; nothing is
			-- raised. The file is opened sharing read, write and delete.
		local
			l_bytes: STRING_8
			l_encoding: SIMPLE_ENCODING
			l_first_line: INTEGER
		do
			reset_error
			l_bytes := raw_bytes ("File not readable: ")
			if has_error then
				create Result.make_empty
			else
				if l_bytes.count >= 3 and then l_bytes.code (1) = 0xEF and then l_bytes.code (2) = 0xBB and then l_bytes.code (3) = 0xBF then
					l_bytes.remove_head (3)
				end
				create l_encoding.make
				Result := l_encoding.utf_8_to_utf_32 (l_bytes)
				if l_encoding.has_error then
					l_first_line := l_encoding.last_error.index_of ('%N', 1)
					if l_first_line > 1 then
						set_error ({STRING_32} "Invalid UTF-8 in " + internal_path.name + {STRING_32} ": " + l_encoding.last_error.substring (1, l_first_line - 1) + {STRING_32} " (each invalid byte read as U+FFFD)")
					else
						set_error ({STRING_32} "Invalid UTF-8 in " + internal_path.name)
					end
				end
			end
		ensure
			empty_on_read_failure: (has_error and last_error_code /= 0) implies Result.is_empty
		end

	read_bytes,
	get_binary,
	load_binary,
	binary_content: ARRAY [NATURAL_8]
			-- Read entire file as bytes.
		local
			l_file: RAW_FILE
			l_byte: NATURAL_8
		do
			reset_error
			create Result.make_empty
			create l_file.make_with_path (internal_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				from
				until
					l_file.end_of_file
				loop
					l_file.read_natural_8
					if not l_file.end_of_file then
						l_byte := l_file.last_natural_8
						Result.force (l_byte, Result.count + 1)
					end
				end
				l_file.close
			else
				set_error ({STRING_32} "File not readable: " + internal_path.name)
			end
		end

	read_lines,
	get_lines,
	load_lines,
	lines: ARRAYED_LIST [STRING_32]
			-- Read all lines.
		local
			l_file: PLAIN_TEXT_FILE
		do
			reset_error
			create Result.make (10)
			create l_file.make_with_path (internal_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_file.set_utf8_encoding
				from
					l_file.read_line
				until
					l_file.exhausted
				loop
					Result.extend (l_file.last_string.to_string_32)
					l_file.read_line
				end
				l_file.close
			else
				set_error ({STRING_32} "File not readable: " + internal_path.name)
			end
		end

feature -- Write Operations

	write_text,
	put_content,
	save,
	write_all,
	set_content (a_content: READABLE_STRING_GENERAL): BOOLEAN
			-- Write content to file (overwrites), atomically. Returns success.
			-- Bytes as in 1.0: UTF-8, each LF written as CR LF.
			-- The old content stays in place until the new is complete on
			-- disk; see the class note. On failure the target is untouched,
			-- the temporary file is removed and `last_error' says why.
		do
			Result := replace_with (text_bytes (a_content, True))
		ensure
			success_implies_exists: Result implies exists
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

	write_text_utf_8 (a_content: READABLE_STRING_GENERAL): BOOLEAN
			-- Write `a_content' as UTF-8 exactly (no line-ending translation,
			-- no byte order mark), atomically like `write_text'. The writing
			-- counterpart of `read_text_utf_8': the two round-trip any text.
		do
			Result := replace_with (text_bytes (a_content, False))
		ensure
			success_implies_exists: Result implies exists
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

	write_bytes,
	put_binary,
	save_binary (a_bytes: ARRAY [NATURAL_8]): BOOLEAN
			-- Write bytes to file (overwrites), atomically. Returns success.
		local
			l_bytes: STRING_8
			i: INTEGER
		do
			create l_bytes.make (a_bytes.count)
			from
				i := a_bytes.lower
			until
				i > a_bytes.upper
			loop
				l_bytes.append_code (a_bytes [i].to_natural_32)
				i := i + 1
			end
			Result := replace_with (l_bytes)
		ensure
			success_implies_exists: Result implies exists
			success_implies_size: Result implies size = a_bytes.count.to_integer_64
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

	write_lines (a_lines: LIST [READABLE_STRING_GENERAL]): BOOLEAN
			-- Write lines to file (overwrites), atomically, each followed by a
			-- line break (CR LF). Returns success.
		local
			l_text: STRING_32
			i: INTEGER
		do
			create l_text.make (80 * a_lines.count)
			from
				i := 1
			until
				i > a_lines.count
			loop
				l_text.append_string_general (a_lines.i_th (i))
				l_text.append_character ('%N')
				i := i + 1
			end
			Result := replace_with (text_bytes (l_text, True))
		ensure
			success_implies_exists: Result implies exists
			success_implies_line_count: Result implies lines_model.count = a_lines.count
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

	append_text (a_content: READABLE_STRING_GENERAL): BOOLEAN
			-- Append content to file, creating it if missing. Returns success.
			-- Not atomic: an append extends the file in place, so a process
			-- killed mid-append can leave part of `a_content' at the end
			-- (never damage what was there before).
		do
			Result := append_bytes (text_bytes (a_content, True))
		ensure
			success_implies_exists: Result implies exists
			size_increased: Result implies size >= old size
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

	append_line (a_line: READABLE_STRING_GENERAL): BOOLEAN
			-- Append line with newline to file, creating it if missing.
			-- Returns success. Not atomic (see `append_text').
		local
			l_text: STRING_32
		do
			create l_text.make (a_line.count + 1)
			l_text.append_string_general (a_line)
			l_text.append_character ('%N')
			Result := append_bytes (text_bytes (l_text, True))
		ensure
			success_implies_exists: Result implies exists
			line_count_increased: Result implies lines_model.count >= old lines_model.count
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

	clear: BOOLEAN
			-- Empty the file. Returns success.
		local
			l_file: PLAIN_TEXT_FILE
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.exists then
				l_file.open_write
				l_file.close
				Result := True
			else
				set_error ({STRING_32} "File does not exist: " + internal_path.name)
			end
		ensure
			success_implies_empty: Result implies size = 0
			success_implies_exists: Result implies exists
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

feature -- File Operations

	copy_to,
	copy_file,
	duplicate_to (a_destination: READABLE_STRING_GENERAL): BOOLEAN
			-- Copy file to destination. Returns success.
			-- The copy is attempted whatever the destination folder's ReadOnly
			-- attribute says; an OS failure is reported, not raised. A
			-- destination naming an alternate data stream is refused.
		require
			destination_not_empty: not a_destination.is_empty
		local
			l_src, l_dest: detachable RAW_FILE
			l_retried: BOOLEAN
		do
			if not l_retried then
				reset_error
				if names_stream (a_destination) then
					set_error (stream_message (a_destination))
				else
					create l_src.make_with_path (internal_path)
					if l_src.exists and then l_src.is_readable then
						create l_dest.make_with_name (a_destination)
						l_src.open_read
						l_dest.open_write
						l_src.copy_to (l_dest)
						l_src.close
						l_dest.close
						Result := True
					else
						set_error ({STRING_32} "Source file not readable: " + internal_path.name)
					end
				end
			end
		ensure
			source_unchanged: exists = old exists
			source_content_unchanged: bytes_model |=| old bytes_model
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		rescue
			l_retried := True
			if attached l_src as al_src and then not al_src.is_closed then
				al_src.close
			end
			if attached l_dest as al_dest and then not al_dest.is_closed then
				al_dest.close
			end
			set_error ({STRING_32} "Cannot write to destination: " + a_destination.to_string_32 + {STRING_32} " - " + last_exception_text)
			retry
		end

	move_to,
	move,
	relocate_to (a_destination: READABLE_STRING_GENERAL): BOOLEAN
			-- Move file to destination. Returns success.
			-- An OS failure is reported, not raised. A destination naming an
			-- alternate data stream is refused.
		require
			destination_not_empty: not a_destination.is_empty
		local
			l_file: RAW_FILE
			l_retried: BOOLEAN
		do
			if not l_retried then
				reset_error
				if names_stream (a_destination) then
					set_error (stream_message (a_destination))
				else
					create l_file.make_with_path (internal_path)
					if l_file.exists then
						l_file.rename_file (a_destination)
						internal_path := create {PATH}.make_from_string (a_destination.to_string_32)
						Result := True
					else
						set_error ({STRING_32} "File does not exist: " + internal_path.name)
					end
				end
			end
		ensure
			success_implies_exists: Result implies exists
			success_implies_new_path: Result implies path_string.same_string (a_destination.to_string_32)
			failure_implies_error: not Result implies has_error
		rescue
			l_retried := True
			set_error ({STRING_32} "Cannot move to: " + a_destination.to_string_32 + {STRING_32} " - " + last_exception_text)
			retry
		end

	rename_to (a_new_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Rename file (same directory). Returns success.
		require
			name_not_empty: not a_new_name.is_empty
		local
			l_new_path: STRING_32
		do
			l_new_path := parent_path.twin
			l_new_path.append_character ({OPERATING_ENVIRONMENT}.directory_separator)
			l_new_path.append_string_general (a_new_name)
			Result := move_to (l_new_path)
		ensure
			success_implies_exists: Result implies exists
			success_implies_new_name: Result implies file_name.same_string (a_new_name.to_string_32)
			failure_implies_error: not Result implies has_error
		end

	delete,
	remove,
	unlink: BOOLEAN
			-- Delete file. Returns success.
		local
			l_file: RAW_FILE
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.exists then
				l_file.delete
				Result := True
			else
				set_error ({STRING_32} "File does not exist: " + internal_path.name)
			end
		ensure
			success_implies_gone: Result implies not exists
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

	create_if_missing: BOOLEAN
			-- Create empty file if it doesn't exist. Returns success.
			-- Creation is attempted whatever the folder's ReadOnly attribute
			-- says (Windows does not honor it on directories); a failure is
			-- reported. A path naming an alternate data stream is refused.
		local
			l_file: PLAIN_TEXT_FILE
			l_path: NATIVE_STRING
			l_code: INTEGER
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.exists then
				Result := True -- Already exists
			elseif is_stream_path then
				set_error (stream_message (internal_path.name))
			else
				create l_path.make (internal_path.name)
				l_code := win32.write_new_file (l_path.item, default_pointer, 0, default_pointer)
				if l_code = 0 or l_code = {SIMPLE_FILE_WIN32}.Error_file_exists then
					Result := True
				else
					set_os_error ({STRING_32} "Cannot create file: ", l_code)
				end
			end
		ensure
			success_implies_exists: Result implies exists
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

feature -- Directory Operations

	entries,
	list,
	contents,
	children: ARRAYED_LIST [STRING_32]
			-- All entries in directory, from one FindFirstFileExW pass.
			-- (The 1.0 postcondition `Result.count = entries_model.count' was
			-- removed: it listed the folder a second time, so it failed when
			-- another process changed the folder in between, and its MML set
			-- made each call quadratic under contracts.)
		do
			Result := listed (True, True)
		ensure
			path_unchanged: path_model |=| old path_model
		end

	files: ARRAYED_LIST [STRING_32]
			-- Only files in directory (not subdirectories), from one
			-- FindFirstFileExW pass: an entry is a file when it lacks
			-- FILE_ATTRIBUTE_DIRECTORY.
		do
			Result := listed (True, False)
		end

	directories: ARRAYED_LIST [STRING_32]
			-- Only subdirectories in directory (junctions and directory links
			-- included), from one FindFirstFileExW pass.
		do
			Result := listed (False, True)
		end

	remove_stale_temporaries: INTEGER
			-- In this directory, delete the temporary files that atomic
			-- writes of processes no longer running left behind (a process
			-- killed mid-write leaves its ".~sf<pid>_<n>.tmp"); return how
			-- many were removed. Temporaries of running processes, and every
			-- other file, are left alone; a process that reuses a dead
			-- owner's id but started after the temporary was created does not
			-- count as its owner. Safe for data: the target of an interrupted
			-- write was never touched, and were an owner misjudged and still
			-- writing, its rename would fail and be reported to it.
		local
			l_pid: NATURAL_32
			l_path: NATIVE_STRING
			l_failures: INTEGER
		do
			across listed (True, False) as ic loop
				l_pid := temporary_owner (ic)
				create l_path.make (internal_path.extended (ic).name)
				if l_pid /= 0 and then l_pid /= win32.current_process_id and then not win32.is_owner_running (l_pid, l_path.item) then
					if win32.delete_file (l_path.item) = 0 then
						Result := Result + 1
					else
						l_failures := l_failures + 1
					end
				end
			end
			if l_failures > 0 and not has_error then
				set_error ({STRING_32} "Could not remove " + l_failures.out + {STRING_32} " stale temporary file(s) in " + internal_path.name)
			end
		ensure
			non_negative: Result >= 0
		end

	files_with_extension (a_ext: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Files with given extension.
		local
			l_ext: STRING_32
			l_files: ARRAYED_LIST [STRING_32]
			l_file: STRING_32
			i: INTEGER
		do
			l_ext := a_ext.to_string_32.as_lower
			create Result.make (10)
			l_files := files
			from
				i := 1
			until
				i > l_files.count
			loop
				l_file := l_files.i_th (i)
				if l_file.as_lower.ends_with (l_ext) or else
				   l_file.as_lower.ends_with ({STRING_32} "." + l_ext) then
					Result.extend (l_file)
				end
				i := i + 1
			end
		end

	create_directory: BOOLEAN
			-- Create directory. Returns success.
		local
			l_dir: DIRECTORY
		do
			reset_error
			create l_dir.make_with_path (internal_path)
			if not l_dir.exists then
				l_dir.create_dir
				Result := l_dir.exists
				if not Result then
					set_error ({STRING_32} "Failed to create directory: " + internal_path.name)
				end
			else
				Result := True -- Already exists
			end
		ensure
			success_implies_exists: Result implies is_directory
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

	create_directory_recursive: BOOLEAN
			-- Create directory and parents. Returns success.
		local
			l_dir: DIRECTORY
		do
			reset_error
			create l_dir.make_with_path (internal_path)
			if not l_dir.exists then
				l_dir.recursive_create_dir
				Result := l_dir.exists
				if not Result then
					set_error ({STRING_32} "Failed to create directory: " + internal_path.name)
				end
			else
				Result := True -- Already exists
			end
		ensure
			success_implies_exists: Result implies is_directory
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

	delete_directory: BOOLEAN
			-- Delete empty directory. Returns success.
		local
			l_dir: DIRECTORY
		do
			reset_error
			create l_dir.make_with_path (internal_path)
			if l_dir.exists then
				l_dir.delete
				Result := not l_dir.exists
				if not Result then
					set_error ({STRING_32} "Failed to delete directory (not empty?): " + internal_path.name)
				end
			else
				set_error ({STRING_32} "Directory does not exist: " + internal_path.name)
			end
		ensure
			success_implies_gone: Result implies not is_directory
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

	delete_directory_recursive: BOOLEAN
			-- Delete directory and contents. Returns success.
		local
			l_dir: DIRECTORY
		do
			reset_error
			create l_dir.make_with_path (internal_path)
			if l_dir.exists then
				l_dir.recursive_delete
				Result := not l_dir.exists
				if not Result then
					set_error ({STRING_32} "Failed to delete directory: " + internal_path.name)
				end
			else
				set_error ({STRING_32} "Directory does not exist: " + internal_path.name)
			end
		ensure
			success_implies_gone: Result implies not is_directory
			failure_implies_error: not Result implies has_error
			path_unchanged: path_model |=| old path_model
		end

feature -- Streaming Operations (for large files)

	each_line (a_action: PROCEDURE [STRING_32])
			-- Iterate lines one at a time (memory efficient).
		local
			l_file: PLAIN_TEXT_FILE
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_file.set_utf8_encoding
				from
					l_file.read_line
				until
					l_file.exhausted
				loop
					a_action.call ([l_file.last_string.to_string_32])
					l_file.read_line
				end
				l_file.close
			else
				set_error ({STRING_32} "File not readable: " + internal_path.name)
			end
		end

	read_chunk (a_offset, a_size: INTEGER): ARRAY [NATURAL_8]
			-- Read chunk of bytes at offset (for large binary files).
		local
			l_file: RAW_FILE
			i: INTEGER
		do
			reset_error
			create Result.make_empty
			create l_file.make_with_path (internal_path)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				if a_offset > 0 then
					l_file.go (a_offset)
				end
				from
					i := 0
				until
					i >= a_size or l_file.end_of_file
				loop
					l_file.read_natural_8
					if not l_file.end_of_file then
						Result.force (l_file.last_natural_8, Result.count + 1)
					end
					i := i + 1
				end
				l_file.close
			else
				set_error ({STRING_32} "File not readable: " + internal_path.name)
			end
		end

feature -- Path Transformation

	resolve: STRING_32
			-- Canonical absolute path (requires file to exist).
		do
			Result := internal_path.canonical_path.name
		end

	normalize: STRING_32
			-- Normalize path (remove . and ..) without requiring existence.
		local
			l_parts: LIST [IMMUTABLE_STRING_32]
			l_result: ARRAYED_LIST [STRING_32]
			l_sep: CHARACTER_32
			l_part: IMMUTABLE_STRING_32
			i: INTEGER
		do
			l_sep := {OPERATING_ENVIRONMENT}.directory_separator
			l_parts := internal_path.name.split (l_sep)
			create l_result.make (l_parts.count)
			from
				i := 1
			until
				i > l_parts.count
			loop
				l_part := l_parts.i_th (i)
				if l_part.same_string (".") then
					-- Skip current dir
				elseif l_part.same_string ("..") then
					if not l_result.is_empty and then not l_result.last.same_string ("..") then
						l_result.finish
						l_result.remove
					else
						l_result.extend ({STRING_32} "..")
					end
				elseif not l_part.is_empty then
					l_result.extend (l_part)
				end
				i := i + 1
			end

			create Result.make_empty
			from
				i := 1
			until
				i > l_result.count
			loop
				if not Result.is_empty then
					Result.append_character (l_sep)
				end
				Result.append (l_result.i_th (i))
				i := i + 1
			end
		end

	absolute_path: STRING_32
			-- Make path absolute.
		do
			Result := internal_path.absolute_path.name
		end

feature -- Permission Helpers

	make_readable: BOOLEAN
			-- Make file readable. Returns success.
			-- Note: Full implementation requires platform-specific code.
		local
			l_file: RAW_FILE
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.exists then
				-- For now, just check if already readable
				Result := l_file.is_readable
				if not Result then
					set_error ("Cannot change permissions (platform-specific)")
				end
			else
				set_error ({STRING_32} "File does not exist: " + internal_path.name)
			end
		end

	make_writable: BOOLEAN
			-- Make file writable. Returns success.
			-- Note: Full implementation requires platform-specific code.
		local
			l_file: RAW_FILE
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.exists then
				-- For now, just check if already writable
				Result := l_file.is_writable
				if not Result then
					set_error ("Cannot change permissions (platform-specific)")
				end
			else
				set_error ({STRING_32} "File does not exist: " + internal_path.name)
			end
		end

feature -- Temporary File Support

	with_temp_file (a_action: PROCEDURE [SIMPLE_FILE])
			-- Execute action with temp file, auto-delete after.
		local
			l_files: SIMPLE_FILES
			l_temp_path: STRING_32
			l_temp: SIMPLE_FILE
			l_ignore: BOOLEAN
		do
			l_temp_path := l_files.temp_file_path ("simple_file")
			create l_temp.make (l_temp_path)
			l_ignore := l_temp.create_if_missing
			a_action.call ([l_temp])
			if l_temp.exists then
				l_ignore := l_temp.delete
			end
		end

feature -- Error Handling

	has_error,
	failed,
	error_occurred: BOOLEAN
			-- Did last operation fail?
		do
			Result := not last_error.is_empty
		end

	last_error: STRING_32
			-- Description of last error, empty if none.

	last_error_code: INTEGER
			-- Win32 error code behind `last_error' (5 = access denied,
			-- 32 = sharing violation, ...), 0 if none or not an OS error.

feature {NONE} -- Implementation

	internal_path: PATH
			-- Internal path object.

	reset_error
			-- Clear error state.
		do
			create last_error.make_empty
			last_error_code := 0
		ensure
			no_error: not has_error
			no_code: last_error_code = 0
		end

	set_error (a_message: READABLE_STRING_GENERAL)
			-- Set error message (not an OS error: `last_error_code' becomes 0).
		do
			last_error := a_message.to_string_32
			last_error_code := 0
		ensure
			code_cleared: last_error_code = 0
		end

	set_os_error (a_prefix: READABLE_STRING_GENERAL; a_code: INTEGER)
			-- Report Win32 error `a_code' for the current path, after `a_prefix'.
		require
			code_is_error: a_code /= 0
		do
			last_error := a_prefix.to_string_32 + internal_path.name + {STRING_32} " - " + win32.error_text (a_code)
			last_error_code := a_code
		ensure
			has_error: has_error
			code_set: last_error_code = a_code
		end

	win32: SIMPLE_FILE_WIN32
			-- Win32 primitives.
		once
			create Result
		end

	is_ascii_letter (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' in A-Z or a-z (a possible drive letter)?
		do
			Result := ('A' <= a_char and a_char <= 'Z') or ('a' <= a_char and a_char <= 'z')
		end

	names_stream (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_path' name an NTFS alternate data stream?
		local
			l_file: SIMPLE_FILE
		do
			if not a_path.is_empty then
				create l_file.make (a_path)
				Result := l_file.is_stream_path
			end
		end

	stream_message (a_path: READABLE_STRING_GENERAL): STRING_32
			-- Refusal text for a path naming an alternate data stream.
		do
			Result := {STRING_32} "Refused: ':' in a file name would write an NTFS alternate data stream, not a file: " + a_path.to_string_32 + {STRING_32} " (use {SIMPLE_FILES}.file_safe_name)"
		end

	last_exception_text: STRING_32
			-- Description of the exception being rescued.
		do
			if attached (create {EXCEPTION_MANAGER_FACTORY}).exception_manager.last_exception as l_exception then
				if attached l_exception.description as l_description and then not l_description.is_empty then
					Result := l_exception.generator.to_string_32 + {STRING_32} ": " + l_description
				else
					Result := l_exception.generator.to_string_32
				end
			else
				Result := {STRING_32} "unknown exception"
			end
		end

	text_bytes (a_content: READABLE_STRING_GENERAL; a_crlf: BOOLEAN): STRING_8
			-- `a_content' encoded as UTF-8 (each character taken as a Unicode
			-- code point, as 1.0's PLAIN_TEXT_FILE did), each LF written as
			-- CR LF when `a_crlf' (1.0's text-mode output on Windows).
		local
			l_encoding: SIMPLE_ENCODING
			l_utf_8: STRING_8
			l_lf_count, i: INTEGER
		do
			create l_encoding.make
			l_utf_8 := l_encoding.utf_32_to_utf_8 (a_content.to_string_32)
			if a_crlf then
				l_lf_count := l_utf_8.occurrences ('%N')
			end
			if l_lf_count = 0 then
				Result := l_utf_8
			else
				create Result.make (l_utf_8.count + l_lf_count)
				from
					i := 1
				until
					i > l_utf_8.count
				loop
					if l_utf_8 [i] = '%N' then
						Result.append_character ('%R')
					end
					Result.append_character (l_utf_8 [i])
					i := i + 1
				end
			end
		ensure
			at_least_one_byte_per_character: Result.count >= a_content.count
		end

	replace_with (a_bytes: STRING_8): BOOLEAN
			-- Replace the file at `internal_path' with `a_bytes', atomically:
			-- a temporary file in the same folder (CREATE_NEW), written,
			-- FlushFileBuffers, closed, then MoveFileExW (REPLACE_EXISTING |
			-- WRITE_THROUGH) over the target. On failure the temporary file
			-- is deleted, the target is untouched and the error is reported.
		local
			l_data: MANAGED_POINTER
			l_target, l_temp: NATIVE_STRING
			l_code, l_attempt, l_ignored: INTEGER
		do
			reset_error
			if is_stream_path then
				set_error (stream_message (internal_path.name))
			else
				create l_data.make (a_bytes.count.max (1))
				if a_bytes.count > 0 then
					l_data.put_special_character_8 (a_bytes.area, 0, 0, a_bytes.count)
				end
				create l_target.make (internal_path.name)
				from
					l_attempt := 1
					create l_temp.make (temporary_sibling_name (l_attempt))
					l_code := win32.write_new_file (l_temp.item, l_data.item, a_bytes.count, l_target.item)
				until
					l_attempt >= 8 or (l_code /= {SIMPLE_FILE_WIN32}.Error_file_exists and l_code /= {SIMPLE_FILE_WIN32}.Error_already_exists)
				loop
					l_attempt := l_attempt + 1
					create l_temp.make (temporary_sibling_name (l_attempt))
					l_code := win32.write_new_file (l_temp.item, l_data.item, a_bytes.count, l_target.item)
				end
				if l_code = 0 then
					l_code := win32.move_replace (l_temp.item, l_target.item)
					if l_code /= 0 then
						l_ignored := win32.delete_file (l_temp.item)
					end
				end
				if l_code = 0 then
					Result := True
				else
					set_os_error ({STRING_32} "Cannot write to: ", l_code)
				end
			end
		ensure
			failure_implies_error: not Result implies has_error
			success_implies_no_error: Result implies not has_error
		end

	temporary_sibling_name (a_attempt: INTEGER): STRING_32
			-- Name for a temporary file in the folder of the target (so the
			-- final MoveFileExW is a rename on one volume): ".~sf<pid>_<n>.tmp".
			-- The leading dot keeps it out of Obsidian-style views.
		local
			l_name: STRING_32
		do
			create l_name.make (40)
			l_name.append ({STRING_32} ".~sf")
			l_name.append (win32.current_process_id.to_hex_string)
			l_name.append_character ('_')
			l_name.append ((win32.performance_counter + a_attempt).to_hex_string)
			l_name.append ({STRING_32} ".tmp")
			Result := internal_path.parent.extended (l_name).name
		end

	temporary_owner (a_name: READABLE_STRING_32): NATURAL_32
			-- Process id in `a_name' if it has the form of
			-- `temporary_sibling_name' (".~sf<hex pid>_<hex>.tmp"), else 0.
		local
			i, l_underscore: INTEGER
			l_digit: NATURAL_32
			l_valid: BOOLEAN
		do
			if a_name.starts_with ({STRING_32} ".~sf") and then a_name.ends_with ({STRING_32} ".tmp") then
				l_underscore := a_name.index_of ('_', 5)
				if l_underscore > 5 and l_underscore <= 13 then
					l_valid := True
					from
						i := 5
					until
						i >= l_underscore or not l_valid
					loop
						inspect a_name [i]
						when '0' .. '9' then
							l_digit := a_name.code (i) - ('0').natural_32_code
						when 'A' .. 'F' then
							l_digit := a_name.code (i) - ('A').natural_32_code + 10
						when 'a' .. 'f' then
							l_digit := a_name.code (i) - ('a').natural_32_code + 10
						else
							l_valid := False
						end
						if l_valid then
							Result := Result * 16 + l_digit
						end
						i := i + 1
					end
					if not l_valid then
						Result := 0
					end
				end
			end
		end

	append_bytes (a_bytes: STRING_8): BOOLEAN
			-- Append `a_bytes' at the end of the file, creating it if missing.
		local
			l_data: MANAGED_POINTER
			l_target: NATIVE_STRING
			l_code: INTEGER
		do
			reset_error
			if is_stream_path then
				set_error (stream_message (internal_path.name))
			else
				create l_data.make (a_bytes.count.max (1))
				if a_bytes.count > 0 then
					l_data.put_special_character_8 (a_bytes.area, 0, 0, a_bytes.count)
				end
				create l_target.make (internal_path.name)
				l_code := win32.append_to_file (l_target.item, l_data.item, a_bytes.count)
				if l_code = 0 then
					Result := True
				else
					set_os_error ({STRING_32} "Cannot append to: ", l_code)
				end
			end
		ensure
			failure_implies_error: not Result implies has_error
		end

	raw_bytes (a_failure_prefix: READABLE_STRING_GENERAL): STRING_8
			-- Every byte of the file, read through Win32 in 64 KiB chunks.
			-- Empty with an error set if the file cannot be opened or read.
		local
			l_path: NATIVE_STRING
			l_error, l_buffer: MANAGED_POINTER
			l_handle: POINTER
			l_read: INTEGER
			l_done: BOOLEAN
		do
			create Result.make (0)
			create l_path.make (internal_path.name)
			create l_error.make (4)
			l_handle := win32.open_for_read (l_path.item, l_error.item)
			if l_handle = default_pointer then
				set_os_error (a_failure_prefix, l_error.read_integer_32 (0))
			else
				create l_buffer.make (Read_chunk_size)
				from
				until
					l_done
				loop
					l_read := win32.read_chunk (l_handle, l_buffer.item, Read_chunk_size)
					if l_read < 0 then
						set_os_error (a_failure_prefix, - l_read)
						Result.wipe_out
						l_done := True
					elseif l_read = 0 then
						l_done := True
					else
						Result.append (create {STRING_8}.make_from_c_substring (l_buffer.item, 1, l_read))
					end
				end
				win32.close_handle (l_handle)
			end
		ensure
			empty_on_failure: has_error implies Result.is_empty
		end

	Read_chunk_size: INTEGER = 65536
			-- Bytes per ReadFile call.

	listed (a_files, a_directories: BOOLEAN): ARRAYED_LIST [STRING_32]
			-- Names in the directory (never "." or ".."), from one
			-- FindFirstFileExW (FindExInfoBasic, FIND_FIRST_EX_LARGE_FETCH)
			-- pass, in the order the file system returns them: files when
			-- `a_files', subdirectories when `a_directories'.
		local
			l_data, l_error: MANAGED_POINTER
			l_pattern_text: STRING_32
			l_pattern: NATIVE_STRING
			l_handle: POINTER
			l_more, l_is_directory: BOOLEAN
			l_name: STRING_32
			l_code: INTEGER
		do
			reset_error
			create Result.make (16)
			if is_directory then
				create l_data.make (win32.find_data_size)
				create l_error.make (4)
				l_pattern_text := internal_path.name.twin
				if not l_pattern_text.is_empty and then not (l_pattern_text [l_pattern_text.count] = '\' or l_pattern_text [l_pattern_text.count] = '/') then
					l_pattern_text.append_character ('\')
				end
				l_pattern_text.append_character ('*')
				create l_pattern.make (l_pattern_text)
				l_handle := win32.find_first (l_pattern.item, l_data.item, l_error.item)
				if l_handle = default_pointer then
					l_code := l_error.read_integer_32 (0)
					if l_code /= {SIMPLE_FILE_WIN32}.Error_file_not_found then
						set_os_error ({STRING_32} "Cannot list directory: ", l_code)
					end
				else
					from
						l_more := True
					until
						not l_more
					loop
						l_name := (create {NATIVE_STRING}.make_from_pointer (win32.find_data_name (l_data.item))).string
						if not (l_name.same_string_general (".") or l_name.same_string_general ("..")) then
							l_is_directory := (win32.find_data_attributes (l_data.item) & {SIMPLE_FILE_WIN32}.Attribute_directory) /= 0
							if (l_is_directory and a_directories) or (not l_is_directory and a_files) then
								Result.extend (l_name)
							end
						end
						l_more := win32.find_next (l_handle, l_data.item, l_error.item)
					end
					l_code := l_error.read_integer_32 (0)
					win32.find_close (l_handle)
					if l_code /= {SIMPLE_FILE_WIN32}.Error_no_more_files then
						set_os_error ({STRING_32} "Cannot list directory: ", l_code)
					end
				end
			else
				set_error ({STRING_32} "Directory does not exist: " + internal_path.name)
			end
		end

invariant
	-- Per-element and model clauses were removed 2026-09-11: an
	-- invariant runs on every feature call, so a clause that walks
	-- the collection or builds its MML model makes every call O(n)
	-- and a walk over the collection O(n^2) (simple_json read a
	-- 1434-element array in 158 s under DBC). Models belong in
	-- postconditions of the features that change them.
	path_not_empty: not internal_path.is_empty

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
