# Changelog

All notable changes to simple_file will be documented in this file.

## [1.1.0] - 2026-10-08

Fixes the simple_file defects found by executed spikes in the simple_bible
notes-store debate (RQ-06, `04 - VERDICT.md`: D10-D13, D18; F-1, F-2, F-3b,
F-4, F-SN, LG-10).

### Fixed
- **D10 (critical): `write_text` was not crash-safe.** 1.0 truncated the
  target, then wrote: a process killed in between left an empty file (112 of
  200 kills in the spike; 52 of 200 when re-run 2026-10-08). `write_text`,
  `write_bytes`, `write_lines` and the new `write_text_utf_8` now write a
  temporary file in the same folder, `FlushFileBuffers` it and rename it over
  the target with `MoveFileExW (MOVEFILE_REPLACE_EXISTING |
  MOVEFILE_WRITE_THROUGH)`. Re-run of the kill test against 1.1.0: 0 empty,
  0 torn in 400 kills (`testing/kill_spike`). On failure the temporary file is
  deleted, the target is untouched, and the call returns False with
  `last_error` and `last_error_code`. Bytes on disk are unchanged from 1.0
  (UTF-8, each LF written as CR LF), verified byte for byte.
- **D11 (critical): no file was created in a folder carrying the ReadOnly
  attribute** (OneDrive sets it; Windows does not honor it on directories).
  1.0 trusted `FILE.is_creatable` and refused (0 of 20). Writes, appends,
  `create_if_missing` and `copy_to` now attempt the real operation and report
  the OS error if it fails: 20 of 20 (plus append, bytes, lines, create, copy)
  in the test.
- **D12 (high, silent): a `:` in a file name wrote an NTFS alternate data
  stream.** `write_text ("notes\John 3:16.md")` returned True and left a
  0-byte file `John 3` with the body in stream `16.md`. Every write, append,
  create, copy destination and move destination now refuses a path with a `:`
  other than a drive letter's, returning False with an error (a reported
  error rather than a precondition, so lean builds without contracts are
  protected too). New query `is_stream_path`.
- **D13 (medium):**
  - `read_text` does not decode UTF-8 (41 characters for 25). It is **kept as
    1.0** (one character per byte) because clients call `to_string_8` or their
    own UTF-8 decoder on its result; new `read_text_utf_8` decodes, keeps line
    endings and the final line break, drops a leading BOM and reports invalid
    UTF-8. Uses simple_encoding (new dependency).
  - modification time was whole-second only: new `modified_time_100ns`
    (FILETIME, 100 ns ticks since 1601 UTC).
  - `entries`, `files` and `directories` probed every entry after listing it
    (20-35 times slower than one pass). They now make one `FindFirstFileExW`
    pass (`FindExInfoBasic`, `FIND_FIRST_EX_LARGE_FETCH`). Same names, same
    order as 1.0 (tested with Hebrew, Greek, emoji, hidden files,
    subdirectories). Lean build, warm cache: `files` on 10,000 files 320-339 ms
    to 8-10 ms; on 100,000 files 3,332-4,468 ms to 123-140 ms.
- Error messages built from a non-Latin-1 path no longer violate
  `to_string_8`'s precondition (they are STRING_32 now).
- `copy_to` and `move_to` report OS failures through `last_error` instead of
  raising.

### Added
- `SIMPLE_FILE.write_text_utf_8`, `read_text_utf_8`, `modified_time_100ns`,
  `is_stream_path`, `last_error_code`, `remove_stale_temporaries` (deletes the
  `.~sf<pid>_<n>.tmp` files killed writers leave; owners still running are
  left alone, judged by process id and start time).
- `SIMPLE_FILES.file_safe_name` / `is_file_safe_name` / `Max_file_name_length`:
  arbitrary text to one Windows file name (reserved characters, control
  characters, trailing dots and spaces, reserved device names including COM0,
  LPT0 and the superscript forms, 255 UTF-16 units). Not reversible; add an id
  where names must be unique. Also `SIMPLE_FILES.read_text_utf_8`,
  `write_text_utf_8`.
- `SIMPLE_FILE_WIN32`: the inline-C Win32 primitives. Externals that can wait
  on I/O are `C blocking` and touch only C memory.
- `testing/kill_spike`: the kill-test writer and driver (`kill_test.ps1`).
- `TEST_APP bench <folder> <n>`: 1.0 listing against the one-pass listing.

### Changed (behavior dependents may notice; signatures unchanged)
- A replacing write now **renames a new file over the target**: the file gets
  a new file ID and creation time; a hard link to the old file keeps the old
  content; a symbolic link at the target path is replaced by a regular file;
  the ACL comes from the folder, not the old file. HIDDEN, SYSTEM, ARCHIVE and
  NOT_CONTENT_INDEXED are carried over.
- A replacing write needs delete access to the target: a target held open by
  another process **without `FILE_SHARE_DELETE`** now makes the write fail
  (returned and reported, error 5 or 32) where 1.0 might have truncated it
  in place. 1.0 raised OPERATING_SYSTEM_FAILURE when the holder denied
  writing; 1.1.0 returns False instead.
- A killed writer can leave a `.~sf*.tmp` file (dot-prefixed) beside the
  target; `remove_stale_temporaries` sweeps them.
- Writes refuse `:` paths (see D12).
- `files` classifies by `FILE_ATTRIBUTE_DIRECTORY`: a file symbolic link whose
  target is missing is now listed (1.0 skipped it because its probe failed).
- The postcondition `entries.count = entries_model.count` was removed: it
  listed the folder a second time, so it failed whenever another process
  changed the folder in between, and its MML set made `entries` quadratic
  under contracts.
- New library dependency: simple_encoding. Clients must rebuild with
  `-clean` (delete EIFGENs) after updating.

### Not changed, on purpose
- `read_text`, `read_lines`, `each_line` still return one character per byte
  (see D13 above).
- **D18:** `ReplaceFileW` is not used anywhere in simple_file. It can destroy
  an outside edit that lands during the call, sometimes while returning
  success; no Windows API closes that window. An outside edit made between a
  caller's read and its write is replaced by any whole-file save, including
  this one.

### Changed (earlier, unreleased)
- Class invariants are O(1) again: clauses that built an MML model (`x_model.count = count`) or walked a collection on every feature call were removed. An invariant runs on every call, so those made each call O(n) and any loop over the object O(n^2); simple_json read a 1434-element array in 158 s under DBC before the fix. Model and per-element facts stay in the postconditions of the features that establish them.

## [1.0.0] - 2025-12-09

### Added
- Initial release
- SIMPLE_FILE facade class for file operations
- File status queries (exists, is_readable, is_writable, is_directory, is_file)
- File metadata (size, extension, base_name, file_name, parent_path)
- Read operations (read_text, read_bytes, read_lines, each_line streaming)
- Write operations (write_text, write_bytes, append_text, append_line)
- File operations (copy_to, move_to, rename_to, delete)
- Directory operations (entries, files, directories, create_directory, delete_directory_recursive)
- Path transformation utilities
- Error handling with descriptive messages
- SCOOP capability declaration
- Full test suite
- API documentation
