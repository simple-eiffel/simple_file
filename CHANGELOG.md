# Changelog

All notable changes to simple_file will be documented in this file.

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
