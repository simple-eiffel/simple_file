# S05 - Constraints

**Library:** simple_file
**Status:** BACKWASH (reverse-engineered from implementation)
**Generated:** 2026-01-23

## Type Constraints

### Path Constraints
- Path strings must not be empty for creation
- Path components are internally stored as PATH objects
- Unicode paths supported via STRING_32 and PATH

### File Size Constraints
- Maximum file size limited by INTEGER_64 (practical limit: 9+ exabytes)
- Large file operations (read_bytes, read_text) load entire content into memory
- Use streaming operations (each_line, read_chunk) for large files

## Operational Constraints

### File System Constraints
- File operations depend on underlying OS permissions
- Concurrent file access not thread-safe (no SCOOP synchronization)
- File locking is managed by the OS, not the library

### Directory Constraints
- Directory listing excludes "." and ".." entries automatically
- Recursive operations (create_directory_recursive, delete_directory_recursive) follow filesystem limits
- delete_directory requires directory to be empty
- delete_directory_recursive may fail if files are locked

### Encoding Constraints
- Text operations default to UTF-8 encoding
- Binary operations use raw byte arrays
- No automatic encoding detection (assumes UTF-8)

## Platform Constraints

### Cross-Platform
- Path separators handled automatically via PATH class
- Uses `{OPERATING_ENVIRONMENT}.directory_separator`

### Windows-Specific
- Drive letters supported (e.g., "C:\")
- Long path support depends on EiffelStudio and OS version
- Permission helpers (make_readable, make_writable) limited functionality

### Unix-Specific
- Symbolic link detection supported
- Unix permissions accessible via underlying FILE class
- Permission helpers limited (no chmod implementation)

## Error Handling Constraints

### Error State Pattern
- All operations that can fail set `has_error` and `last_error`
- Operations reset error state before execution
- Errors are strings, not exception types

### Non-Throwing Design
- Operations return BOOLEAN success indicator
- No exceptions thrown for normal file errors
- System-level exceptions may still propagate

## Performance Constraints

### Memory Usage
- `read_text`/`read_bytes`: O(n) memory for file size n
- `read_lines`: O(n) memory for total line content
- `entries`: O(m) memory for m directory entries
- Streaming operations (`each_line`): O(1) memory per line

### Time Complexity
- File existence check: O(1) system call
- Read/write operations: O(n) for file size n
- Directory listing: O(m) for m entries
- Path normalization: O(p) for path with p components

## Functional Constraints

### Atomicity
- Write operations are NOT atomic
- No transaction support
- Partial writes possible on failure

### Consistency
- Model queries (bytes_model, lines_model) reflect file state at query time
- Concurrent external modifications may cause inconsistency

## Contract-Based Constraints

### Preconditions
- Path must not be empty for creation
- Destinations must not be empty for copy/move operations
- Extension operations require valid file names

### Postconditions
- Write operations: success implies file exists
- Delete operations: success implies file does not exist
- Copy operations: source unchanged after operation

### Invariants
- Path never becomes empty after creation
- Path model always consistent with internal PATH object
