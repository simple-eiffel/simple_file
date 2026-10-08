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
			l_bytes := {ARRAY [NATURAL_8]} <<0, 1, 2, 255, 128, 64>>
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

			assert_true ("join not empty", not l_files.join_path ({ARRAY [READABLE_STRING_GENERAL]} <<"a", "b", "c">>).is_empty)

			l_ignore := l_files.delete_file (l_path)
		end

feature -- Tests: D10 atomic replacing write

	test_write_text_bytes_as_before
			-- The atomic write puts the same bytes on disk as 1.0's
			-- PLAIN_TEXT_FILE did (bytes captured from 1.0 by a probe).
		local
			l_sf: SIMPLE_FILE
			l_s8: STRING_8
			l_s32: STRING_32
			l_lines: ARRAYED_LIST [STRING_32]
			l_ignore: BOOLEAN
		do
			create l_sf.make (temp_file_path ("bytes_as_before"))
			assert_true ("lf write", l_sf.write_text ({STRING_32} "a%Nb"))
			assert_strings_equal ("lf becomes crlf", "61 0D 0A 62", hex (l_sf.read_bytes))
			assert_true ("crlf write", l_sf.write_text ({STRING_32} "a%R%Nb%N"))
			assert_strings_equal ("cr kept, lf doubled as 1.0", "61 0D 0D 0A 62 0D 0A", hex (l_sf.read_bytes))
			create l_s8.make_empty
			l_s8.append_character ('x')
			l_s8.append_character ((0xE9).to_character_8)
			l_s8.append_character ((0xFF).to_character_8)
			assert_true ("latin write", l_sf.write_text (l_s8))
			assert_strings_equal ("latin-1 code points as UTF-8", "78 C3 A9 C3 BF", hex (l_sf.read_bytes))
			create l_s32.make_empty
			l_s32.append_code (0x5D1)
			l_s32.append_code (0x1F600)
			l_s32.append_code (0)
			l_s32.append_code (0x41)
			assert_true ("unicode write", l_sf.write_text (l_s32))
			assert_strings_equal ("utf-8 incl. non-BMP and NUL", "D7 91 F0 9F 98 80 00 41", hex (l_sf.read_bytes))
			create l_lines.make (2)
			l_lines.extend ({STRING_32} "x")
			l_lines.extend ({STRING_32} "y")
			assert_true ("lines write", l_sf.write_lines (l_lines))
			assert_strings_equal ("lines bytes", "78 0D 0A 79 0D 0A", hex (l_sf.read_bytes))
			assert_true ("p", l_sf.write_text ("p"))
			assert_true ("append text", l_sf.append_text ({STRING_32} "q%Nr"))
			assert_true ("append line", l_sf.append_line ("s"))
			assert_strings_equal ("append bytes", "70 71 0D 0A 72 73 0D 0A", hex (l_sf.read_bytes))
			assert_true ("empty write", l_sf.write_text (""))
			assert_integers_equal ("empty file", 0, l_sf.size.to_integer_32)
			l_ignore := l_sf.delete
		end

	test_write_text_leaves_no_temporary
			-- Repeated replacing writes leave exactly the target in the folder.
		local
			l_dir, l_sf: SIMPLE_FILE
			l_lines: ARRAYED_LIST [STRING_32]
			i: INTEGER
			l_ignore: BOOLEAN
		do
			create l_dir.make (temp_file_path ("no_temp_dir"))
			assert_true ("dir", l_dir.create_directory)
			create l_sf.make (l_dir.path.extended ("note.md").name)
			from i := 1 until i > 25 loop
				assert_true ("write " + i.out, l_sf.write_text ("version " + i.out))
				i := i + 1
			end
			assert_true ("bytes", l_sf.write_bytes ({ARRAY [NATURAL_8]} <<65, 66>>))
			create l_lines.make (1)
			l_lines.extend ({STRING_32} "last")
			assert_true ("lines", l_sf.write_lines (l_lines))
			assert_integers_equal ("only the target", 1, l_dir.entries.count)
			assert_strings_equal ("the target", "note.md", l_dir.entries.first.to_string_8)
			assert_strings_equal ("last content", "last", l_sf.read_text.to_string_8)
			l_ignore := l_dir.delete_directory_recursive
		end

	test_write_text_failure_keeps_old_content
			-- A replace that the OS refuses (target held open without delete
			-- sharing) returns False with the Win32 error, leaves the old
			-- content whole and removes its temporary file. In 1.0 this
			-- raised OPERATING_SYSTEM_FAILURE (S-F2-1 T7).
		local
			l_dir, l_sf: SIMPLE_FILE
			l_holder: RAW_FILE
			l_ok: BOOLEAN
			l_ignore: BOOLEAN
		do
			create l_dir.make (temp_file_path ("held_dir"))
			assert_true ("dir", l_dir.create_directory)
			create l_sf.make (l_dir.path.extended ("held.md").name)
			assert_true ("old written", l_sf.write_text ("old content"))
			create l_holder.make_with_path (l_sf.path)
			l_holder.open_read
			l_ok := l_sf.write_text ("new content")
			l_holder.close
			assert_false ("replace refused", l_ok)
			assert_true ("error reported", l_sf.has_error)
			assert_true ("win32 code kept", l_sf.last_error_code /= 0)
			assert_string_contains ("message names the code", l_sf.last_error, "Win32 error")
			assert_strings_equal ("old content intact", "old content", l_sf.read_text.to_string_8)
			assert_integers_equal ("temporary removed", 1, l_dir.entries.count)
			assert_true ("next write works", l_sf.write_text ("new content"))
			assert_strings_equal ("new content", "new content", l_sf.read_text.to_string_8)
			l_ignore := l_dir.delete_directory_recursive
		end

	test_write_text_keeps_hidden_attribute
			-- Replacing a hidden file keeps it hidden.
		local
			l_dir, l_sf: SIMPLE_FILE
			l_win32: SIMPLE_FILE_WIN32
			l_path: NATIVE_STRING
			l_ignore: BOOLEAN
		do
			create l_win32
			create l_dir.make (temp_file_path ("hidden_dir"))
			assert_true ("dir", l_dir.create_directory)
			create l_sf.make (l_dir.path.extended ("hidden.md").name)
			assert_true ("first", l_sf.write_text ("one"))
			create l_path.make (l_sf.path_string)
			assert_integers_equal ("hide", 0, l_win32.set_attributes (l_path.item, {NATURAL_32} 0x2))
			assert_true ("replace hidden", l_sf.write_text ("two"))
			assert_true ("still hidden", (l_win32.attributes (l_path.item) & 0x2) /= 0)
			assert_strings_equal ("content", "two", l_sf.read_text.to_string_8)
			l_ignore := l_dir.delete_directory_recursive
		end

	test_remove_stale_temporaries
			-- A temporary left by a dead process is swept; one of this
			-- process and every other file are kept.
		local
			l_dir, l_sf: SIMPLE_FILE
			l_win32: SIMPLE_FILE_WIN32
			l_own: STRING_32
			l_ignore: BOOLEAN
		do
			create l_win32
			create l_dir.make (temp_file_path ("sweep_dir"))
			assert_true ("dir", l_dir.create_directory)
			create l_sf.make (l_dir.path.extended (".~sf00000001_1A2B.tmp").name)
			assert_true ("dead temp", l_sf.write_text ("left by a kill"))
			l_own := {STRING_32} ".~sf" + l_win32.current_process_id.to_hex_string + {STRING_32} "_77.tmp"
			create l_sf.make (l_dir.path.extended (l_own).name)
			assert_true ("own temp", l_sf.write_text ("mine"))
			create l_sf.make (l_dir.path.extended (".~sfZZ_1.tmp").name)
			assert_true ("not a temp name", l_sf.write_text ("other"))
			create l_sf.make (l_dir.path.extended ("note.md").name)
			assert_true ("note", l_sf.write_text ("note"))
			assert_integers_equal ("one removed", 1, l_dir.remove_stale_temporaries)
			assert_false ("no error", l_dir.has_error)
			assert_integers_equal ("three kept", 3, l_dir.entries.count)
			l_ignore := l_dir.delete_directory_recursive
		end

