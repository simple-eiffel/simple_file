note
	description: "[
		The directory listing of simple_file 1.0 (DIRECTORY.readentry plus one
		RAW_FILE or DIRECTORY probe per entry), kept in the tests as the
		reference the one-pass FindFirstFileExW listing must match, and as
		the "before" side of the enumeration benchmark.
	]"
	author: "Larry Rix"

class
	LEGACY_LISTING

feature -- Listing

	entries (a_dir: PATH): ARRAYED_LIST [STRING_32]
			-- All entries of `a_dir' but "." and "..", as 1.0 listed them.
		local
			l_dir: DIRECTORY
		do
			create Result.make (10)
			create l_dir.make_with_path (a_dir)
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
			end
		end

	files (a_dir: PATH): ARRAYED_LIST [STRING_32]
			-- Plain files of `a_dir', as 1.0 listed them.
		local
			l_file: RAW_FILE
		do
			create Result.make (10)
			across entries (a_dir) as ic loop
				create l_file.make_with_path (a_dir.extended (ic))
				if l_file.exists and then l_file.is_plain then
					Result.extend (ic)
				end
			end
		end

	directories (a_dir: PATH): ARRAYED_LIST [STRING_32]
			-- Subdirectories of `a_dir', as 1.0 listed them.
		local
			l_subdir: DIRECTORY
		do
			create Result.make (10)
			across entries (a_dir) as ic loop
				create l_subdir.make_with_path (a_dir.extended (ic))
				if l_subdir.exists then
					Result.extend (ic)
				end
			end
		end

feature -- Comparison

	same_names (a, b: LIST [STRING_32]): BOOLEAN
			-- Do `a' and `b' hold the same names, order ignored (each name
			-- once, as in a folder)?
		local
			l_seen: HASH_TABLE [BOOLEAN, STRING_32]
		do
			if a.count = b.count then
				create l_seen.make (a.count)
				across a as ic loop
					l_seen.force (True, ic)
				end
				Result := l_seen.count = a.count
				across b as ic loop
					Result := Result and l_seen.has (ic)
				end
			end
		end

feature -- Clock

	now_ms: REAL_64
			-- QueryPerformanceCounter in milliseconds.
		external
			"C inline use <windows.h>"
		alias
			"[
				LARGE_INTEGER f, c;
				QueryPerformanceFrequency (&f);
				QueryPerformanceCounter (&c);
				return (EIF_REAL_64) c.QuadPart * 1000.0 / (EIF_REAL_64) f.QuadPart;
			]"
		end

end
