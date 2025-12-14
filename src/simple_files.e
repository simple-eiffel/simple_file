note
	description: "Expanded convenience class for common file operations"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

expanded class
	SIMPLE_FILES

feature -- Existence Checks

	file_exists (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Does file exist at `a_path'?
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			Result := l_file.exists and then l_file.is_plain
		end

	directory_exists (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Does directory exist at `a_path'?
		local
			l_dir: DIRECTORY
		do
			create l_dir.make (a_path)
			Result := l_dir.exists
		end

feature -- Quick Read

	read_text (a_path: READABLE_STRING_GENERAL): STRING_32
			-- Read entire file as text (UTF-8).
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.read_text
		end

	read_lines (a_path: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- Read all lines from file.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.read_lines
		end

	read_bytes (a_path: READABLE_STRING_GENERAL): ARRAY [NATURAL_8]
			-- Read file as bytes.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.read_bytes
		end

feature -- Quick Write

	write_text (a_path, a_content: READABLE_STRING_GENERAL): BOOLEAN
			-- Write content to file (overwrites).
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.write_text (a_content)
		end

	write_lines (a_path: READABLE_STRING_GENERAL; a_lines: LIST [READABLE_STRING_GENERAL]): BOOLEAN
			-- Write lines to file (overwrites).
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.write_lines (a_lines)
		end

	write_bytes (a_path: READABLE_STRING_GENERAL; a_bytes: ARRAY [NATURAL_8]): BOOLEAN
			-- Write bytes to file (overwrites).
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.write_bytes (a_bytes)
		end

	append_text (a_path, a_content: READABLE_STRING_GENERAL): BOOLEAN
			-- Append content to file.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.append_text (a_content)
		end

feature -- Quick Operations

	copy_file (a_source, a_dest: READABLE_STRING_GENERAL): BOOLEAN
			-- Copy file from source to destination.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_source)
			Result := l_sf.copy_to (a_dest)
		end

	move_file (a_source, a_dest: READABLE_STRING_GENERAL): BOOLEAN
			-- Move file from source to destination.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_source)
			Result := l_sf.move_to (a_dest)
		end

	delete_file (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Delete file at path.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.delete
		end

	ensure_directory (a_path: READABLE_STRING_GENERAL): BOOLEAN
			-- Create directory and parents if needed.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.create_directory_recursive
		end

feature -- Directory Listing

	list_files (a_path: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- List files in directory.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.files
		end

	list_directories (a_path: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- List subdirectories in directory.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.directories
		end

	list_all (a_path: READABLE_STRING_GENERAL): ARRAYED_LIST [STRING_32]
			-- List all entries in directory.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.entries
		end

feature -- Path Utilities

	join_path (a_parts: ARRAY [READABLE_STRING_GENERAL]): STRING_32
			-- Join path components.
		local
			l_path: PATH
			i: INTEGER
		do
			if a_parts.count > 0 then
				create l_path.make_from_string (a_parts [a_parts.lower].to_string_32)
				from
					i := a_parts.lower + 1
				until
					i > a_parts.upper
				loop
					l_path := l_path.extended (a_parts [i].to_string_32)
					i := i + 1
				end
				Result := l_path.name
			else
				create Result.make_empty
			end
		end

	parent_of (a_path: READABLE_STRING_GENERAL): STRING_32
			-- Get parent directory of path.
		local
			l_path: PATH
		do
			create l_path.make_from_string (a_path.to_string_32)
			Result := l_path.parent.name
		end

	extension_of (a_path: READABLE_STRING_GENERAL): STRING_32
			-- Get file extension.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.extension
		end

	base_name_of (a_path: READABLE_STRING_GENERAL): STRING_32
			-- Get file name without extension.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.base_name
		end

	file_name_of (a_path: READABLE_STRING_GENERAL): STRING_32
			-- Get file name with extension.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.file_name
		end

feature -- Temporary Files

	temp_directory: STRING_32
			-- Get system temp directory path.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.temporary_directory_path as l_temp then
				Result := l_temp.name
			else
				-- Fallback
				if {PLATFORM}.is_windows then
					Result := {STRING_32} "C:\Temp"
				else
					Result := {STRING_32} "/tmp"
				end
			end
		end

	temp_file_path (a_prefix: READABLE_STRING_GENERAL): STRING_32
			-- Generate unique temp file path with prefix.
		local
			l_rand: RANDOM
			l_time: SIMPLE_DATE_TIME
		do
			create l_time.make_now
			create l_rand.set_seed (l_time.to_timestamp.to_integer)
			l_rand.forth
			Result := temp_directory.twin
			Result.append_character ({OPERATING_ENVIRONMENT}.directory_separator)
			Result.append_string_general (a_prefix)
			Result.append_character ('_')
			Result.append_string_general (l_rand.item.abs.out)
			Result.append ({STRING_32} ".tmp")
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
