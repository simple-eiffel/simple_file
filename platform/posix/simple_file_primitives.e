note
	description: "[
		POSIX primitives behind SIMPLE_FILE and SIMPLE_FILES, for macOS and Linux.
		The C bodies are in Clib/simple_file_posix.h. Paths from NATIVE_STRING are
		UTF-8, and error codes are errno values.

		Attributes are mapped onto Windows-style bits so callers stay the same:
		a folder sets Attribute_directory, no write permission sets
		Attribute_readonly, and a leading dot reports hidden. Only read-only
		can be set.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_FILE_PRIMITIVES

inherit
	SIMPLE_FILE_OS

feature -- Constants

	Error_file_exists: INTEGER = 17
			-- EEXIST.

	Error_already_exists: INTEGER = 17
			-- EEXIST.

	Error_file_not_found: INTEGER = 2
			-- ENOENT.

	Error_no_more_files: INTEGER = 0xFFFE
			-- Set by `find_next' at the end of a listing; not an errno value.

	Error_short_write: INTEGER = 0xFFFF
			-- Reported when write wrote nothing without an OS error.

	Attribute_readonly: NATURAL_32 = 0x1
			-- Set when no write permission bit is on.

	Attribute_directory: NATURAL_32 = 0x10
			-- Set for a directory.

feature -- Writing

	write_new_file (a_path, a_data: POINTER; a_count: INTEGER; a_like_path: POINTER): INTEGER
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER) sfp_write_new_file ((const char *) $a_path, (const char *) $a_data, (int) $a_count, (const char *) $a_like_path);"
		end

	move_replace (a_source, a_target: POINTER): INTEGER
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER) sfp_move_replace ((const char *) $a_source, (const char *) $a_target);"
		end

	append_to_file (a_path, a_data: POINTER; a_count: INTEGER): INTEGER
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER) sfp_append ((const char *) $a_path, (const char *) $a_data, (int) $a_count);"
		end

	delete_file (a_path: POINTER): INTEGER
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER) sfp_delete ((const char *) $a_path);"
		end

feature -- Reading

	open_for_read (a_path, a_error: POINTER): POINTER
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_POINTER) sfp_open_read ((const char *) $a_path, (int *) $a_error);"
		end

	read_chunk (a_handle, a_buffer: POINTER; a_capacity: INTEGER): INTEGER
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER) sfp_read ((void *) $a_handle, (void *) $a_buffer, (int) $a_capacity);"
		end

	close_handle (a_handle: POINTER)
			-- <Precursor>
		external
			"C inline use %"simple_file_posix.h%""
		alias
			"sfp_close ((void *) $a_handle);"
		end

feature -- Status

	attributes (a_path: POINTER): INTEGER_64
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER_64) sfp_attributes ((const char *) $a_path);"
		end

	set_attributes (a_path: POINTER; a_attributes: NATURAL_32): INTEGER
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER) sfp_set_attributes ((const char *) $a_path, (unsigned int) $a_attributes);"
		end

	last_write_100ns (a_path: POINTER): INTEGER_64
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER_64) sfp_last_write_100ns ((const char *) $a_path);"
		end

feature -- Enumeration

	directory_pattern (a_directory: READABLE_STRING_32): STRING_32
			-- <Precursor>
		do
			create Result.make_from_string (a_directory)
		end

	find_data_size: INTEGER
			-- <Precursor>
		external
			"C inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER) sizeof (sfp_find_data);"
		end

	find_first (a_pattern, a_data, a_error: POINTER): POINTER
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_POINTER) sfp_find_first ((const char *) $a_pattern, (void *) $a_data, (int *) $a_error);"
		end

	find_next (a_handle, a_data, a_error: POINTER): BOOLEAN
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return sfp_find_next ((void *) $a_handle, (void *) $a_data, (int *) $a_error) ? EIF_TRUE : EIF_FALSE;"
		end

	find_close (a_handle: POINTER)
			-- <Precursor>
		external
			"C inline use %"simple_file_posix.h%""
		alias
			"sfp_find_close ((void *) $a_handle);"
		end

	find_data_name (a_data: POINTER): POINTER
			-- <Precursor>
		external
			"C inline use %"simple_file_posix.h%""
		alias
			"return (EIF_POINTER) ((sfp_find_data *) $a_data)->name;"
		end

	find_data_attributes (a_data: POINTER): NATURAL_32
			-- <Precursor>
		external
			"C inline use %"simple_file_posix.h%""
		alias
			"return (EIF_NATURAL_32) ((sfp_find_data *) $a_data)->attributes;"
		end

feature -- Bulk binary I/O

	read_block (a_path, a_dest: POINTER; a_offset: INTEGER_64; a_count: INTEGER): INTEGER
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER) sfp_read_block ((const char *) $a_path, (void *) $a_dest, (long long) $a_offset, (int) $a_count);"
		end

	write_block (a_path, a_source: POINTER; a_count, a_append: INTEGER): INTEGER
			-- <Precursor>
		external
			"C blocking inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER) sfp_write_block ((const char *) $a_path, (const void *) $a_source, (int) $a_count, (int) $a_append);"
		end

feature -- Process and errors

	current_process_id: NATURAL_32
			-- <Precursor>
		external
			"C inline use <unistd.h>"
		alias
			"return (EIF_NATURAL_32) getpid ();"
		end

	is_owner_running (a_pid: NATURAL_32; a_file: POINTER): BOOLEAN
			-- <Precursor>
			-- POSIX has no portable process start time, so a process that reused a
			-- dead owner's id still counts. The temporary file is then kept, not lost.
		external
			"C inline use %"simple_file_posix.h%""
		alias
			"return sfp_is_process_running ((unsigned int) $a_pid) ? EIF_TRUE : EIF_FALSE;"
		end

	performance_counter: INTEGER_64
			-- <Precursor>
		external
			"C inline use %"simple_file_posix.h%""
		alias
			"return (EIF_INTEGER_64) sfp_counter ();"
		end

	error_text (a_code: INTEGER): STRING_32
			-- "<system message> (errno `a_code')".
		do
			Result := (create {NATIVE_STRING}.make_from_pointer (c_error_message (a_code))).string
			Result.append ({STRING_32} " (errno ")
			Result.append (a_code.out)
			Result.append_character (')')
		end

feature {NONE} -- Implementation

	c_error_message (a_code: INTEGER): POINTER
			-- Text of errno `a_code'.
		external
			"C inline use <string.h>"
		alias
			"return (EIF_POINTER) strerror ((int) $a_code);"
		end

note
	copyright: "Copyright (c) 2024-2026, Larry Rix"
	license: "MIT License"

end
