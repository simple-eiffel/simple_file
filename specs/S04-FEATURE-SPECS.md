# S04 - Feature Specifications

**Library:** simple_file
**Status:** BACKWASH (reverse-engineered from implementation)
**Generated:** 2026-01-23

## SIMPLE_FILE Features

### Initialization

| Feature | Signature | Description |
|---------|-----------|-------------|
| make | (a_path: READABLE_STRING_GENERAL) | Create file object from path string |
| make_with_path | (a_path: PATH) | Create file object from PATH object |

### File Status (Queries)

| Feature | Returns | Description |
|---------|---------|-------------|
| exists | BOOLEAN | Does file or directory exist? |
| is_present | BOOLEAN | Alias for exists |
| found | BOOLEAN | Alias for exists |
| is_readable | BOOLEAN | Can file be read? |
| is_writable | BOOLEAN | Can file be written? |
| is_executable | BOOLEAN | Can file be executed? |
| is_directory | BOOLEAN | Is this a directory? |
| is_file | BOOLEAN | Is this a regular file? |
| is_symlink | BOOLEAN | Is this a symbolic link? |

### File Metadata (Queries)

| Feature | Returns | Description |
|---------|---------|-------------|
| size | INTEGER_64 | Size in bytes (0 if not exists) |
| length | INTEGER_64 | Alias for size |
| byte_count | INTEGER_64 | Alias for size |
| modified_timestamp | INTEGER | Modification timestamp (seconds since epoch) |
| accessed_timestamp | INTEGER | Access timestamp (seconds since epoch) |
| extension | STRING_32 | File extension (e.g., "txt") |
| base_name | STRING_32 | File name without extension |
| file_name | STRING_32 | Full file name with extension |
| parent_path | STRING_32 | Parent directory path |
| path | PATH | Full PATH object |
| path_string | STRING_32 | Full path as string |

### Read Operations (Queries)

| Feature | Returns | Description |
|---------|---------|-------------|
| read_text | STRING_32 | Read entire file as UTF-8 text |
| get_content | STRING_32 | Alias for read_text |
| load | STRING_32 | Alias for read_text |
| read_all | STRING_32 | Alias for read_text |
| content | STRING_32 | Alias for read_text |
| read_bytes | ARRAY [NATURAL_8] | Read entire file as bytes |
| get_binary | ARRAY [NATURAL_8] | Alias for read_bytes |
| load_binary | ARRAY [NATURAL_8] | Alias for read_bytes |
| binary_content | ARRAY [NATURAL_8] | Alias for read_bytes |
| read_lines | ARRAYED_LIST [STRING_32] | Read all lines |
| get_lines | ARRAYED_LIST [STRING_32] | Alias for read_lines |
| load_lines | ARRAYED_LIST [STRING_32] | Alias for read_lines |
| lines | ARRAYED_LIST [STRING_32] | Alias for read_lines |

### Write Operations (Commands with Result)

| Feature | Signature | Returns | Description |
|---------|-----------|---------|-------------|
| write_text | (a_content: READABLE_STRING_GENERAL) | BOOLEAN | Write content (overwrites) |
| put_content | (a_content) | BOOLEAN | Alias for write_text |
| save | (a_content) | BOOLEAN | Alias for write_text |
| write_all | (a_content) | BOOLEAN | Alias for write_text |
| set_content | (a_content) | BOOLEAN | Alias for write_text |
| write_bytes | (a_bytes: ARRAY [NATURAL_8]) | BOOLEAN | Write bytes (overwrites) |
| put_binary | (a_bytes) | BOOLEAN | Alias for write_bytes |
| save_binary | (a_bytes) | BOOLEAN | Alias for write_bytes |
| write_lines | (a_lines: LIST [...]) | BOOLEAN | Write lines (overwrites) |
| append_text | (a_content) | BOOLEAN | Append content to file |
| append_line | (a_line) | BOOLEAN | Append line with newline |
| clear | () | BOOLEAN | Empty the file |

### File Operations (Commands with Result)

| Feature | Signature | Returns | Description |
|---------|-----------|---------|-------------|
| copy_to | (a_destination: READABLE_STRING_GENERAL) | BOOLEAN | Copy file to destination |
| copy_file | (a_destination) | BOOLEAN | Alias for copy_to |
| duplicate_to | (a_destination) | BOOLEAN | Alias for copy_to |
| move_to | (a_destination) | BOOLEAN | Move file to destination |
| move | (a_destination) | BOOLEAN | Alias for move_to |
| relocate_to | (a_destination) | BOOLEAN | Alias for move_to |
| rename_to | (a_new_name) | BOOLEAN | Rename file (same directory) |
| delete | () | BOOLEAN | Delete file |
| remove | () | BOOLEAN | Alias for delete |
| unlink | () | BOOLEAN | Alias for delete |
| create_if_missing | () | BOOLEAN | Create empty file if not exists |

### Directory Operations

| Feature | Signature | Returns | Description |
|---------|-----------|---------|-------------|
| entries | () | ARRAYED_LIST [STRING_32] | All entries in directory |
| list | () | ARRAYED_LIST [STRING_32] | Alias for entries |
| contents | () | ARRAYED_LIST [STRING_32] | Alias for entries |
| children | () | ARRAYED_LIST [STRING_32] | Alias for entries |
| files | () | ARRAYED_LIST [STRING_32] | Only files (not subdirectories) |
| directories | () | ARRAYED_LIST [STRING_32] | Only subdirectories |
| files_with_extension | (a_ext: READABLE_STRING_GENERAL) | ARRAYED_LIST [STRING_32] | Files with given extension |
| create_directory | () | BOOLEAN | Create directory |
| create_directory_recursive | () | BOOLEAN | Create directory and parents |
| delete_directory | () | BOOLEAN | Delete empty directory |
| delete_directory_recursive | () | BOOLEAN | Delete directory and contents |

