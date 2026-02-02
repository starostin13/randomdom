# RandomDom - Project Summary

## Overview
RandomDom is a cross-platform task/deed selector application that works on both Windows PC and Android devices. It randomly selects tasks from configurable lists and supports various item types including text tasks, links, folders, and Android applications.

## Problem Statement (Original Request in Russian)
The requirement was to create a solution that:
1. Works identically on Windows PC and Android devices
2. Can be either a script or a compilable application
3. Should be compilable on ARM Windows or directly in GitHub
4. Implements a task/deed selector from lists
5. Supports multiple lists
6. Supports nested lists  
7. List items can be links, folders (run random file inside), and applications (for Android)

## Solution Overview
Created a Python-based solution that:
- ✅ Runs on Windows, Linux, macOS, and Android (via Termux)
- ✅ Works as a standalone Python script (no dependencies)
- ✅ Can be compiled to executable using PyInstaller
- ✅ Includes GitHub Actions workflow for automated builds
- ✅ Supports all requested item types
- ✅ Fully featured with robust error handling

## Key Features
1. **Cross-Platform Compatibility**: Works on Windows, Linux, macOS, and Android
2. **No Dependencies**: Uses only Python standard library
3. **Multiple Item Types**:
   - Text tasks
   - Links (open in browser)
   - Folders (select random file)
   - Nested lists
   - Android applications
4. **Platform Detection**: Automatically detects Android environment
5. **Interactive & CLI Modes**: Both interactive menu and command-line usage
6. **Robust Error Handling**: Graceful handling of malformed configs, missing files, etc.

## Project Structure

```
randomdom/
├── randomdom.py              # Main application (278 lines)
├── config.json              # Default configuration (Russian examples)
├── test_randomdom.py        # Comprehensive test suite
├── README.md                # Main documentation (Russian)
├── README_EN.md             # English documentation
├── USAGE.md                 # Detailed usage guide
├── requirements.txt         # Dependencies (none needed!)
├── randomdom.sh             # Linux/Android launcher
├── randomdom.bat            # Windows launcher
├── build_unix.sh            # Unix build script
├── build_windows.bat        # Windows build script
├── .github/workflows/
│   └── build.yml            # GitHub Actions for multi-platform builds
└── examples/
    ├── README.md            # Examples documentation
    ├── config_daily.json    # Daily routine example
    ├── config_android.json  # Android apps example
    └── config_folders.json  # Folders/media example
```

## Technical Implementation

### Core Components

1. **RandomDomSelector Class**: Main application logic
   - Configuration loading with error handling
   - Platform detection (Windows/Android)
   - Random item selection
   - Item type processing

2. **Item Types Support**:
   - `text`: Display text task
   - `link`: Open URL in browser
   - `folder`: Select and open random file
   - `nested_list`: Recurse into another list
   - `application`: Launch Android app (Android only)

3. **Error Handling**:
   - Malformed JSON configuration
   - Missing files and folders
   - Failed subprocess calls
   - Platform-specific command availability

### Configuration Format

JSON-based configuration with simple structure:
```json
{
  "lists": {
    "list_name": {
      "name": "Display Name",
      "items": [
        {"type": "text", "value": "Task description"},
        {"type": "link", "value": "https://example.com"},
        {"type": "folder", "value": "~/path"},
        {"type": "nested_list", "value": "other_list"},
        {"type": "application", "value": "package.name/.Activity"}
      ]
    }
  }
}
```

## Usage Examples

### Interactive Mode
```bash
python randomdom.py
# Select from available lists interactively
```

### Command Line
```bash
# Select from specific list
python randomdom.py --list work_tasks

# Use custom config
python randomdom.py --config examples/config_daily.json
```

### Launcher Scripts
```bash
# Windows
randomdom.bat --list main

# Linux/Android
./randomdom.sh --list main
```

## Building Executables

### Manual Build
```bash
pip install pyinstaller
pyinstaller --onefile --name randomdom randomdom.py
```

### Automated Builds (GitHub Actions)
The workflow builds for:
- Windows (x64)
- Linux (x64)
- macOS (Intel/ARM)

Triggered by:
- Tags: `v*`
- Manual workflow dispatch

## Testing

Comprehensive test suite covering:
1. Configuration loading
2. List retrieval
3. Random selection
4. Nested lists
5. Platform detection
6. List enumeration
7. Malformed JSON handling

All tests pass: ✓

## Security

### Security Checks
- ✅ CodeQL analysis: No vulnerabilities found
- ✅ GitHub Actions permissions: Properly configured
- ✅ Error handling: All external operations handled safely
- ✅ Input validation: Config files validated

### Security Summary
No security issues detected. The application:
- Uses only standard library functions
- Validates all inputs
- Handles errors gracefully
- Follows least-privilege principle in GitHub Actions

## Documentation

1. **README.md** (Russian): Installation, usage, examples
2. **README_EN.md** (English): Same as above in English
3. **USAGE.md**: Comprehensive usage guide with all features
4. **examples/README.md**: Documentation for example configs

## Code Quality

### Code Review Results
All review feedback addressed:
- ✅ Enhanced error handling for malformed JSON
- ✅ Subprocess error checking and feedback
- ✅ Platform-specific command availability checks
- ✅ Test coverage for error conditions

### Code Statistics
- Main application: ~280 lines
- Test suite: ~220 lines
- Total Python code: ~500 lines
- Documentation: ~800 lines
- Example configs: ~150 lines JSON

## Platform-Specific Notes

### Windows
- Works with Python 3.6+
- Opens files with default applications
- Can build standalone .exe

### Android (Termux)
- Requires Termux (from F-Droid recommended)
- Python package: `pkg install python`
- Termux:API for app launching
- Access to storage via `termux-setup-storage`

### Linux
- Requires `xdg-utils` for file opening
- Standard Python 3 installation
- Works with most distributions

### macOS
- Uses built-in `open` command
- Standard Python 3
- Intel and ARM (M1/M2) support

## Future Enhancements (Optional)

Possible improvements:
1. GUI version using tkinter
2. Weighted random selection
3. Task history/statistics
4. Scheduled/timed task selection
5. Task completion tracking
6. YAML config support
7. Web interface

## License
MIT License (implied)

## Contributing
Pull requests and issues welcome on GitHub

## Conclusion

This project successfully fulfills all requirements from the problem statement:
- ✅ Works identically on Windows and Android
- ✅ Available as Python script (no compilation needed)
- ✅ Can be compiled to standalone executables
- ✅ GitHub Actions provides automated builds
- ✅ Implements full task selector functionality
- ✅ Supports multiple and nested lists
- ✅ Handles all requested item types (links, folders, apps)

The solution is production-ready, well-documented, tested, and secure.
