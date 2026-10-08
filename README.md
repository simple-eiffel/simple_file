<p align="center">
  <img src="docs/images/logo.svg" alt="simple_file logo" width="400">
</p>

# simple_file

**[Documentation](https://simple-eiffel.github.io/simple_file/)** | **[GitHub](https://github.com/simple-eiffel/simple_file)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

Simple file and directory operations for Eiffel applications.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Production**

## Overview

SIMPLE_FILE wraps standard Eiffel file classes with a simpler interface and better error handling. Read, write, copy, move files with one-line operations.

```eiffel
local
    f: SIMPLE_FILE
do
    create f.make ("config.json")
    if f.exists then
        print (f.read_text)
        print ("Size: " + f.size.out + " bytes%N")
    end
end
```

## Features

- **File Operations** - Read, write, copy, move, delete
- **Crash-safe writes** - `write_text`, `write_bytes`, `write_lines` replace a file atomically (temp file in the same folder, flush, `MoveFileExW` with write-through): a killed process leaves the old content or the new, never an empty file (0 of 400 kills, 1.1.0)
- **Every failure reported** - writes return False with `last_error` and the Win32 `last_error_code`; nothing is refused because a folder carries the ReadOnly attribute (as OneDrive folders do)
- **Safe file names** - `{SIMPLE_FILES}.file_safe_name` turns any text (a verse reference like `John 3:16`, a title with `?` or `"`) into a usable Windows file name; writes refuse a `:` that would land the body in a hidden NTFS stream
- **UTF-8 text** - `read_text_utf_8` / `write_text_utf_8` round-trip any text exactly (`read_text` keeps its 1.0 one-character-per-byte behavior)
- **Directory Management** - List (one `FindFirstFileExW` pass: 100,000 files in about 130 ms), create, delete directories
- **Streaming Support** - Memory-efficient large file processing
- **Path Utilities** - Cross-platform path manipulation
- **File Metadata** - Size, timestamps (whole seconds, or 100 ns with `modified_time_100ns`), extension, permissions

```eiffel
local
    files: SIMPLE_FILES
    f: SIMPLE_FILE
do
    create f.make ({STRING_32} "notes\" + files.file_safe_name ("John 3:16") + {STRING_32} ".md")   -- notes\John 3_16.md
    if not f.write_text_utf_8 (body) then
        print ({STRING_32} "Save failed: " + f.last_error + {STRING_32} "%N")
    end
end
```

`ReplaceFileW` is never used: it can destroy an outside edit that lands during the call while still returning success. A whole-file save, this one included, replaces any outside edit made between your read and your write.

## Installation

1. Set environment variable (one-time setup for all simple_* libraries):
```bash
export SIMPLE_EIFFEL=D:\prod
```

2. Add to ECF:
```xml
<library name="simple_file" location="$SIMPLE_EIFFEL/simple_file/simple_file.ecf"/>
```

## License

MIT License
