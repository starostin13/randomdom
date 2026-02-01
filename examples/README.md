# Example Configurations

This directory contains example configuration files for different use cases.

## Available Examples

### 1. config_daily.json
Daily routine and task organizer with nested lists for different times of day:
- Morning routine
- Work tasks
- Break activities
- Learning activities
- Evening routine

**Usage:**
```bash
python randomdom.py --config examples/config_daily.json
```

### 2. config_android.json
Android-specific configuration for launching apps:
- App launcher with popular apps
- Productivity apps
- Mixed tasks (text, links, and apps)

**Note:** This is designed for Android devices using Termux.

**Usage:**
```bash
python randomdom.py --config examples/config_android.json
```

### 3. config_folders.json
File and folder-based configuration:
- Random media selection from folders
- Music selection from categorized folders
- Document selection

**Usage:**
```bash
python randomdom.py --config examples/config_folders.json
```

**Note:** Make sure the folders specified in the config exist on your system, or modify the paths to match your directory structure.

## Creating Your Own Configuration

You can create your own configuration file by copying one of these examples and modifying it to suit your needs. The basic structure is:

```json
{
  "lists": {
    "list_name": {
      "name": "Display Name",
      "items": [
        {"type": "text", "value": "Task description"},
        {"type": "link", "value": "https://example.com"},
        {"type": "folder", "value": "/path/to/folder"},
        {"type": "nested_list", "value": "another_list_name"},
        {"type": "application", "value": "com.package.name/.Activity"}
      ]
    }
  }
}
```

## Tips

1. **Nested Lists**: Use nested lists to organize tasks hierarchically
2. **Folder Paths**: Use absolute paths or `~` for home directory
3. **Android Apps**: Find package names using `pm list packages` in Termux
4. **Testing**: Test your config with `python randomdom.py --config your_config.json --list list_name`
