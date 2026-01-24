# S06 - Boundaries

**Library:** simple_file
**Status:** BACKWASH (reverse-engineered from implementation)
**Generated:** 2026-01-23

## Scope Boundaries

### In Scope

1. **File Operations**
   - Read entire files (text, binary, lines)
   - Write entire files (text, binary, lines)
   - Append to files
   - Copy, move, rename, delete files
   - Create empty files

2. **Directory Operations**
   - List directory contents (all, files only, directories only)
   - Create directories (single and recursive)
   - Delete directories (empty and recursive)
   - Filter files by extension

3. **Path Operations**
   - Path construction (fluent builder)
   - Path transformation (normalize, resolve, absolute)
   - Path component extraction (parent, filename, extension)

4. **File Metadata**
   - Existence checks
   - Size queries
   - Timestamps (modified, accessed)
   - Type detection (file, directory, symlink)
   - Permission queries (readable, writable, executable)

5. **Streaming Operations**
   - Line-by-line iteration
   - Chunked reading

### Out of Scope

1. **Network File Systems**
   - No special handling for NFS, SMB, etc.
   - No remote file URL support

2. **Advanced File Operations**
   - File locking (advisory or mandatory)
   - Memory-mapped files
   - Sparse files
   - File system events/watching
   - Hard links

3. **Archive Operations**
   - No ZIP, TAR, GZIP support (see simple_archive if implemented)

4. **Encoding Detection**
   - No automatic charset detection
   - No BOM handling (assumes UTF-8)

5. **Asynchronous Operations**
   - All operations are synchronous
   - No async I/O support

6. **Security Features**
   - No secure deletion (overwrite before delete)
   - No encryption/decryption
   - No ACL management

7. **Concurrency**
   - No thread-safe operations
   - No SCOOP-specific synchronization

## API Boundaries

### Public API

All features in SIMPLE_FILE, SIMPLE_FILES, and SIMPLE_PATH are part of the public API.

### Internal API (feature {NONE})

| Class | Feature | Purpose |
|-------|---------|---------|
| SIMPLE_FILE | internal_path | PATH storage |
| SIMPLE_FILE | reset_error | Clear error state |
| SIMPLE_FILE | set_error | Set error message |
| SIMPLE_PATH | internal_path | PATH storage |

### Extension Points

1. **SIMPLE_FILE**
   - Can be inherited for specialized file types
   - Model queries can be overridden

2. **SIMPLE_PATH**
   - Fluent methods can be extended via inheritance
   - Conversion methods can be overridden

3. **SIMPLE_FILES**
   - Expanded class cannot be inherited
   - Provides static utility pattern

## Dependency Boundaries

### Required Dependencies
- EiffelStudio base library (mandatory)
- EiffelStudio time library (for SIMPLE_FILES.temp_file_path)
- simple_date_time (for temp file naming)

### Optional Dependencies
- None

### No Dependencies On
- Network libraries
- Database libraries
- GUI libraries
- Other simple_* libraries (except simple_date_time)

## Data Boundaries

### Input Boundaries
- Path strings: READABLE_STRING_GENERAL (supports STRING_8, STRING_32)
- Content: READABLE_STRING_GENERAL for text, ARRAY [NATURAL_8] for binary
- Lines: LIST [READABLE_STRING_GENERAL]
- Callbacks: PROCEDURE [STRING_32] for iteration

### Output Boundaries
- Content: STRING_32 for text, ARRAY [NATURAL_8] for binary
- Lines: ARRAYED_LIST [STRING_32]
- Entries: ARRAYED_LIST [STRING_32]
- Paths: STRING_32 or PATH

### Size Limits
- Maximum file size: INTEGER_64 max (~9 EB)
- Maximum path length: OS-dependent
- Maximum directory entries: OS-dependent

## Error Boundaries

### Recoverable Errors (has_error = True)
- File not found
- Permission denied
- Directory not empty
- Disk full
- File in use

### Non-Recoverable Errors (Exception)
- Out of memory
- System call failure
- Invalid memory access

### Not Handled
- Disk corruption
- File system unmount during operation
- Network timeout (for network file systems)
