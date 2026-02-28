#!/usr/bin/env python3
"""
RandomDom - Random Task/Deed Selector
Cross-platform application for Windows and Android
"""

import json
import os
import platform
import random
import sys
import subprocess
import webbrowser
from pathlib import Path
from typing import Dict, List, Union, Any


class RandomDomSelector:
    """Main class for random task selection"""
    
    def __init__(self, config_file: str = "config.json"):
        self.config_file = config_file
        self.config = self.load_config()
        self.is_android = self.detect_android()
    
    def detect_android(self) -> bool:
        """Detect if running on Android"""
        # Check for Android-specific indicators
        if hasattr(sys, 'getandroidapilevel'):
            return True
        # Check for Termux environment
        if os.environ.get('PREFIX', '').startswith('/data/data/com.termux'):
            return True
        # Check system properties on Android
        try:
            with open('/system/build.prop', 'r') as f:
                return True
        except (FileNotFoundError, PermissionError):
            pass
        return False
    
    def load_config(self) -> Dict:
        """Load configuration from JSON file"""
        if not os.path.exists(self.config_file):
            # Create default config
            default_config = {
                "lists": {
                    "main": {
                        "name": "Main Tasks",
                        "items": [
                            {"type": "text", "value": "Task 1"},
                            {"type": "text", "value": "Task 2"}
                        ]
                    }
                }
            }
            self.save_config(default_config)
            return default_config
        
        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except json.JSONDecodeError as e:
            print(f"Error: Invalid JSON in config file '{self.config_file}': {e}")
            print("Using default configuration instead.")
            return {
                "lists": {
                    "main": {
                        "name": "Main Tasks",
                        "items": [
                            {"type": "text", "value": "Task 1"},
                            {"type": "text", "value": "Task 2"}
                        ]
                    }
                }
            }
        except Exception as e:
            print(f"Error loading config file '{self.config_file}': {e}")
            print("Using default configuration instead.")
            return {
                "lists": {
                    "main": {
                        "name": "Main Tasks",
                        "items": [
                            {"type": "text", "value": "Task 1"},
                            {"type": "text", "value": "Task 2"}
                        ]
                    }
                }
            }
    
    def save_config(self, config: Dict):
        """Save configuration to JSON file"""
        with open(self.config_file, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
    
    def get_list(self, list_name: str) -> Dict:
        """Get a specific list by name"""
        return self.config.get("lists", {}).get(list_name)
    
    def select_random_item(self, list_name: str = "main") -> Union[Dict, None]:
        """Select a random item from a list"""
        list_data = self.get_list(list_name)
        if not list_data or not list_data.get("items"):
            print(f"List '{list_name}' not found or empty")
            return None
        
        items = list_data["items"]
        selected = random.choice(items)
        return selected
    
    def process_item(self, item: Dict) -> bool:
        """Process selected item based on its type"""
        item_type = item.get("type", "text")
        value = item.get("value")
        
        if item_type == "text":
            print(f"Selected: {value}")
            return True
        
        elif item_type == "link":
            print(f"Opening link: {value}")
            return self.open_link(value)
        
        elif item_type == "folder":
            print(f"Selecting random file from folder: {value}")
            return self.select_random_file(value)

        elif item_type == "file":
            print(f"Opening file: {value}")
            return self.open_file(value)
        
        elif item_type == "nested_list":
            print(f"Selecting from nested list: {value}")
            nested_item = self.select_random_item(value)
            if nested_item:
                return self.process_item(nested_item)
            return False
        
        elif item_type == "application":
            if self.is_android:
                print(f"Launching application: {value}")
                return self.launch_android_app(value)
            else:
                print(f"Application type only supported on Android: {value}")
                return False
        
        else:
            print(f"Unknown item type: {item_type}")
            return False
    
    def open_link(self, url: str) -> bool:
        """Open a link in default browser"""
        try:
            webbrowser.open(url)
            return True
        except Exception as e:
            print(f"Error opening link: {e}")
            return False

    def open_path_with_default_app(self, target_path: Path) -> bool:
        """Open path with system default application"""
        try:
            if platform.system() == 'Windows':
                if target_path.suffix.lower() in {'.bat', '.cmd'}:
                    result = subprocess.run([
                        'cmd', '/c', str(target_path)
                    ], cwd=str(target_path.parent), capture_output=True, text=True)
                    if result.returncode != 0:
                        print(f"Error opening file: {result.stderr}")
                        return False
                else:
                    os.startfile(str(target_path))
            elif platform.system() == 'Darwin':  # macOS
                result = subprocess.run(['open', str(target_path)],
                                      capture_output=True, text=True)
                if result.returncode != 0:
                    print(f"Error opening file: {result.stderr}")
                    return False
            else:  # Linux/Android
                result = subprocess.run(['xdg-open', str(target_path)],
                                      capture_output=True, text=True)
                if result.returncode != 0:
                    print(f"Error opening file: {result.stderr}")
                    print("Tip: Install xdg-utils if not available")
                    return False

            return True
        except FileNotFoundError as e:
            print(f"Required command not found: {e}")
            print("On Linux, install xdg-utils: sudo apt-get install xdg-utils")
            return False
        except Exception as e:
            print(f"Error opening file: {e}")
            return False

    def open_file(self, file_path: str) -> bool:
        """Open a specific file with default application"""
        try:
            path = Path(file_path).expanduser()
            if not path.exists() or not path.is_file():
                print(f"File not found: {file_path}")
                return False

            return self.open_path_with_default_app(path)
        except Exception as e:
            print(f"Error opening file: {e}")
            return False
    
    def select_random_file(self, folder_path: str) -> bool:
        """Select and open/execute random file from folder"""
        try:
            path = Path(folder_path).expanduser()
            if not path.exists() or not path.is_dir():
                print(f"Folder not found: {folder_path}")
                return False
            
            files = [f for f in path.iterdir() if f.is_file()]
            if not files:
                print(f"No files found in folder: {folder_path}")
                return False
            
            selected_file = random.choice(files)
            print(f"Selected file: {selected_file}")

            return self.open_path_with_default_app(selected_file)
        except Exception as e:
            print(f"Error selecting random file: {e}")
            return False
    
    def launch_android_app(self, package_name: str) -> bool:
        """Launch Android application by package name"""
        try:
            # Use am (Activity Manager) command to launch app
            result = subprocess.run([
                'am', 'start',
                '-a', 'android.intent.action.MAIN',
                '-n', package_name
            ], capture_output=True, text=True)
            
            if result.returncode != 0:
                print(f"Error launching Android app: {result.stderr}")
                print(f"Return code: {result.returncode}")
                return False
            
            return True
        except FileNotFoundError:
            print("Error: 'am' command not found. This feature only works on Android.")
            return False
        except Exception as e:
            print(f"Error launching Android app: {e}")
            return False
    
    def list_available_lists(self) -> List[str]:
        """List all available lists"""
        return list(self.config.get("lists", {}).keys())
    
    def run_interactive(self):
        """Run in interactive mode"""
        print("=" * 50)
        print("RandomDom - Random Task Selector")
        print("=" * 50)
        print(f"Platform: {'Android' if self.is_android else platform.system()}")
        print()
        
        available_lists = self.list_available_lists()
        if not available_lists:
            print("No lists available in config!")
            return
        
        print("Available lists:")
        for i, list_name in enumerate(available_lists, 1):
            list_data = self.get_list(list_name)
            print(f"{i}. {list_data.get('name', list_name)} ({len(list_data.get('items', []))} items)")
        
        print()
        choice = input(f"Select list (1-{len(available_lists)}) or press Enter for 'main': ").strip()
        
        if choice == "":
            selected_list = "main" if "main" in available_lists else available_lists[0]
        else:
            try:
                index = int(choice) - 1
                selected_list = available_lists[index]
            except (ValueError, IndexError):
                print("Invalid choice, using first list")
                selected_list = available_lists[0]
        
        print(f"\nSelecting from: {self.get_list(selected_list).get('name', selected_list)}")
        print("-" * 50)
        
        item = self.select_random_item(selected_list)
        if item:
            self.process_item(item)


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="RandomDom - Random Task Selector")
    parser.add_argument('-c', '--config', default='config.json', help='Config file path')
    parser.add_argument('-l', '--list', default='main', help='List name to select from')
    parser.add_argument('-i', '--interactive', action='store_true', help='Interactive mode')
    
    args = parser.parse_args()
    
    selector = RandomDomSelector(args.config)
    
    if args.interactive or len(sys.argv) == 1:
        selector.run_interactive()
    else:
        item = selector.select_random_item(args.list)
        if item:
            selector.process_item(item)


if __name__ == "__main__":
    main()
