# Changelog

All notable changes to simple_file will be documented in this file.

## [Unreleased]

### Changed
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
