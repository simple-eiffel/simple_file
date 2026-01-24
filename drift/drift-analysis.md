# Drift Analysis: simple_file

Generated: 2026-01-24
Method: `ec.exe -flatshort` vs `specs/*.md` + `research/*.md`

## Specification Sources

| Source | Files | Lines |
|--------|-------|-------|
| specs/*.md | 8 | 1146 |
| research/*.md | 1 | 544 |

## Classes Analyzed

| Class | Spec'd Features | Actual Features | Drift |
|-------|-----------------|-----------------|-------|
| SIMPLE_FILE | 28 | 106 | +78 |

## Feature-Level Drift

### Specified, Implemented ✓
- `each_line` ✓
- `has_error` ✓
- `last_error` ✓
- `make_readable` ✓
- `make_writable` ✓
- `read_bytes` ✓
- `read_lines` ✓
- `read_text` ✓
- `with_temp_file` ✓

### Specified, NOT Implemented ✗
- `create_dir` ✗
- `detect_encoding` ✗
- `ensure_directory` ✗
- `make_current` ✗
- `make_home` ✗
- `make_open_temporary` ✗
- `make_temp` ✗
- `put_encoding_bom` ✗
- `put_new_line` ✗
- `read_character` ✗
- ... and 9 more

### Implemented, NOT Specified
- `Io`
- `Operating_environment`
- `absolute_path`
- `accessed_timestamp`
- `append_line`
- `append_text`
- `author`
- `base_name`
- `binary_content`
- `byte_count`
- ... and 87 more

## Summary

| Category | Count |
|----------|-------|
| Spec'd, implemented | 9 |
| Spec'd, missing | 19 |
| Implemented, not spec'd | 97 |
| **Overall Drift** | **HIGH** |

## Conclusion

**simple_file** has high drift. Significant gaps between spec and implementation.
