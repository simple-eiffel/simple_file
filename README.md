<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
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
- **Directory Management** - List, create, delete directories
- **Streaming Support** - Memory-efficient large file processing
- **Path Utilities** - Cross-platform path manipulation
- **File Metadata** - Size, timestamps, extension, permissions

## Installation

1. Set environment variable:
```bash
export SIMPLE_FILE=/path/to/simple_file
```

2. Add to ECF:
```xml
<library name="simple_file" location="$SIMPLE_FILE/simple_file.ecf"/>
```

## License

MIT License
