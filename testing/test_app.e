note
	description: "Test application for SIMPLE_FILE"
	author: "Larry Rix"

class
	TEST_APP

inherit
	ARGUMENTS_32

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests, or with arguments "bench <folder> <n>" time the
			-- 1.0 listing against the one-pass listing on <n> files.
		do
			create tests
			if argument_count >= 3 and then argument (1).same_string ("bench") then
				run_bench (argument (2), argument (3).to_integer)
			else
				run_tests
			end
		end

	run_tests
			-- Run the tests.
		do
			print ("Running SIMPLE_FILE tests...%N%N")

			passed := 0
			failed := 0

			run_test (agent tests.test_file_exists, "test_file_exists")
			run_test (agent tests.test_directory_exists, "test_directory_exists")
			run_test (agent tests.test_write_and_read_text, "test_write_and_read_text")
			run_test (agent tests.test_write_and_read_lines, "test_write_and_read_lines")
			run_test (agent tests.test_write_and_read_bytes, "test_write_and_read_bytes")
			run_test (agent tests.test_append_text, "test_append_text")
			run_test (agent tests.test_file_metadata, "test_file_metadata")
			run_test (agent tests.test_copy_file, "test_copy_file")
			run_test (agent tests.test_move_file, "test_move_file")
			run_test (agent tests.test_delete_file, "test_delete_file")
			run_test (agent tests.test_create_directory, "test_create_directory")
			run_test (agent tests.test_list_directory, "test_list_directory")
			run_test (agent tests.test_files_with_extension, "test_files_with_extension")
			run_test (agent tests.test_expanded_convenience, "test_expanded_convenience")
			run_test (agent tests.test_write_text_bytes_as_before, "test_write_text_bytes_as_before")
			run_test (agent tests.test_write_text_leaves_no_temporary, "test_write_text_leaves_no_temporary")
			run_test (agent tests.test_write_text_failure_keeps_old_content, "test_write_text_failure_keeps_old_content")
			run_test (agent tests.test_write_text_keeps_hidden_attribute, "test_write_text_keeps_hidden_attribute")
			run_test (agent tests.test_remove_stale_temporaries, "test_remove_stale_temporaries")
			run_test (agent tests.test_readonly_folder_creates_files, "test_readonly_folder_creates_files")
			run_test (agent tests.test_write_failure_is_reported, "test_write_failure_is_reported")
			run_test (agent tests.test_stream_names_refused, "test_stream_names_refused")
			run_test (agent tests.test_is_stream_path, "test_is_stream_path")
			run_test (agent tests.test_file_safe_name, "test_file_safe_name")
			run_test (agent tests.test_file_safe_names_make_real_files, "test_file_safe_names_make_real_files")
			run_test (agent tests.test_read_text_utf_8, "test_read_text_utf_8")
			run_test (agent tests.test_modified_time_100ns, "test_modified_time_100ns")
			run_test (agent tests.test_listing_matches_legacy, "test_listing_matches_legacy")

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Benchmark

	run_bench (a_folder: READABLE_STRING_32; a_count: INTEGER)
			-- Fill `a_folder' with `a_count' files (if it holds fewer), then
			-- time 1.0's `files' (LEGACY_LISTING) and the one-pass `files',
			-- three runs each, and check both give the same names.
		local
			l_dir, l_sf: SIMPLE_FILE
			l_legacy: LEGACY_LISTING
			l_old, l_new: ARRAYED_LIST [STRING_32]
			l_name: STRING_32
			l_t0: REAL_64
			i, l_run: INTEGER
			l_ignore: BOOLEAN
		do
			create l_legacy
			create l_dir.make (a_folder)
			l_ignore := l_dir.create_directory_recursive
			if l_dir.files.count < a_count then
				from i := 1 until i > a_count loop
					create l_name.make_from_string ({STRING_32} "note_")
					l_name.append (i.out)
					if i \\ 10 = 0 then
						l_name.append_code (0x5D1)
						l_name.append_code (0x3B1)
					end
					l_name.append ({STRING_32} ".md")
					create l_sf.make (l_dir.path.extended (l_name).name)
					l_ignore := l_sf.write_text ("body")
					i := i + 1
				end
			end
			from l_run := 1 until l_run > 3 loop
				l_t0 := l_legacy.now_ms
				l_old := l_legacy.files (l_dir.path)
				print ("BENCH run=" + l_run.out + " legacy_files=" + l_old.count.out + " ms=" + (l_legacy.now_ms - l_t0).truncated_to_integer.out)
				l_t0 := l_legacy.now_ms
				l_new := l_dir.files
				print (" one_pass_files=" + l_new.count.out + " ms=" + (l_legacy.now_ms - l_t0).truncated_to_integer.out)
				print (" same_names=" + l_legacy.same_names (l_old, l_new).out + " error=" + l_dir.has_error.out + "%N")
				l_run := l_run + 1
			end
		end

feature {NONE} -- Implementation

	tests: LIB_TESTS

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
