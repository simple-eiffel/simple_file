note
	description: "Fluent path builder for easy path construction"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_PATH

create
	make,
	make_from,
	make_current,
	make_temp,
	make_home

feature {NONE} -- Initialization

	make
			-- Create empty path.
		do
			create internal_path.make_empty
		end

	make_from (a_path: READABLE_STRING_GENERAL)
			-- Create from string.
		do
			create internal_path.make_from_string (a_path.to_string_32)
		end

	make_current
			-- Create for current directory.
		do
			create internal_path.make_current
		end

	make_temp
			-- Create for temp directory.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.temporary_directory_path as l_temp then
				internal_path := l_temp
			else
				if {PLATFORM}.is_windows then
					create internal_path.make_from_string ("C:\Temp")
				else
					create internal_path.make_from_string ("/tmp")
				end
			end
		end

	make_home
			-- Create for home directory.
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.home_directory_path as l_home then
				internal_path := l_home
			else
				create internal_path.make_current
			end
		end

feature -- Fluent Building

	add (a_component: READABLE_STRING_GENERAL): SIMPLE_PATH
			-- Add path component. Returns self for chaining.
		do
			internal_path := internal_path.extended (a_component.to_string_32)
			Result := Current
		end

	joined alias "/" (a_component: READABLE_STRING_GENERAL): SIMPLE_PATH
			-- Add path component (alias for add). Returns self for chaining.
		do
			Result := add (a_component)
		end

	up: SIMPLE_PATH
			-- Go to parent directory. Returns self for chaining.
		do
			internal_path := internal_path.parent
			Result := Current
		end

	with_extension (a_ext: READABLE_STRING_GENERAL): SIMPLE_PATH
			-- Change or add extension. Returns self for chaining.
		local
			l_name: STRING_32
			l_dot: INTEGER
			l_new_name: STRING_32
		do
			if attached internal_path.entry as l_entry then
				l_name := l_entry.name
				l_dot := l_name.last_index_of ('.', l_name.count)
				if l_dot > 1 then
					l_new_name := l_name.substring (1, l_dot - 1)
				else
					l_new_name := l_name.twin
				end
				l_new_name.append_character ('.')
				l_new_name.append_string_general (a_ext)
				internal_path := internal_path.parent.extended (l_new_name)
			end
			Result := Current
		end

	without_extension: SIMPLE_PATH
			-- Remove extension. Returns self for chaining.
		local
			l_name: STRING_32
			l_dot: INTEGER
			l_new_name: STRING_32
		do
			if attached internal_path.entry as l_entry then
				l_name := l_entry.name
				l_dot := l_name.last_index_of ('.', l_name.count)
				if l_dot > 1 then
					l_new_name := l_name.substring (1, l_dot - 1)
					internal_path := internal_path.parent.extended (l_new_name)
				end
			end
			Result := Current
		end

feature -- Access

	to_string: STRING_32
			-- Get path as string.
		do
			Result := internal_path.name
		end

	to_path: PATH
			-- Get as PATH object.
		do
			Result := internal_path
		end

	to_file: SIMPLE_FILE
			-- Create SIMPLE_FILE for this path.
		do
			create Result.make_with_path (internal_path)
		end

feature -- Status

	exists: BOOLEAN
			-- Does path exist?
		local
			l_file: RAW_FILE
			l_dir: DIRECTORY
		do
			create l_file.make_with_path (internal_path)
			create l_dir.make_with_path (internal_path)
			Result := l_file.exists or l_dir.exists
		end

	is_file: BOOLEAN
			-- Is this a regular file?
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_path (internal_path)
			Result := l_file.exists and then l_file.is_plain
		end

	is_directory: BOOLEAN
			-- Is this a directory?
		local
			l_dir: DIRECTORY
		do
			create l_dir.make_with_path (internal_path)
			Result := l_dir.exists
		end

	is_absolute: BOOLEAN
			-- Is this an absolute path?
		do
			Result := internal_path.is_absolute
		end

	is_empty: BOOLEAN
			-- Is path empty?
		do
			Result := internal_path.is_empty
		end

feature -- Components

	parent: SIMPLE_PATH
			-- Parent directory as new SIMPLE_PATH.
		do
			create Result.make_from (internal_path.parent.name)
		end

	file_name: STRING_32
			-- File name component.
		do
			if attached internal_path.entry as l_entry then
				Result := l_entry.name
			else
				Result := internal_path.name
			end
		end

	extension: STRING_32
			-- File extension (without dot).
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

	stem: STRING_32
			-- File name without extension (Python pathlib term).
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

feature -- Path Transformation

	resolve: SIMPLE_PATH
			-- Canonical absolute path (requires file to exist).
		do
			create Result.make_from (internal_path.canonical_path.name)
		end

	normalize: STRING_32
			-- Normalize path (remove . and ..) without requiring existence.
		local
			l_parts: LIST [READABLE_STRING_32]
			l_result: ARRAYED_LIST [STRING_32]
			l_sep: CHARACTER_32
		do
			l_sep := {OPERATING_ENVIRONMENT}.directory_separator
			l_parts := internal_path.name.split (l_sep)
			create l_result.make (l_parts.count)
			across l_parts as p loop
				if p.item.same_string (".") then
					-- Skip current dir
				elseif p.item.same_string ("..") then
					if not l_result.is_empty and then not l_result.last.same_string ("..") then
						l_result.finish
						l_result.remove
					else
						l_result.extend ({STRING_32} "..")
					end
				elseif not p.item.is_empty then
					l_result.extend (p.item.to_string_32)
				end
			end

			create Result.make_empty
			across l_result as r loop
				if not Result.is_empty then
					Result.append_character (l_sep)
				end
				Result.append (r.item)
			end
		end

	absolute: SIMPLE_PATH
			-- Make absolute path.
		do
			create Result.make_from (internal_path.absolute_path.name)
		end

feature {NONE} -- Implementation

	internal_path: PATH
			-- Internal path storage.

invariant
	path_not_void: internal_path /= Void

note
	copyright: "Copyright (c) 2024-2025, Larry Rix"
	license: "MIT License"

end
