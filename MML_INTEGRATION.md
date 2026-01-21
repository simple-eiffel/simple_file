# MML Integration - simple_file

## Overview
Applied X03 Contract Assault with simple_mml on 2025-01-21.

## MML Classes Used
- `MML_SEQUENCE [CHARACTER_32]` - Models file path as char sequence
- `MML_SEQUENCE [NATURAL_8]` - Models binary file content
- `MML_SEQUENCE [STRING_32]` - Models text lines and path components
- `MML_SET [STRING_32]` - Models directory entries

## Model Queries Added
- `path_model: MML_SEQUENCE [CHARACTER_32]` - Path as chars
- `bytes_model: MML_SEQUENCE [NATURAL_8]` - Binary content
- `lines_model: MML_SEQUENCE [STRING_32]` - Text lines
- `entries_model: MML_SET [STRING_32]` - Directory contents
- `components_model: MML_SEQUENCE [STRING_32]` - Path components

## Model-Based Postconditions
| Feature | Postcondition | Purpose |
|---------|---------------|---------|
| `make` | `path_model_matches`, `no_error` | Init state |
| `write_text` | `success_implies_exists`, `path_unchanged` | Write correctness |
| `write_bytes` | `success_implies_size` | Size matches |
| `append_text` | `size_increased` | Append grows file |
| `copy_to` | `source_unchanged`, `source_content_unchanged` | Copy preserves |
| `delete` | `success_implies_gone` | Delete removes |
| `entries` | `result_count_matches_model` | Dir listing |

## Invariants Added
- `path_not_empty` - Path never empty
- `path_model_consistent` - Model matches path

## Bugs Found
None

## Test Results
- Compilation: SUCCESS
- Tests: 14/14 PASS
