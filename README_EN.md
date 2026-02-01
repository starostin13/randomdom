# RandomDom - Random Task Selector

Cross-platform application for random task/deed selection from lists.
Works on Windows PC and Android devices.

## 🚀 Quick Start (One Click!)

### Windows
**Just double-click `quick-start.bat`** - no command line needed! 🎯

### Android (Termux)
**Install Termux:Widget and add widget to home screen** - launch with one tap! 📱

📖 **[Complete one-click setup guide →](ONE_CLICK_SETUP.md)**

## Features

- ✅ **One-click launch** - no command line required!
- ✅ Works on Windows and Android
- ✅ Multiple task lists
- ✅ Nested lists support
- ✅ Different item types:
  - Text tasks
  - Links (open in browser)
  - Folders (select random file)
  - Android applications (Android only)

## Installation

### Windows

1. Ensure Python 3.6+ is installed:
```bash
python --version
```

2. Download the files:
```bash
git clone https://github.com/starostin13/randomdom.git
cd randomdom
```

3. Run the application:
```bash
python randomdom.py
```

### Android (Termux)

1. Install Termux from F-Droid or Google Play

2. In Termux, install Python and Git:
```bash
pkg install python git
```

3. Download the application:
```bash
git clone https://github.com/starostin13/randomdom.git
cd randomdom
```

4. Run:
```bash
python randomdom.py
```

For Android app launching, Termux:API may be required.

## Usage

### Interactive Mode

Simply run without parameters:
```bash
python randomdom.py
```

Or explicitly with `-i` flag:
```bash
python randomdom.py -i
```

### Command Line

Select task from specific list:
```bash
python randomdom.py --list main
python randomdom.py --list work_tasks
```

Use custom config file:
```bash
python randomdom.py --config my_config.json
```

## Configuration

Configuration is stored in `config.json`. Example structure:

```json
{
  "lists": {
    "main": {
      "name": "Main Tasks",
      "items": [
        {
          "type": "text",
          "value": "Do exercise"
        },
        {
          "type": "link",
          "value": "https://github.com"
        },
        {
          "type": "nested_list",
          "value": "work_tasks"
        },
        {
          "type": "folder",
          "value": "~/Documents"
        },
        {
          "type": "application",
          "value": "com.android.chrome/.Main"
        }
      ]
    },
    "work_tasks": {
      "name": "Work Tasks",
      "items": [
        {
          "type": "text",
          "value": "Check email"
        }
      ]
    }
  }
}
```

### Item Types

#### `text` - Text Task
```json
{
  "type": "text",
  "value": "Task description"
}
```

#### `link` - Link
Opens in default browser:
```json
{
  "type": "link",
  "value": "https://example.com"
}
```

#### `folder` - Folder
Selects and opens random file from folder:
```json
{
  "type": "folder",
  "value": "/path/to/folder"
}
```
You can use `~` for home directory.

#### `nested_list` - Nested List
Navigate to another list:
```json
{
  "type": "nested_list",
  "value": "list_name"
}
```

#### `application` - Android Application
Launches app on Android (Android only):
```json
{
  "type": "application",
  "value": "com.package.name/.ActivityName"
}
```

To get package name and activity, use:
```bash
# In Termux
pm list packages  # list all packages
dumpsys package <package_name> | grep -A 1 "android.intent.action.MAIN"
```

## Examples

### Example 1: Simple Task List
```json
{
  "lists": {
    "daily": {
      "name": "Daily Tasks",
      "items": [
        {"type": "text", "value": "Exercise 15 minutes"},
        {"type": "text", "value": "Meditate 10 minutes"},
        {"type": "text", "value": "Read 20 pages"}
      ]
    }
  }
}
```

### Example 2: Nested Lists
```json
{
  "lists": {
    "main": {
      "name": "Main Menu",
      "items": [
        {"type": "nested_list", "value": "work"},
        {"type": "nested_list", "value": "hobby"},
        {"type": "text", "value": "Take a break"}
      ]
    },
    "work": {
      "name": "Work",
      "items": [
        {"type": "text", "value": "Code review"},
        {"type": "text", "value": "Write documentation"}
      ]
    },
    "hobby": {
      "name": "Hobby",
      "items": [
        {"type": "text", "value": "Drawing"},
        {"type": "text", "value": "Playing guitar"}
      ]
    }
  }
}
```

### Example 3: Multimedia
```json
{
  "lists": {
    "media": {
      "name": "Random Media",
      "items": [
        {"type": "folder", "value": "~/Music"},
        {"type": "folder", "value": "~/Videos"},
        {"type": "link", "value": "https://www.youtube.com"}
      ]
    }
  }
}
```

## Building Executable (Optional)

To create a standalone application, you can use PyInstaller:

### Windows
```bash
pip install pyinstaller
pyinstaller --onefile randomdom.py
```
Executable will be in `dist/` folder.

### Android
On Android, it's recommended to use as Python script through Termux.

## License

MIT License

## Contributing

Pull requests and issues are welcome on GitHub!
