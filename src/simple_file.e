note
	description: "Simple file and directory operations wrapper"
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
		end

feature -- File Status

	exists: BOOLEAN
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

feature -- File Metadata

	size: INTEGER_64
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

	read_text: STRING_32
			-- Read entire file as text (UTF-8 default).
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
				set_error ("File not readable: " + internal_path.name)
			end
		end

	read_bytes: ARRAY [NATURAL_8]
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
				set_error ("File not readable: " + internal_path.name)
			end
		end

	read_lines: ARRAYED_LIST [STRING_32]
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
				set_error ("File not readable: " + internal_path.name)
			end
		end

feature -- Write Operations

	write_text (a_content: READABLE_STRING_GENERAL): BOOLEAN
			-- Write content to file (overwrites). Returns success.
		local
			l_file: PLAIN_TEXT_FILE
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.is_creatable or l_file.exists then
				l_file.open_write
				l_file.set_utf8_encoding
				l_file.put_string_general (a_content)
				l_file.close
				Result := True
			else
				set_error ("Cannot write to: " + internal_path.name)
			end
		end

	write_bytes (a_bytes: ARRAY [NATURAL_8]): BOOLEAN
			-- Write bytes to file (overwrites). Returns success.
		local
			l_file: RAW_FILE
			i: INTEGER
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.is_creatable or l_file.exists then
				l_file.open_write
				from
					i := a_bytes.lower
				until
					i > a_bytes.upper
				loop
					l_file.put_natural_8 (a_bytes [i])
					i := i + 1
				end
				l_file.close
				Result := True
			else
				set_error ("Cannot write to: " + internal_path.name)
			end
		end

	write_lines (a_lines: LIST [READABLE_STRING_GENERAL]): BOOLEAN
			-- Write lines to file (overwrites). Returns success.
		local
			l_file: PLAIN_TEXT_FILE
			i: INTEGER
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.is_creatable or l_file.exists then
				l_file.open_write
				l_file.set_utf8_encoding
				from
					i := 1
				until
					i > a_lines.count
				loop
					l_file.put_string_general (a_lines.i_th (i))
					l_file.put_new_line
					i := i + 1
				end
				l_file.close
				Result := True
			else
				set_error ("Cannot write to: " + internal_path.name)
			end
		end

	append_text (a_content: READABLE_STRING_GENERAL): BOOLEAN
			-- Append content to file. Returns success.
		local
			l_file: PLAIN_TEXT_FILE
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.exists or l_file.is_creatable then
				l_file.open_append
				l_file.set_utf8_encoding
				l_file.put_string_general (a_content)
				l_file.close
				Result := True
			else
				set_error ("Cannot append to: " + internal_path.name)
			end
		end

	append_line (a_line: READABLE_STRING_GENERAL): BOOLEAN
			-- Append line with newline to file. Returns success.
		local
			l_file: PLAIN_TEXT_FILE
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.exists or l_file.is_creatable then
				l_file.open_append
				l_file.set_utf8_encoding
				l_file.put_string_general (a_line)
				l_file.put_new_line
				l_file.close
				Result := True
			else
				set_error ("Cannot append to: " + internal_path.name)
			end
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
				set_error ("File does not exist: " + internal_path.name)
			end
		end

