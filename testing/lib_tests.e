note
	description: "Tests for SIMPLE_FILE"
	author: "Larry Rix"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Tests

	test_file_exists
			-- Test file existence check.
		local
			l_sf: SIMPLE_FILE
			l_files: SIMPLE_FILES
		do
			create l_sf.make ("nonexistent_file_12345.txt")
			assert_false ("nonexistent file", l_sf.exists)
			assert_false ("nonexistent via expanded", l_files.file_exists ("nonexistent_file_12345.txt"))
		end

	test_directory_exists
			-- Test directory existence check.
		local
			l_sf: SIMPLE_FILE
			l_files: SIMPLE_FILES
		do
			create l_sf.make (".")
			assert_true ("current dir exists", l_sf.is_directory)
			assert_true ("current dir via expanded", l_files.directory_exists ("."))
		end

	test_write_and_read_text
			-- Test writing and reading text.
		local
			l_sf: SIMPLE_FILE
			l_content: STRING_32
			l_read: STRING_32
			l_ignore: BOOLEAN
		do
			l_content := {STRING_32} "Hello, World! Simple text test."
			create l_sf.make (temp_file_path ("text_test"))

			assert_true ("write succeeded", l_sf.write_text (l_content))
			assert_true ("file exists after write", l_sf.exists)

			l_read := l_sf.read_text
			assert_false ("no read error", l_sf.has_error)
			assert_true ("content matches", l_read.same_string (l_content))

			l_ignore := l_sf.delete
		end

	test_write_and_read_lines
			-- Test writing and reading lines.
		local
			l_sf: SIMPLE_FILE
			l_lines: ARRAYED_LIST [STRING_32]
			l_read: ARRAYED_LIST [STRING_32]
			l_ignore: BOOLEAN
		do
			create l_lines.make (3)
			l_lines.extend ({STRING_32} "Line 1")
			l_lines.extend ({STRING_32} "Line 2")
			l_lines.extend ({STRING_32} "Line 3")

			create l_sf.make (temp_file_path ("lines_test"))

			assert_true ("write lines succeeded", l_sf.write_lines (l_lines))

			l_read := l_sf.read_lines
			assert_false ("no read error", l_sf.has_error)
			assert_integers_equal ("line count", 3, l_read.count)
			assert_strings_equal ("first line", "Line 1", l_read [1].out)
			assert_strings_equal ("third line", "Line 3", l_read [3].out)

			l_ignore := l_sf.delete
		end

	test_write_and_read_bytes
			-- Test writing and reading bytes.
		local
			l_sf: SIMPLE_FILE
			l_bytes: ARRAY [NATURAL_8]
			l_read: ARRAY [NATURAL_8]
			l_ignore: BOOLEAN
		do
			l_bytes := <<0, 1, 2, 255, 128, 64>>
			create l_sf.make (temp_file_path ("bytes_test"))

			assert_true ("write bytes succeeded", l_sf.write_bytes (l_bytes))

			l_read := l_sf.read_bytes
			assert_false ("no read error", l_sf.has_error)
			assert_integers_equal ("byte count", 6, l_read.count)
			assert_integers_equal ("first byte", 0, l_read [1].to_integer_32)
			assert_integers_equal ("fourth byte", 255, l_read [4].to_integer_32)

			l_ignore := l_sf.delete
		end

	test_append_text
			-- Test appending text.
		local
			l_sf: SIMPLE_FILE
			l_read: STRING_32
			l_ignore: BOOLEAN
		do
			create l_sf.make (temp_file_path ("append_test"))

			assert_true ("initial write", l_sf.write_text ("Hello"))
			assert_true ("append succeeded", l_sf.append_text (", World!"))

			l_read := l_sf.read_text
			assert_strings_equal ("appended content", "Hello, World!", l_read.out)

			l_ignore := l_sf.delete
		end

	test_file_metadata
			-- Test file metadata access.
		local
			l_sf: SIMPLE_FILE
			l_ignore: BOOLEAN
		do
			create l_sf.make (temp_file_path ("meta_test"))
			l_ignore := l_sf.write_text ("Test content for metadata")

			assert_true ("size > 0", l_sf.size > 0)
			assert_true ("has modified timestamp", l_sf.modified_timestamp > 0)
			assert_strings_equal ("extension", "tmp", l_sf.extension.out)
			assert_true ("base name not empty", not l_sf.base_name.is_empty)
			assert_true ("file name not empty", not l_sf.file_name.is_empty)
			assert_true ("is file", l_sf.is_file)
			assert_false ("is not directory", l_sf.is_directory)

			l_ignore := l_sf.delete
		end

	test_copy_file
			-- Test file copy.
		local
			l_sf: SIMPLE_FILE
			l_dest: SIMPLE_FILE
			l_dest_path: STRING_32
			l_ignore: BOOLEAN
		do
			create l_sf.make (temp_file_path ("copy_src"))
			l_ignore := l_sf.write_text ("Content to copy")

			l_dest_path := temp_file_path ("copy_dest")
			assert_true ("copy succeeded", l_sf.copy_to (l_dest_path))

			create l_dest.make (l_dest_path)
			assert_true ("dest exists", l_dest.exists)
			assert_strings_equal ("content copied", "Content to copy", l_dest.read_text.out)

			l_ignore := l_sf.delete
			l_ignore := l_dest.delete
		end

	test_move_file
			-- Test file move/rename.
		local
			l_sf: SIMPLE_FILE
			l_dest_path: STRING_32
			l_dest: SIMPLE_FILE
			l_ignore: BOOLEAN
		do
			create l_sf.make (temp_file_path ("move_src"))
			l_ignore := l_sf.write_text ("Content to move")

			l_dest_path := temp_file_path ("move_dest")
			assert_true ("move succeeded", l_sf.move_to (l_dest_path))

			create l_dest.make (l_dest_path)
			assert_true ("dest exists", l_dest.exists)

			l_ignore := l_dest.delete
		end

	test_delete_file
			-- Test file deletion.
		local
			l_sf: SIMPLE_FILE
			l_ignore: BOOLEAN
		do
			create l_sf.make (temp_file_path ("delete_test"))
			l_ignore := l_sf.write_text ("To be deleted")
			assert_true ("file exists", l_sf.exists)

			assert_true ("delete succeeded", l_sf.delete)
			assert_false ("file gone", l_sf.exists)
		end

	test_create_directory
			-- Test directory creation.
		local
			l_sf: SIMPLE_FILE
			l_dir_path: STRING_32
		do
			l_dir_path := temp_file_path ("test_dir")
			create l_sf.make (l_dir_path)

			assert_true ("create dir succeeded", l_sf.create_directory)
			assert_true ("dir exists", l_sf.is_directory)

			assert_true ("delete dir succeeded", l_sf.delete_directory)
		end

	test_list_directory
			-- Test directory listing.
		local
			l_sf: SIMPLE_FILE
			l_dir_path: STRING_32
			l_file1, l_file2: SIMPLE_FILE
			l_entries: ARRAYED_LIST [STRING_32]
			l_ignore: BOOLEAN
		do
			l_dir_path := temp_file_path ("list_dir")
			create l_sf.make (l_dir_path)
			l_ignore := l_sf.create_directory

			create l_file1.make (l_dir_path + {STRING_32} "/" + {STRING_32} "file1.txt")
			l_ignore := l_file1.write_text ("File 1")
			create l_file2.make (l_dir_path + {STRING_32} "/" + {STRING_32} "file2.txt")
			l_ignore := l_file2.write_text ("File 2")

			l_entries := l_sf.entries
			assert_integers_equal ("entry count", 2, l_entries.count)

			l_entries := l_sf.files
			assert_integers_equal ("file count", 2, l_entries.count)

			l_ignore := l_file1.delete
			l_ignore := l_file2.delete
			l_ignore := l_sf.delete_directory
		end

	test_files_with_extension
			-- Test filtering files by extension.
		local
			l_sf: SIMPLE_FILE
			l_dir_path: STRING_32
			l_file1, l_file2, l_file3: SIMPLE_FILE
			l_txt_files: ARRAYED_LIST [STRING_32]
			l_ignore: BOOLEAN
		do
			l_dir_path := temp_file_path ("ext_dir")
			create l_sf.make (l_dir_path)
			l_ignore := l_sf.create_directory

			create l_file1.make (l_dir_path + {STRING_32} "/" + {STRING_32} "file1.txt")
			l_ignore := l_file1.write_text ("Text file")
			create l_file2.make (l_dir_path + {STRING_32} "/" + {STRING_32} "file2.txt")
			l_ignore := l_file2.write_text ("Text file 2")
			create l_file3.make (l_dir_path + {STRING_32} "/" + {STRING_32} "file3.dat")
			l_ignore := l_file3.write_text ("Data file")

			l_txt_files := l_sf.files_with_extension ("txt")
			assert_integers_equal ("txt file count", 2, l_txt_files.count)

			l_ignore := l_file1.delete
			l_ignore := l_file2.delete
			l_ignore := l_file3.delete
			l_ignore := l_sf.delete_directory
		end

	test_expanded_convenience
			-- Test expanded class convenience methods.
		local
			l_files: SIMPLE_FILES
			l_path: STRING_32
			l_content: STRING_32
			l_ignore: BOOLEAN
		do
			l_path := temp_file_path ("expanded_test")

			assert_true ("expanded write", l_files.write_text (l_path, "Expanded test"))

			l_content := l_files.read_text (l_path)
			assert_strings_equal ("expanded read", "Expanded test", l_content.out)

			assert_strings_equal ("extension", "tmp", l_files.extension_of (l_path).out)
			assert_true ("parent not empty", not l_files.parent_of (l_path).is_empty)

			assert_true ("join not empty", not l_files.join_path (<<"a", "b", "c">>).is_empty)

			l_ignore := l_files.delete_file (l_path)
		end

feature {NONE} -- Helpers

	temp_file_path (a_prefix: READABLE_STRING_GENERAL): STRING_32
			-- Generate temp file path for testing.
		local
			l_files: SIMPLE_FILES
		do
			Result := l_files.temp_file_path (a_prefix)
		end

end
