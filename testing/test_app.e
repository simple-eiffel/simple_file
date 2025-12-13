note
	description: "Test application for SIMPLE_FILE"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		do
			create tests
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

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
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
