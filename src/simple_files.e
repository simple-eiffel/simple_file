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

	read_text_utf_8 (a_path: READABLE_STRING_GENERAL): STRING_32
			-- Read entire file decoded from UTF-8, exactly as stored
			-- (see {SIMPLE_FILE}.read_text_utf_8).
		require
			path_not_empty: not a_path.is_empty
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.read_text_utf_8
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
			-- Write content to file (overwrites), atomically.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.write_text (a_content)
		end

	write_text_utf_8 (a_path, a_content: READABLE_STRING_GENERAL): BOOLEAN
			-- Write content as UTF-8 exactly, atomically (overwrites)
			-- (see {SIMPLE_FILE}.write_text_utf_8).
		require
			path_not_empty: not a_path.is_empty
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (a_path)
			Result := l_sf.write_text_utf_8 (a_content)
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

feature -- File Names

	file_safe_name (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text' made usable as one Windows file name:
			-- each of < > : " / \ | ? *, each control character (U+0000 to
			-- U+001F) and each surrogate or out-of-range code becomes '_';
			-- trailing dots and spaces are dropped (Windows would drop them
			-- silently); a reserved device name (CON, PRN, AUX, NUL, COM0-COM9,
			-- LPT0-LPT9, also COM and LPT with a superscript 1, 2 or 3; in any
			-- case, with or without an extension) gets '_' after its stem
			-- ("con.txt" becomes "con_.txt"); a name longer than
			-- `Max_file_name_length' UTF-16 units is cut, keeping an extension
			-- of up to 16 characters; an empty result becomes "_".
			-- Not reversible: different texts can give the same name, so add
			-- an id where names must be unique.
		local
			l_code: NATURAL_32
			i: INTEGER
		do
			create Result.make (a_text.count)
			from
				i := 1
			until
				i > a_text.count
			loop
				l_code := a_text.code (i)
				if l_code < 32 or l_code > 0x10FFFF or (0xD800 <= l_code and l_code <= 0xDFFF) or Reserved_characters.has (l_code.to_character_32) then
					Result.append_character (Replacement_character)
				else
					Result.append_code (l_code)
				end
				i := i + 1
			end
			drop_trailing_dots_and_spaces (Result)
			if Result.is_empty then
				Result.append_character (Replacement_character)
			end
			if is_reserved_device_name (Result) then
				Result.insert_character (Replacement_character, stem_end (Result) + 1)
			end
			if utf_16_length (Result) > Max_file_name_length then
				cut_to_length (Result)
				drop_trailing_dots_and_spaces (Result)
				if Result.is_empty then
					Result.append_character (Replacement_character)
				end
			end
		ensure
			safe: is_file_safe_name (Result)
			safe_text_unchanged: is_file_safe_name (a_text) implies Result.same_string_general (a_text)
		end

	is_file_safe_name (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_name' be used as one Windows file name as it stands:
			-- not empty, none of the characters `file_safe_name' replaces, no
			-- trailing dot or space, not a reserved device name, at most
			-- `Max_file_name_length' UTF-16 units?
		local
			l_code: NATURAL_32
			l_last: CHARACTER_32
			l_name: STRING_32
			i: INTEGER
		do
			if not a_name.is_empty then
				l_name := a_name.to_string_32
				Result := True
				from
					i := 1
				until
					i > l_name.count or not Result
				loop
					l_code := l_name.code (i)
					Result := not (l_code < 32 or l_code > 0x10FFFF or (0xD800 <= l_code and l_code <= 0xDFFF) or Reserved_characters.has (l_name [i]))
					i := i + 1
				end
				if Result then
					l_last := l_name [l_name.count]
					Result := l_last /= '.' and l_last /= ' ' and then not is_reserved_device_name (l_name) and then utf_16_length (l_name) <= Max_file_name_length
				end
			end
		end

	Max_file_name_length: INTEGER = 255
			-- Longest file name NTFS accepts, in UTF-16 units.

feature {NONE} -- File name implementation

	Reserved_characters: STRING_32
			-- Characters Windows forbids in a file name.
		once
			Result := {STRING_32} "<>:%"/\|?*"
		end

	Replacement_character: CHARACTER_32 = '_'
			-- Stands in for each forbidden character.

	Reserved_device_names: ARRAYED_LIST [STRING_32]
			-- Device names Windows reserves, in upper case: CON, PRN, AUX,
			-- NUL, COM0-COM9, LPT0-LPT9, and COM and LPT followed by a
			-- superscript 1, 2 or 3 (U+00B9, U+00B2, U+00B3).
		local
			l_name: STRING_32
		once
			create Result.make (30)
			Result.extend ({STRING_32} "CON")
			Result.extend ({STRING_32} "PRN")
			Result.extend ({STRING_32} "AUX")
			Result.extend ({STRING_32} "NUL")
			across << {STRING_32} "COM", {STRING_32} "LPT" >> as ic_port loop
				across << 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0xB9, 0xB2, 0xB3 >> as ic_digit loop
					l_name := ic_port.twin
					l_name.append_code (ic_digit.to_natural_32)
					Result.extend (l_name)
				end
			end
		ensure
			thirty_names: Result.count = 30
		end

	stem_end (a_name: READABLE_STRING_32): INTEGER
			-- Index of the last character before the first dot of `a_name'
			-- (its whole count if it has no dot).
		do
			Result := a_name.index_of ('.', 1) - 1
			if Result < 0 then
				Result := a_name.count
			end
		ensure
			in_range: 0 <= Result and Result <= a_name.count
		end

	is_reserved_device_name (a_name: READABLE_STRING_32): BOOLEAN
			-- Is the stem of `a_name' (before its first dot, trailing spaces
			-- ignored) a reserved device name, in any case?
		local
			l_stem: STRING_32
		do
			l_stem := a_name.substring (1, stem_end (a_name)).to_string_32
			l_stem.right_adjust
			l_stem.to_upper
			Result := across Reserved_device_names as ic some ic.same_string (l_stem) end
		end

	drop_trailing_dots_and_spaces (a_name: STRING_32)
			-- Remove dots and spaces from the end of `a_name'.
		do
			from
			until
				a_name.is_empty or else not (a_name [a_name.count] = '.' or a_name [a_name.count] = ' ')
			loop
				a_name.remove_tail (1)
			end
		ensure
			no_trailing: not a_name.is_empty implies (a_name [a_name.count] /= '.' and a_name [a_name.count] /= ' ')
		end

	utf_16_length (a_name: READABLE_STRING_32): INTEGER
			-- Length of `a_name' in UTF-16 units.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_name.count
			loop
				if a_name.code (i) > 0xFFFF then
					Result := Result + 2
				else
					Result := Result + 1
				end
				i := i + 1
			end
		ensure
			at_least_count: Result >= a_name.count
		end

	cut_to_length (a_name: STRING_32)
			-- Cut `a_name' to `Max_file_name_length' UTF-16 units, keeping an
			-- extension (from the last dot) of up to 16 characters.
		local
			l_extension: STRING_32
			l_dot, l_length: INTEGER
		do
			l_dot := a_name.last_index_of ('.', a_name.count)
			if l_dot > 1 and then a_name.count - l_dot + 1 <= 16 then
				l_extension := a_name.substring (l_dot, a_name.count)
				a_name.keep_head (l_dot - 1)
			else
				create l_extension.make_empty
			end
			from
				l_length := utf_16_length (a_name) + utf_16_length (l_extension)
			until
				l_length <= Max_file_name_length or a_name.is_empty
			loop
				if a_name.code (a_name.count) > 0xFFFF then
					l_length := l_length - 2
				else
					l_length := l_length - 1
				end
				a_name.remove_tail (1)
			end
			a_name.append (l_extension)
		ensure
			short_enough: utf_16_length (a_name) <= Max_file_name_length
		end

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