feature -- Tests: D11 ReadOnly-attribute folder

	test_readonly_folder_creates_files
			-- A folder carrying the ReadOnly attribute (as OneDrive sets it)
			-- does not stop file creation on Windows, so neither does
			-- simple_file (1.0 created 0 of 20 here).
		local
			l_dir, l_sf, l_src: SIMPLE_FILE
			l_win32: SIMPLE_FILE_WIN32
			l_dir_native: NATIVE_STRING
			l_lines: ARRAYED_LIST [STRING_32]
			i, l_written: INTEGER
			l_ignore: BOOLEAN
		do
			create l_win32
			create l_src.make (temp_file_path ("ro_source"))
			assert_true ("source", l_src.write_text ("copied"))
			create l_dir.make (temp_file_path ("ro_dir"))
			assert_true ("dir", l_dir.create_directory)
			create l_dir_native.make (l_dir.path_string)
			assert_integers_equal ("set ReadOnly", 0, l_win32.set_attributes (l_dir_native.item, {NATURAL_32} 0x1))
			assert_true ("attribute set", (l_win32.attributes (l_dir_native.item) & 0x1) /= 0)
			from i := 1 until i > 20 loop
				create l_sf.make (l_dir.path.extended ("note_" + i.out + ".md").name)
				if l_sf.write_text ("body " + i.out) and then l_sf.exists then
					l_written := l_written + 1
				end
				i := i + 1
			end
			assert_integers_equal ("20 of 20 written", 20, l_written)
			create l_sf.make (l_dir.path.extended ("appended.md").name)
			assert_true ("append creates", l_sf.append_text ("a"))
			create l_sf.make (l_dir.path.extended ("bytes.bin").name)
			assert_true ("write_bytes", l_sf.write_bytes ({ARRAY [NATURAL_8]} <<1, 2, 3>>))
			create l_sf.make (l_dir.path.extended ("lines.txt").name)
			create l_lines.make (1)
			l_lines.extend ({STRING_32} "one")
			assert_true ("write_lines", l_sf.write_lines (l_lines))
			create l_sf.make (l_dir.path.extended ("empty.txt").name)
			assert_true ("create_if_missing", l_sf.create_if_missing)
			create l_sf.make (l_dir.path.extended ("utf8.md").name)
			assert_true ("write_text_utf_8", l_sf.write_text_utf_8 ("u"))
			assert_true ("copy_to", l_src.copy_to (l_dir.path.extended ("copy.md").name))
			assert_integers_equal ("26 files", 26, l_dir.files.count)
			assert_true ("still ReadOnly", (l_win32.attributes (l_dir_native.item) & 0x1) /= 0)
			l_ignore := l_win32.set_attributes (l_dir_native.item, {NATURAL_32} 0x80) = 0
			l_ignore := l_dir.delete_directory_recursive
			l_ignore := l_src.delete
		end

	test_write_failure_is_reported
			-- A write that cannot happen (missing parent folder) returns False
			-- with a reason; nothing is raised.
		local
			l_sf: SIMPLE_FILE
		do
			create l_sf.make (temp_file_path ("missing_parent") + {STRING_32} "\no\such\note.md")
			assert_false ("write refused", l_sf.write_text ("x"))
			assert_true ("error", l_sf.has_error)
			assert_true ("path not found code", l_sf.last_error_code = 3 or l_sf.last_error_code = 2)
			assert_false ("append refused", l_sf.append_text ("x"))
			assert_true ("append error", l_sf.has_error)
			assert_false ("create refused", l_sf.create_if_missing)
			assert_true ("create error", l_sf.has_error)
		end

