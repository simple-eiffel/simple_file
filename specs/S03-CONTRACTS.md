# S03 - Contracts

**Library:** simple_file
**Status:** BACKWASH (reverse-engineered from implementation)
**Generated:** 2026-01-23

## SIMPLE_FILE Contracts

### Creation Contracts

#### make (a_path: READABLE_STRING_GENERAL)
```eiffel
require
    path_not_empty: not a_path.is_empty
ensure
    path_set: not internal_path.is_empty
    path_model_matches: path_model.count = a_path.count
    no_error: not has_error
```

#### make_with_path (a_path: PATH)
```eiffel
require
    path_not_empty: not a_path.is_empty
ensure
    path_set: internal_path = a_path
    no_error: not has_error
```

### Write Operation Contracts

#### write_text / set_content (a_content: READABLE_STRING_GENERAL): BOOLEAN
```eiffel
ensure
    success_implies_exists: Result implies exists
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

#### write_bytes / save_binary (a_bytes: ARRAY [NATURAL_8]): BOOLEAN
```eiffel
ensure
    success_implies_exists: Result implies exists
    success_implies_size: Result implies size = a_bytes.count.to_integer_64
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

#### write_lines (a_lines: LIST [READABLE_STRING_GENERAL]): BOOLEAN
```eiffel
ensure
    success_implies_exists: Result implies exists
    success_implies_line_count: Result implies lines_model.count = a_lines.count
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

#### append_text (a_content: READABLE_STRING_GENERAL): BOOLEAN
```eiffel
ensure
    success_implies_exists: Result implies exists
    size_increased: Result implies size >= old size
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

#### append_line (a_line: READABLE_STRING_GENERAL): BOOLEAN
```eiffel
ensure
    success_implies_exists: Result implies exists
    line_count_increased: Result implies lines_model.count >= old lines_model.count
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

#### clear: BOOLEAN
```eiffel
ensure
    success_implies_empty: Result implies size = 0
    success_implies_exists: Result implies exists
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

### File Operation Contracts

#### copy_to (a_destination: READABLE_STRING_GENERAL): BOOLEAN
```eiffel
require
    destination_not_empty: not a_destination.is_empty
ensure
    source_unchanged: exists = old exists
    source_content_unchanged: bytes_model |=| old bytes_model
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

#### move_to (a_destination: READABLE_STRING_GENERAL): BOOLEAN
```eiffel
require
    destination_not_empty: not a_destination.is_empty
ensure
    success_implies_exists: Result implies exists
    success_implies_new_path: Result implies path_string.same_string (a_destination.to_string_32)
    failure_implies_error: not Result implies has_error
```

#### rename_to (a_new_name: READABLE_STRING_GENERAL): BOOLEAN
```eiffel
require
    name_not_empty: not a_new_name.is_empty
ensure
    success_implies_exists: Result implies exists
    success_implies_new_name: Result implies file_name.same_string (a_new_name.to_string_32)
    failure_implies_error: not Result implies has_error
```

#### delete: BOOLEAN
```eiffel
ensure
    success_implies_gone: Result implies not exists
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

#### create_if_missing: BOOLEAN
```eiffel
ensure
    success_implies_exists: Result implies exists
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

### Directory Operation Contracts

#### entries: ARRAYED_LIST [STRING_32]
```eiffel
ensure
    result_count_matches_model: Result.count = entries_model.count
    path_unchanged: path_model |=| old path_model
```

#### create_directory: BOOLEAN
```eiffel
ensure
    success_implies_exists: Result implies is_directory
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

#### create_directory_recursive: BOOLEAN
```eiffel
ensure
    success_implies_exists: Result implies is_directory
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

#### delete_directory: BOOLEAN
```eiffel
ensure
    success_implies_gone: Result implies not is_directory
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

#### delete_directory_recursive: BOOLEAN
```eiffel
ensure
    success_implies_gone: Result implies not is_directory
    failure_implies_error: not Result implies has_error
    path_unchanged: path_model |=| old path_model
```

### Class Invariants

#### SIMPLE_FILE
```eiffel
invariant
    path_not_empty: not internal_path.is_empty
    path_model_consistent: path_model.count = internal_path.name.count
```

#### SIMPLE_PATH
```eiffel
invariant
    path_model_consistent: path_model.count = internal_path.name.count
```

## Model Queries

The library uses MML (Mathematical Model Library) for specification:

### path_model: MML_SEQUENCE [CHARACTER_32]
Returns the path as a sequence of characters for contract verification.

### bytes_model: MML_SEQUENCE [NATURAL_8]
Returns file content as byte sequence (empty if file doesn't exist).

### lines_model: MML_SEQUENCE [STRING_32]
Returns file content as sequence of lines (empty if file doesn't exist).

### entries_model: MML_SET [STRING_32]
Returns directory entries as a set (excludes "." and "..").

### components_model: MML_SEQUENCE [STRING_32] (SIMPLE_PATH)
Returns path components as a sequence of strings.