feature -- File Operations

	copy_to (a_destination: READABLE_STRING_GENERAL): BOOLEAN
			-- Copy file to destination. Returns success.
		local
			l_src, l_dest: RAW_FILE
		do
			reset_error
			create l_src.make_with_path (internal_path)
			if l_src.exists and then l_src.is_readable then
				create l_dest.make_with_name (a_destination)
				if l_dest.is_creatable or l_dest.exists then
					l_src.open_read
					l_dest.open_write
					l_src.copy_to (l_dest)
					l_src.close
					l_dest.close
					Result := True
				else
					set_error ("Cannot write to destination: " + a_destination.to_string_32)
				end
			else
				set_error ("Source file not readable: " + internal_path.name)
			end
		end

	move_to (a_destination: READABLE_STRING_GENERAL): BOOLEAN
			-- Move file to destination. Returns success.
		local
			l_file: RAW_FILE
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if l_file.exists then
				l_file.rename_file (a_destination)
				internal_path := create {PATH}.make_from_string (a_destination.to_string_32)
				Result := True
			else
				set_error ("File does not exist: " + internal_path.name)
			end
		end

	rename_to (a_new_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Rename file (same directory). Returns success.
		local
			l_new_path: STRING_32
		do
			l_new_path := parent_path.twin
			l_new_path.append_character ({OPERATING_ENVIRONMENT}.directory_separator)
			l_new_path.append_string_general (a_new_name)
			Result := move_to (l_new_path)
		end

	delete: BOOLEAN
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
				set_error ("File does not exist: " + internal_path.name)
			end
		end

	create_if_missing: BOOLEAN
			-- Create empty file if it doesn't exist. Returns success.
		local
			l_file: PLAIN_TEXT_FILE
		do
			reset_error
			create l_file.make_with_path (internal_path)
			if not l_file.exists then
				if l_file.is_creatable then
					l_file.create_read_write
					l_file.close
					Result := True
				else
					set_error ("Cannot create file: " + internal_path.name)
				end
			else
				Result := True -- Already exists
			end
		end

feature -- Directory Operations

	entries: ARRAYED_LIST [STRING_32]
			-- All entries in directory.
		local
			l_dir: DIRECTORY
		do
			reset_error
			create Result.make (10)
			create l_dir.make_with_path (internal_path)
			if l_dir.exists then
				l_dir.open_read
				from
					l_dir.readentry
				until
					not attached l_dir.last_entry_32 as l_entry
				loop
					if not l_entry.same_string (".") and not l_entry.same_string ("..") then
						Result.extend (l_entry)
					end
					l_dir.readentry
				end
				l_dir.close
			else
				set_error ("Directory does not exist: " + internal_path.name)
			end
		end

	files: ARRAYED_LIST [STRING_32]
			-- Only files in directory (not subdirectories).
		local
			l_dir: DIRECTORY
			l_file: RAW_FILE
			l_entry_path: PATH
		do
			reset_error
			create Result.make (10)
			create l_dir.make_with_path (internal_path)
			if l_dir.exists then
				l_dir.open_read
				from
					l_dir.readentry
				until
					not attached l_dir.last_entry_32 as l_entry
				loop
					if not l_entry.same_string (".") and not l_entry.same_string ("..") then
						l_entry_path := internal_path.extended (l_entry)
						create l_file.make_with_path (l_entry_path)
						if l_file.exists and then l_file.is_plain then
							Result.extend (l_entry)
						end
					end
					l_dir.readentry
				end
				l_dir.close
			else
				set_error ("Directory does not exist: " + internal_path.name)
			end
		end

	directories: ARRAYED_LIST [STRING_32]
			-- Only subdirectories in directory.
		local
			l_dir: DIRECTORY
			l_subdir: DIRECTORY
			l_entry_path: PATH
		do
			reset_error
			create Result.make (10)
			create l_dir.make_with_path (internal_path)
			if l_dir.exists then
				l_dir.open_read
				from
					l_dir.readentry
				until
					not attached l_dir.last_entry_32 as l_entry
				loop
					if not l_entry.same_string (".") and not l_entry.same_string ("..") then
						l_entry_path := internal_path.extended (l_entry)
						create l_subdir.make_with_path (l_entry_path)
						if l_subdir.exists then
							Result.extend (l_entry)
						end
					end
					l_dir.readentry
				end
				l_dir.close
			else
				set_error ("Directory does not exist: " + internal_path.name)
			end
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
				   l_file.as_lower.ends_with ("." + l_ext) then
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
					set_error ("Failed to create directory: " + internal_path.name)
				end
			else
				Result := True -- Already exists
			end
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
					set_error ("Failed to create directory: " + internal_path.name)
				end
			else
				Result := True -- Already exists
			end
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
					set_error ("Failed to delete directory (not empty?): " + internal_path.name)
				end
			else
				set_error ("Directory does not exist: " + internal_path.name)
			end
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
					set_error ("Failed to delete directory: " + internal_path.name)
				end
			else
				set_error ("Directory does not exist: " + internal_path.name)
			end
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
				set_error ("File not readable: " + internal_path.name)
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
				set_error ("File not readable: " + internal_path.name)
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
				set_error ("File does not exist: " + internal_path.name)
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
				set_error ("File does not exist: " + internal_path.name)
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

	has_error: BOOLEAN
			-- Did last operation fail?
		do
			Result := not last_error.is_empty
		end

	last_error: STRING_32
			-- Description of last error, empty if none.

feature {NONE} -- Implementation

	internal_path: PATH
			-- Internal path object.

	reset_error
			-- Clear error state.
		do
			create last_error.make_empty
		end

	set_error (a_message: READABLE_STRING_GENERAL)
			-- Set error message.
		do
			last_error := a_message.to_string_32
		end

invariant
	path_not_void: internal_path /= Void
	error_not_void: last_error /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
