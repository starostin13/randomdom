# RandomDom Usage Guide

Complete guide for using RandomDom task selector.

## Table of Contents
1. [Quick Start](#quick-start)
2. [Command Line Interface](#command-line-interface)
3. [Configuration Files](#configuration-files)
4. [Item Types](#item-types)
5. [Advanced Usage](#advanced-usage)
6. [Platform-Specific Notes](#platform-specific-notes)

## Quick Start

### Windows
```bash
# Clone the repository
git clone https://github.com/starostin13/randomdom.git
cd randomdom

# Run the application
python randomdom.py
```

### Android (Termux)
```bash
# Install required packages
pkg install python git

# Clone the repository
git clone https://github.com/starostin13/randomdom.git
cd randomdom

# Run the application
python randomdom.py
```

## Command Line Interface

### Interactive Mode
Launch interactive mode to select from available lists:
```bash
python randomdom.py
# or explicitly
python randomdom.py -i
```

### Direct Selection
Select from a specific list without interaction:
```bash
python randomdom.py --list main
python randomdom.py --list work_tasks
```

### Custom Configuration
Use a custom configuration file:
```bash
python randomdom.py --config my_tasks.json
python randomdom.py --config examples/config_daily.json --list morning_routine
```

### Using Launcher Scripts

**Windows:**
```bash
randomdom.bat
randomdom.bat --list work
```

**Linux/Android:**
```bash
./randomdom.sh
./randomdom.sh --list work
```

## Configuration Files

### Basic Structure
```json
{
  "lists": {
    "list_name": {
      "name": "Display Name",
      "items": [
        {"type": "text", "value": "Description"},
        {"type": "link", "value": "https://example.com"}
      ]
    }
  }
}
```

### Multiple Lists
```json
{
  "lists": {
    "work": {
      "name": "Work Tasks",
      "items": [...]
    },
    "personal": {
      "name": "Personal Tasks",
      "items": [...]
    }
  }
}
```

## Item Types

### 1. Text (`text`)
Simple text task that gets displayed.

```json
{
  "type": "text",
  "value": "Do morning exercise"
}
```

**Output:** Displays the text to the console.

### 2. Link (`link`)
URL that opens in the default browser.

```json
{
  "type": "link",
  "value": "https://github.com"
}
```

**Output:** Opens the URL in your default web browser.

### 3. Folder (`folder`)
Selects a random file from a folder and opens it.

```json
{
  "type": "folder",
  "value": "~/Music"
}
```

**Supported paths:**
- Absolute: `/home/user/Music`
- Home relative: `~/Music`
- Windows: `C:\\Users\\Username\\Music`

**Output:** Opens a random file from the folder with the default application.

### 4. File (`file`)
Opens a specific file with the default application.

```json
{
  "type": "file",
  "value": "~/Documents/note.txt"
}
```

**Supported paths:**
- Absolute: `/home/user/Documents/note.txt`
- Home relative: `~/Documents/note.txt`
- Windows: `C:\\Users\\Username\\Documents\\note.txt`

**Output:** Opens the specified file with the default application.

### 5. Nested List (`nested_list`)
References another list for selection.

```json
{
  "type": "nested_list",
  "value": "work_tasks"
}
```

**Output:** Selects a random item from the referenced list.

### 6. Application (`application`) - Android Only
Launches an Android application.

```json
{
  "type": "application",
  "value": "com.android.chrome/.Main"
}
```

**Format:** `package_name/activity_name`

**Finding package names:**
```bash
# List all packages
pm list packages

# Find main activity
dumpsys package <package_name> | grep -A 1 "android.intent.action.MAIN"
```

**Common examples:**
- Chrome: `com.android.chrome/com.google.android.apps.chrome.Main`
- YouTube: `com.google.android.youtube/.HomeActivity`
- Gmail: `com.google.android.gm/.ConversationListActivityGmail`

## Advanced Usage

### Creating Nested List Hierarchies

```json
{
  "lists": {
    "main": {
      "name": "Main Menu",
      "items": [
        {"type": "nested_list", "value": "morning"},
        {"type": "nested_list", "value": "work"},
        {"type": "nested_list", "value": "evening"}
      ]
    },
    "morning": {
      "name": "Morning Routine",
      "items": [
        {"type": "text", "value": "Breakfast"},
        {"type": "nested_list", "value": "exercise"}
      ]
    },
    "exercise": {
      "name": "Exercise Options",
      "items": [
        {"type": "text", "value": "Yoga"},
        {"type": "text", "value": "Running"},
        {"type": "link", "value": "https://www.youtube.com/workout"}
      ]
    },
    "work": {
      "name": "Work Tasks",
      "items": [...]
    },
    "evening": {
      "name": "Evening Routine",
      "items": [...]
    }
  }
}
```

### Mixing Different Types

```json
{
  "lists": {
    "media_break": {
      "name": "Media Break",
      "items": [
        {"type": "folder", "value": "~/Music"},
        {"type": "folder", "value": "~/Videos"},
        {"type": "link", "value": "https://www.youtube.com"},
        {"type": "link", "value": "https://open.spotify.com"},
        {"type": "text", "value": "Read a book"}
      ]
    }
  }
}
```

### Platform-Specific Configurations

Create separate configs for different platforms:

**android_tasks.json:**
```json
{
  "lists": {
    "main": {
      "name": "Android Tasks",
      "items": [
        {"type": "application", "value": "com.android.chrome/.Main"},
        {"type": "link", "value": "https://mobile.twitter.com"}
      ]
    }
  }
}
```

**windows_tasks.json:**
```json
{
  "lists": {
    "main": {
      "name": "Windows Tasks",
      "items": [
        {"type": "folder", "value": "C:\\Users\\Username\\Documents"},
        {"type": "link", "value": "https://outlook.office.com"}
      ]
    }
  }
}
```

## Platform-Specific Notes

### Windows
- Use backslashes (`\\`) or forward slashes (`/`) in paths
- Folder items open files with default associated programs
- Requires Python 3.6+ (download from python.org)

### Android (Termux)
- Install Termux from F-Droid (recommended) or Play Store
- Install Termux:API for app launching
- Storage access: `termux-setup-storage`
- Paths typically start with `/data/data/com.termux/`
- Use `~/storage/shared/` to access main storage

### Linux
- Requires `xdg-open` for opening files (usually pre-installed)
- Use standard Unix paths
- May require additional permissions for some folders

### macOS
- Uses `open` command for files (built-in)
- Standard Unix paths with home directory support

## Troubleshooting

### Issue: "List not found"
**Solution:** Check that the list name in your command matches the config file.

### Issue: Folder not opening on Linux
**Solution:** Install `xdg-utils`: `sudo apt-get install xdg-utils`

### Issue: Android app not launching
**Solution:** 
1. Install Termux:API
2. Verify package name with `pm list packages | grep <app>`
3. Grant necessary permissions

### Issue: Python not found
**Solution:**
- Windows: Download from python.org
- Linux: `sudo apt-get install python3`
- Android: `pkg install python`

## Building Executables

### Windows
```bash
pip install pyinstaller
pyinstaller --onefile --name randomdom randomdom.py
# Executable: dist\randomdom.exe
```

### Linux
```bash
pip3 install pyinstaller
pyinstaller --onefile --name randomdom randomdom.py
# Executable: dist/randomdom
```

### Using Build Scripts
```bash
# Windows
build_windows.bat

# Linux/macOS
./build_unix.sh
```

## Tips and Best Practices

1. **Organize with nested lists:** Use nested lists to create hierarchies
2. **Backup your configs:** Keep backups of your configuration files
3. **Use descriptive names:** Make list names and task descriptions clear
4. **Test paths:** Verify folder paths exist before adding them
5. **Start simple:** Begin with text items, then add complexity
6. **Platform separation:** Consider separate configs for different platforms

## Examples

See the `examples/` directory for complete working examples:
- `config_daily.json` - Daily routine organizer
- `config_android.json` - Android app launcher
- `config_folders.json` - File and folder selector
