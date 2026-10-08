note
	description: "[
		Kill-test writer for simple_file (RQ-06 spike S-F2-1, re-run against
		the fixed library). `kill_writer <path>' rewrites one note through
		{SIMPLE_FILE}.write_text in an endless loop until it is killed.
		Each version is "VERSION k", 4,000 'x' and "END k", one per line,
		as in the original spike. kill_test.ps1 kills it at random moments
		and classifies what the note holds afterwards.
	]"
	author: "Larry Rix"

class
	KILL_WRITER_APP

inherit
	ARGUMENTS_32

create
	make

feature {NONE} -- Initialization

	make
			-- Rewrite the note named by the first argument until killed.
		local
			l_file: SIMPLE_FILE
			l_body: STRING_8
			k: INTEGER
		do
			if argument_count >= 2 and then argument (1).same_string ("sweep") then
				create l_file.make (argument (2))
				print ("removed stale temporaries: " + l_file.remove_stale_temporaries.out + " error=" + l_file.has_error.out + "%N")
			elseif argument_count >= 1 and then not argument (1).is_empty then
				create l_file.make (argument (1))
				from
					k := 1
				until
					k > 100_000_000
				loop
					l_body := "VERSION " + k.out + "%N" + create {STRING_8}.make_filled ('x', 4000) + "%NEND " + k.out + "%N"
					if not l_file.write_text (l_body) then
						io.error.put_string ("write failed: ")
						io.error.put_string (l_file.last_error.to_string_8)
						io.error.put_new_line
					end
					k := k + 1
				end
			else
				io.error.put_string ("usage: kill_writer <path> | kill_writer sweep <folder>%N")
			end
		end

end