feature -- Tests: D12 ':' in names, file_safe_name

	test_stream_names_refused
			-- "John 3:16.md" would land in stream "16.md" of a 0-byte file
			-- "John 3" (1.0 did that and returned True). Every write refuses it.
		local
			l_dir, l_sf, l_src: SIMPLE_FILE
			l_bad: STRING_32
			l_ignore: BOOLEAN
		do
			create l_dir.make (temp_file_path ("colon_dir"))
			assert_true ("dir", l_dir.create_directory)
			l_bad := l_dir.path_string + {STRING_32} "\John 3:16.md"
			create l_sf.make (l_bad)
			assert_true ("is stream path", l_sf.is_stream_path)
			assert_false ("write_text refused", l_sf.write_text ("In the beginning"))
			assert_string_contains ("reason", l_sf.last_error, "alternate data stream")
			assert_false ("write_text_utf_8 refused", l_sf.write_text_utf_8 ("x"))
			assert_false ("write_bytes refused", l_sf.write_bytes ({ARRAY [NATURAL_8]} <<1>>))
			assert_false ("append refused", l_sf.append_text ("x"))
			assert_true ("append error", l_sf.has_error)
			assert_false ("create refused", l_sf.create_if_missing)
			assert_true ("create error", l_sf.has_error)
			create l_src.make (l_dir.path.extended ("source.md").name)
			assert_true ("source", l_src.write_text ("s"))
			assert_false ("copy refused", l_src.copy_to (l_bad))
			assert_true ("copy error", l_src.has_error)
			assert_false ("move refused", l_src.move_to (l_bad))
			assert_true ("source still there", l_src.exists)
			assert_integers_equal ("no John 3 file", 1, l_dir.entries.count)
			l_ignore := l_dir.delete_directory_recursive
		end

	test_is_stream_path
			-- Only a drive letter's colon is allowed.
		do
			assert_false ("drive", (create {SIMPLE_FILE}.make ("C:\x\y.md")).is_stream_path)
			assert_false ("long prefix", (create {SIMPLE_FILE}.make ("\\?\C:\x\y.md")).is_stream_path)
			assert_false ("drive relative", (create {SIMPLE_FILE}.make ("d:y.md")).is_stream_path)
			assert_false ("relative", (create {SIMPLE_FILE}.make ("notes\y.md")).is_stream_path)
			assert_true ("relative colon", (create {SIMPLE_FILE}.make ("notes\John 3:16.md")).is_stream_path)
			assert_true ("absolute colon", (create {SIMPLE_FILE}.make ("C:\x\a:b")).is_stream_path)
			assert_true ("stream syntax", (create {SIMPLE_FILE}.make ("C:\x\f.txt:Zone.Identifier")).is_stream_path)
		end

	test_file_safe_name
			-- Reserved characters, controls, trailing dots and spaces, device
			-- names and length.
		local
			l_files: SIMPLE_FILES
			l_text, l_name: STRING_32
		do
			assert_strings_equal ("colon", "John 3_16", l_files.file_safe_name ("John 3:16").to_string_8)
			assert_strings_equal ("all reserved", "a_b_c_d_e_f_g_h_i", l_files.file_safe_name ("a<b>c%"d/e\f|g?h*i").to_string_8)
			assert_strings_equal ("control", "a_b", l_files.file_safe_name ("a%Tb").to_string_8)
			assert_strings_equal ("trailing dots and spaces", "name", l_files.file_safe_name ("name. . ").to_string_8)
			assert_strings_equal ("empty", "_", l_files.file_safe_name ("").to_string_8)
			assert_strings_equal ("only dots", "_", l_files.file_safe_name ("...").to_string_8)
			assert_strings_equal ("CON", "CON_", l_files.file_safe_name ("CON").to_string_8)
			assert_strings_equal ("con.txt", "con_.txt", l_files.file_safe_name ("con.txt").to_string_8)
			assert_strings_equal ("nul.tar.gz", "nul_.tar.gz", l_files.file_safe_name ("nul.tar.gz").to_string_8)
			assert_strings_equal ("COM1 .md", "COM1 _.md", l_files.file_safe_name ("COM1 .md").to_string_8)
			assert_strings_equal ("LPT9", "LPT9_", l_files.file_safe_name ("LPT9").to_string_8)
			assert_strings_equal ("COM10 is fine", "COM10", l_files.file_safe_name ("COM10").to_string_8)
			assert_strings_equal ("CONSOLE is fine", "CONSOLE", l_files.file_safe_name ("CONSOLE").to_string_8)
			create l_text.make_from_string ({STRING_32} "LPT")
			l_text.append_code (0xB9)
			l_name := l_files.file_safe_name (l_text)
			assert_integers_equal ("superscript device", 5, l_name.count)
			assert_true ("superscript device suffixed", l_name [5] = '_')
			create l_text.make_filled ('a', 300)
			l_text.append ({STRING_32} ".md")
			l_name := l_files.file_safe_name (l_text)
			assert_integers_equal ("cut to 255", 255, l_name.count)
			assert_true ("extension kept", l_name.ends_with ({STRING_32} ".md"))
			create l_text.make_empty
			across 1 |..| 200 as ic loop l_text.append_code (0x1F600) end
			l_name := l_files.file_safe_name (l_text)
			assert_integers_equal ("non-BMP cut by UTF-16 units", 127, l_name.count)
			create l_text.make_empty
			l_text.append_code (0xD800)
			assert_strings_equal ("lone surrogate", "_", l_files.file_safe_name (l_text).to_string_8)
			assert_true ("safe is safe", l_files.is_file_safe_name ("John 3_16.md"))
			assert_false ("colon unsafe", l_files.is_file_safe_name ("John 3:16.md"))
			assert_false ("trailing dot unsafe", l_files.is_file_safe_name ("a."))
			assert_false ("device unsafe", l_files.is_file_safe_name ("aux.md"))
			assert_false ("empty unsafe", l_files.is_file_safe_name (""))
		end

	test_file_safe_names_make_real_files
			-- Every safe name becomes a visible file of its own in a folder.
		local
			l_files: SIMPLE_FILES
			l_dir, l_sf: SIMPLE_FILE
			l_texts: ARRAYED_LIST [STRING_32]
			l_names: HASH_TABLE [BOOLEAN, STRING_32]
			l_name, l_hebrew: STRING_32
			l_ignore: BOOLEAN
		do
			create l_dir.make (temp_file_path ("safe_dir"))
			assert_true ("dir", l_dir.create_directory)
			create l_hebrew.make_empty
			l_hebrew.append_code (0x5D1)
			l_hebrew.append_code (0x5E8)
			l_hebrew.append_code (0x5D0)
			create l_texts.make (12)
			across << "John 3:16", "Rom 5:8", "1 John 4:9-10", "a/b\c", "what?", "%"quoted%"", "star*", "pipe|", "<tag>", "CON", "trailing...", "aux.md" >> as ic loop
				l_texts.extend (ic.to_string_32)
			end
			l_texts.extend (l_hebrew + {STRING_32} " 1:1")
			create l_names.make (20)
			across l_texts as ic loop
				l_name := l_files.file_safe_name (ic) + {STRING_32} ".md"
				l_names.force (True, l_name)
				create l_sf.make (l_dir.path.extended (l_name).name)
				assert_false ({STRING_32} "not a stream: " + l_name, l_sf.is_stream_path)
				assert_true ({STRING_32} "written: " + l_name, l_sf.write_text ("body"))
				assert_true ({STRING_32} "visible: " + l_name, l_sf.is_file and l_sf.size = 4)
			end
			assert_integers_equal ("one visible file each", l_names.count, l_dir.files.count)
			l_ignore := l_dir.delete_directory_recursive
		end

feature -- Tests: D13 UTF-8 read, 100 ns time, one-pass listing

	test_read_text_utf_8
			-- Decoded and byte-faithful; BOM dropped; invalid bytes reported.
		local
			l_sf: SIMPLE_FILE
			l_text, l_read: STRING_32
			l_files: SIMPLE_FILES
			l_ignore: BOOLEAN
		do
			create l_text.make_empty
			l_text.append_code (0x5D1)
			l_text.append_code (0x5E8)
			l_text.append_code (0x3B1)
			l_text.append_code (0x1F600)
			l_text.append ({STRING_32} "%R%Nline 2%N")
			create l_sf.make (temp_file_path ("utf8_read"))
			assert_true ("write exact", l_sf.write_text_utf_8 (l_text))
			assert_integers_equal ("bytes on disk", 2 + 2 + 2 + 4 + 2 + 6 + 1, l_sf.size.to_integer_32)
			l_read := l_sf.read_text_utf_8
			assert_false ("no error", l_sf.has_error)
			assert_true ("exact round trip incl. CR LF and final LF", l_read.same_string (l_text))
			assert_integers_equal ("legacy read_text still widens bytes", 2 + 2 + 2 + 4 + 6 + 1, l_sf.read_text.count)
			assert_true ("write_text output", l_sf.write_text ({STRING_32} "a%Nb"))
			assert_true ("write_text crlf visible", l_sf.read_text_utf_8.same_string ({STRING_32} "a%R%Nb"))
			assert_true ("bom file", l_sf.write_bytes ({ARRAY [NATURAL_8]} <<0xEF, 0xBB, 0xBF, 0x41>>))
			assert_true ("bom dropped", l_sf.read_text_utf_8.same_string ({STRING_32} "A"))
			assert_true ("invalid file", l_sf.write_bytes ({ARRAY [NATURAL_8]} <<0x41, 0xFF, 0x42>>))
			l_read := l_sf.read_text_utf_8
			assert_true ("invalid reported", l_sf.has_error)
			assert_string_contains ("invalid message", l_sf.last_error, "Invalid UTF-8")
			assert_integers_equal ("replacement used", 0xFFFD, l_read.code (2).to_integer_32)
			assert_true ("convenience", l_files.write_text_utf_8 (l_sf.path_string, l_text))
			assert_true ("convenience read", l_files.read_text_utf_8 (l_sf.path_string).same_string (l_text))
			l_ignore := l_sf.delete
			l_read := l_sf.read_text_utf_8
			assert_true ("missing reported", l_sf.has_error)
			assert_true ("missing code", l_sf.last_error_code = 2)
			assert_true ("missing empty", l_read.is_empty)
		end

	test_modified_time_100ns
			-- Sub-second modification time, consistent with the seconds one.
		local
			l_sf: SIMPLE_FILE
			l_t1, l_t2, l_unix: INTEGER_64
			l_env: EXECUTION_ENVIRONMENT
			l_ignore: BOOLEAN
		do
			create l_env
			create l_sf.make (temp_file_path ("mtime_100ns"))
			assert_integers_equal ("missing gives 0", 0, l_sf.modified_time_100ns.to_integer_32)
			assert_true ("write 1", l_sf.write_text ("one"))
			l_t1 := l_sf.modified_time_100ns
			l_env.sleep (60_000_000)
			assert_true ("write 2", l_sf.write_text ("two"))
			l_t2 := l_sf.modified_time_100ns
			assert_true ("positive", l_t1 > 0)
			assert_true ("second write within the second is seen", l_t2 > l_t1)
			assert_true ("sub-second step", l_t2 - l_t1 < 10_000_000)
			l_unix := (l_t2 - 116_444_736_000_000_000) // 10_000_000
			assert_true ("agrees with modified_timestamp", (l_unix - l_sf.modified_timestamp.to_integer_64).abs <= 1)
			l_ignore := l_sf.delete
		end

	test_listing_matches_legacy
			-- The one-pass listing gives the same names as 1.0, Unicode
			-- names, hidden files and subdirectories included.
		local
			l_dir, l_sf, l_sub: SIMPLE_FILE
			l_legacy: LEGACY_LISTING
			l_names: ARRAYED_LIST [STRING_32]
			l_name: STRING_32
			l_win32: SIMPLE_FILE_WIN32
			l_native: NATIVE_STRING
			l_new, l_old: ARRAYED_LIST [STRING_32]
			i: INTEGER
			l_ignore: BOOLEAN
		do
			create l_legacy
			create l_win32
			create l_dir.make (temp_file_path ("listing_dir"))
			assert_true ("dir", l_dir.create_directory)
			create l_names.make (8)
			l_names.extend ({STRING_32} "plain.txt")
			l_names.extend ({STRING_32} "space name.md")
			l_names.extend ({STRING_32} ".hidden")
			create l_name.make_empty
			l_name.append_code (0x5E9)
			l_name.append_code (0x5DC)
			l_name.append_code (0x5D5)
			l_name.append_code (0x5DD)
			l_name.append ({STRING_32} ".md")
			l_names.extend (l_name)
			create l_name.make_empty
			l_name.append_code (0x1F08)
			l_name.append_code (0x3C1)
			l_name.append_code (0x3C7)
			l_name.append_code (0x1F75)
			l_name.append ({STRING_32} ".md")
			l_names.extend (l_name)
			create l_name.make_from_string ({STRING_32} "emoji ")
			l_name.append_code (0x1F600)
			l_name.append ({STRING_32} ".md")
			l_names.extend (l_name)
			across l_names as ic loop
				create l_sf.make (l_dir.path.extended (ic).name)
				assert_true ({STRING_32} "made " + ic, l_sf.write_text ("x"))
			end
			create l_native.make (l_dir.path.extended (".hidden").name)
			l_ignore := l_win32.set_attributes (l_native.item, {NATURAL_32} 0x2) = 0
			create l_sub.make (l_dir.path.extended ("sub").name)
			assert_true ("sub", l_sub.create_directory)
			create l_name.make_empty
			l_name.append_code (0x5EA)
			l_name.append_code (0x5EA)
			create l_sub.make (l_dir.path.extended (l_name).name)
			assert_true ("hebrew sub", l_sub.create_directory)
			assert_integers_equal ("entries count", 8, l_dir.entries.count)
			assert_true ("entries as 1.0", l_legacy.same_names (l_dir.entries, l_legacy.entries (l_dir.path)))
			assert_integers_equal ("files count", 6, l_dir.files.count)
			assert_true ("files as 1.0", l_legacy.same_names (l_dir.files, l_legacy.files (l_dir.path)))
			assert_integers_equal ("directories count", 2, l_dir.directories.count)
			assert_true ("directories as 1.0", l_legacy.same_names (l_dir.directories, l_legacy.directories (l_dir.path)))
			l_new := l_dir.entries
			l_old := l_legacy.entries (l_dir.path)
			from i := 1 until i > l_new.count loop
				assert_true ({STRING_32} "same order as 1.0 at " + i.out, l_new [i].same_string (l_old [i]))
				i := i + 1
			end
			create l_sub.make (l_dir.path.extended ("sub").name)
			assert_integers_equal ("empty dir", 0, l_sub.entries.count)
			assert_false ("empty dir no error", l_sub.has_error)
			create l_sf.make (l_dir.path.extended ("plain.txt").name)
			assert_integers_equal ("file has no entries", 0, l_sf.files.count)
			assert_true ("file listing error", l_sf.has_error)
			create l_sf.make (l_dir.path.extended ("missing").name)
			assert_integers_equal ("missing", 0, l_sf.entries.count)
			assert_string_contains ("missing error", l_sf.last_error, "Directory does not exist")
			l_ignore := l_dir.delete_directory_recursive
		end

feature {NONE} -- Test support

	hex (a_bytes: ARRAY [NATURAL_8]): STRING_8
			-- "61 0D 0A" style dump of `a_bytes'.
		do
			create Result.make (a_bytes.count * 3)
			across a_bytes as ic loop
				if not Result.is_empty then
					Result.append_character (' ')
				end
				Result.append (ic.to_hex_string)
			end
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
