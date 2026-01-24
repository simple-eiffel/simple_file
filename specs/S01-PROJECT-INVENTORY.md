# S01 - Project Inventory

**Library:** simple_file
**Version:** 1.0.0
**Status:** BACKWASH (reverse-engineered from implementation)
**Generated:** 2026-01-23

## Overview

simple_file provides a simplified wrapper around EiffelStudio's base library file and directory classes (FILE, DIRECTORY, PATH). It offers an intuitive API for common file operations with Design by Contract support and MML (Mathematical Model Library) specification queries.

## Project Files

### Source Files (src/)

| File | Class | Description | LOC |
|------|-------|-------------|-----|
| simple_file.e | SIMPLE_FILE | Main file/directory wrapper class | ~1100 |
| simple_files.e | SIMPLE_FILES | Expanded convenience class for static-like operations | ~265 |
| simple_path.e | SIMPLE_PATH | Fluent path builder with chaining support | ~350 |

### Test Files (testing/)

| File | Description |
|------|-------------|
| test_app.e | Main test application entry point |
| lib_tests.e | Library test suite |
| file_test_app.e | File-specific test application |

### Research Files (research/)

| File | Description |
|------|-------------|
| SIMPLE_FILE_RESEARCH.md | 7-step research process documentation |

### Configuration Files

| File | Description |
|------|-------------|
| simple_file.ecf | ECF configuration |

## Dependencies

### ISE Libraries
- `$ISE_LIBRARY/library/base/base.ecf` - Base library (FILE, DIRECTORY, PATH, etc.)
- `$ISE_LIBRARY/library/time/time.ecf` - Time library for date/timestamp operations

### Ecosystem Dependencies
- simple_date_time - For timestamp conversions in SIMPLE_FILES

## Key Statistics

- **Total Source LOC:** ~1715
- **Number of Classes:** 3
- **Number of Features (SIMPLE_FILE):** ~65
- **Number of Features (SIMPLE_FILES):** ~22
- **Number of Features (SIMPLE_PATH):** ~25
- **MML Model Queries:** 4 (path_model, bytes_model, lines_model, entries_model)

## Phase Status

- Phase 1: Core functionality - COMPLETE
- Phase 2: Expanded features - COMPLETE
- Phase 3: Performance optimization - NOT STARTED
- Phase 4: API documentation - IN PROGRESS
- Phase 5: Test coverage - PARTIAL
- Phase 6: Production hardening - NOT STARTED