### Streaming Operations

| Feature | Signature | Description |
|---------|-----------|-------------|
| each_line | (a_action: PROCEDURE [STRING_32]) | Iterate lines with callback |
| read_chunk | (a_offset, a_size: INTEGER): ARRAY [NATURAL_8] | Read chunk at offset |

### Path Transformation

| Feature | Returns | Description |
|---------|---------|-------------|
| resolve | STRING_32 | Canonical absolute path (requires existence) |
| normalize | STRING_32 | Normalize path (pure, no existence check) |
| absolute_path | STRING_32 | Make path absolute |

### Permission Helpers

| Feature | Returns | Description |
|---------|---------|-------------|
| make_readable | BOOLEAN | Make file readable (platform-specific) |
| make_writable | BOOLEAN | Make file writable (platform-specific) |

### Temporary File Support

| Feature | Signature | Description |
|---------|-----------|-------------|
| with_temp_file | (a_action: PROCEDURE [SIMPLE_FILE]) | Execute action with auto-cleanup |

### Error Handling

| Feature | Returns | Description |
|---------|---------|-------------|
| has_error | BOOLEAN | Did last operation fail? |
| failed | BOOLEAN | Alias for has_error |
| error_occurred | BOOLEAN | Alias for has_error |
| last_error | STRING_32 | Error description (empty if none) |

---

## SIMPLE_FILES Features (Expanded Class)

### Existence Checks

| Feature | Signature | Returns | Description |
|---------|-----------|---------|-------------|
| file_exists | (a_path) | BOOLEAN | Does file exist? |
| directory_exists | (a_path) | BOOLEAN | Does directory exist? |

### Quick Read

| Feature | Signature | Returns | Description |
|---------|-----------|---------|-------------|
| read_text | (a_path) | STRING_32 | Read file as UTF-8 |
| read_lines | (a_path) | ARRAYED_LIST [STRING_32] | Read all lines |
| read_bytes | (a_path) | ARRAY [NATURAL_8] | Read as bytes |

### Quick Write

| Feature | Signature | Returns | Description |
|---------|-----------|---------|-------------|
| write_text | (a_path, a_content) | BOOLEAN | Write content |
| write_lines | (a_path, a_lines) | BOOLEAN | Write lines |
| write_bytes | (a_path, a_bytes) | BOOLEAN | Write bytes |
| append_text | (a_path, a_content) | BOOLEAN | Append content |

### Quick Operations

| Feature | Signature | Returns | Description |
|---------|-----------|---------|-------------|
| copy_file | (a_source, a_dest) | BOOLEAN | Copy file |
| move_file | (a_source, a_dest) | BOOLEAN | Move file |
| delete_file | (a_path) | BOOLEAN | Delete file |
| ensure_directory | (a_path) | BOOLEAN | Create directory recursively |

### Directory Listing

| Feature | Signature | Returns | Description |
|---------|-----------|---------|-------------|
| list_files | (a_path) | ARRAYED_LIST [STRING_32] | List files |
| list_directories | (a_path) | ARRAYED_LIST [STRING_32] | List subdirectories |
| list_all | (a_path) | ARRAYED_LIST [STRING_32] | List all entries |

### Path Utilities

| Feature | Signature | Returns | Description |
|---------|-----------|---------|-------------|
| join_path | (a_parts: ARRAY [...]) | STRING_32 | Join path components |
| parent_of | (a_path) | STRING_32 | Get parent directory |
| extension_of | (a_path) | STRING_32 | Get file extension |
| base_name_of | (a_path) | STRING_32 | Get name without extension |
| file_name_of | (a_path) | STRING_32 | Get name with extension |

### Temporary Files

| Feature | Returns | Description |
|---------|---------|-------------|
| temp_directory | STRING_32 | System temp directory path |
| temp_file_path (a_prefix) | STRING_32 | Generate unique temp file path |

---

## SIMPLE_PATH Features

### Initialization

| Feature | Description |
|---------|-------------|
| make | Empty path |
| make_from (a_path) | From string |
| make_current | Current directory |
| make_temp | Temp directory |
| make_home | Home directory |

### Fluent Building

| Feature | Returns | Description |
|---------|---------|-------------|
| add (a_component) | SIMPLE_PATH | Add path component |
| joined alias "/" (a_component) | SIMPLE_PATH | Add component (alias) |
| up | SIMPLE_PATH | Go to parent |
| with_extension (a_ext) | SIMPLE_PATH | Change extension |
| without_extension | SIMPLE_PATH | Remove extension |

### Access

| Feature | Returns | Description |
|---------|---------|-------------|
| to_string | STRING_32 | Path as string |
| to_path | PATH | As PATH object |
| to_file | SIMPLE_FILE | As SIMPLE_FILE |

### Status

| Feature | Returns | Description |
|---------|---------|-------------|
| exists | BOOLEAN | Does path exist? |
| is_file | BOOLEAN | Is regular file? |
| is_directory | BOOLEAN | Is directory? |
| is_absolute | BOOLEAN | Is absolute path? |
| is_empty | BOOLEAN | Is path empty? |

### Components

| Feature | Returns | Description |
|---------|---------|-------------|
| parent | SIMPLE_PATH | Parent as new SIMPLE_PATH |
| file_name | STRING_32 | File name component |
| extension | STRING_32 | Extension (without dot) |
| stem | STRING_32 | Name without extension |

### Transformation

| Feature | Returns | Description |
|---------|---------|-------------|
| resolve | SIMPLE_PATH | Canonical absolute path |
| normalize | STRING_32 | Normalized path string |
| absolute | SIMPLE_PATH | Absolute path |
