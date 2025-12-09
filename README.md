# SIMPLE_FILE

Simple file and directory operations wrapper for Eiffel applications.

## Features

- File status checking (exists, readable, writable, executable)
- File metadata (size, timestamps, extension)
- Read operations (text, bytes, lines)
- Write operations (text, bytes, lines, append)
- File operations (copy, move, rename, delete)
- Directory operations (list, create, delete)
- Streaming for large files
- Path transformation utilities
- Error handling with descriptive messages

## Installation

Add to your ECF file:

```xml
<library name="simple_file" location="$SIMPLE_FILE/simple_file.ecf"/>
```

Set the environment variable:
```
SIMPLE_FILE=/path/to/simple_file
```

## Quick Start

```eiffel
local
    f: SIMPLE_FILE
    content: STRING_32
do
    create f.make ("config.json")

    -- Check if file exists
    if f.exists then
        -- Read entire file
        content := f.read_text

        -- Get file info
        print ("Size: " + f.size.out + " bytes%N")
        print ("Extension: " + f.extension + "%N")
    end

    -- Write to a file
    create f.make ("output.txt")
    if f.write_text ("Hello, World!") then
        print ("File written successfully%N")
    end
end
```

## API Overview

### File Status
| Feature | Description |
|---------|-------------|
| `exists` | Does file/directory exist? |
| `is_readable` | Can file be read? |
| `is_writable` | Can file be written? |
| `is_directory` | Is this a directory? |
| `is_file` | Is this a regular file? |

### File Metadata
| Feature | Description |
|---------|-------------|
| `size` | Size in bytes |
| `extension` | File extension |
| `base_name` | Name without extension |
| `file_name` | Full file name |
| `parent_path` | Parent directory |

### Read Operations
| Feature | Description |
|---------|-------------|
| `read_text` | Read entire file as text |
| `read_bytes` | Read as byte array |
| `read_lines` | Read all lines |
| `each_line` | Stream lines (memory efficient) |

### Write Operations
| Feature | Description |
|---------|-------------|
| `write_text` | Write text (overwrites) |
| `write_bytes` | Write bytes |
| `append_text` | Append text |
| `append_line` | Append line with newline |

### File Operations
| Feature | Description |
|---------|-------------|
| `copy_to` | Copy file |
| `move_to` | Move file |
| `rename_to` | Rename file |
| `delete` | Delete file |

### Directory Operations
| Feature | Description |
|---------|-------------|
| `entries` | All entries in directory |
| `files` | Only files |
| `directories` | Only subdirectories |
| `create_directory` | Create directory |
| `delete_directory_recursive` | Delete with contents |

## Documentation

- [API Documentation](https://simple-eiffel.github.io/simple_file/)

## License

MIT License - see LICENSE file for details.

## Author

Larry Rix
