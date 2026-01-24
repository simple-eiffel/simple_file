# S02 - Class Catalog

**Library:** simple_file
**Status:** BACKWASH (reverse-engineered from implementation)
**Generated:** 2026-01-23

## Class Hierarchy

```
ANY
 +-- SIMPLE_FILE              [Main file/directory operations]
 +-- SIMPLE_PATH              [Fluent path builder]

expanded ANY
 +-- SIMPLE_FILES             [Static convenience operations]
```

## Class Details

### SIMPLE_FILE

**Purpose:** Main wrapper class for file and directory operations.

**Responsibilities:**
- File existence and status checks
- File metadata retrieval
- Text and binary read/write operations
- Directory listing and manipulation
- Path transformation and normalization
- Error state management

**Creation Procedures:**
- `make (a_path: READABLE_STRING_GENERAL)` - Create from path string
- `make_with_path (a_path: PATH)` - Create from PATH object

**Invariants:**
- `path_not_empty: not internal_path.is_empty`
- `path_model_consistent: path_model.count = internal_path.name.count`

**Collaborators:**
- PATH (composition)
- RAW_FILE, PLAIN_TEXT_FILE (internal usage)
- DIRECTORY (internal usage)
- SIMPLE_FILES (via with_temp_file)

---

### SIMPLE_FILES (expanded)

**Purpose:** Expanded class providing static-like convenience methods for one-liner file operations.

**Responsibilities:**
- Quick file/directory existence checks
- One-liner read operations
- One-liner write operations
- Path utility functions
- Temporary file support

**Creation Procedures:**
- None (expanded class)

**Key Features:**
- No instantiation required
- Stateless operations
- Delegates to SIMPLE_FILE internally

**Collaborators:**
- SIMPLE_FILE (delegation)
- PATH (path utilities)
- EXECUTION_ENVIRONMENT (temp directory)
- RANDOM, SIMPLE_DATE_TIME (temp file naming)

---

### SIMPLE_PATH

**Purpose:** Fluent builder for path construction with chaining support.

**Responsibilities:**
- Path component addition
- Path transformation (parent, extension, normalization)
- Path status queries
- Conversion to PATH and SIMPLE_FILE

**Creation Procedures:**
- `make` - Empty path
- `make_from (a_path: READABLE_STRING_GENERAL)` - From string
- `make_current` - Current directory
- `make_temp` - System temp directory
- `make_home` - User home directory

**Invariants:**
- `path_model_consistent: path_model.count = internal_path.name.count`

**Fluent Methods (return SIMPLE_PATH):**
- `add (a_component)`
- `joined alias "/" (a_component)`
- `up`
- `with_extension (a_ext)`
- `without_extension`

**Collaborators:**
- PATH (composition)
- SIMPLE_FILE (to_file conversion)
- EXECUTION_ENVIRONMENT (temp/home directories)

## Design Patterns

### Facade Pattern
SIMPLE_FILE acts as a facade, simplifying the complex ISE base library file classes.

### Builder Pattern
SIMPLE_PATH implements the builder pattern with fluent method chaining.

### Expanded Class Pattern
SIMPLE_FILES provides static-like convenience methods without requiring instantiation.

### Auto-Close Pattern
All read/write operations automatically open and close file handles.
