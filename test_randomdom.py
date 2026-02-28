#!/usr/bin/env python3
"""
Simple tests for RandomDom
Run with: python3 test_randomdom.py
"""

import json
import os
import sys
import tempfile
from pathlib import Path
from unittest import mock

# Add the parent directory to the path so we can import randomdom
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from randomdom import RandomDomSelector


def test_config_loading():
    """Test configuration loading"""
    print("Test 1: Configuration Loading...")
    
    # Create a temporary config
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        config = {
            "lists": {
                "test": {
                    "name": "Test List",
                    "items": [
                        {"type": "text", "value": "Task 1"},
                        {"type": "text", "value": "Task 2"}
                    ]
                }
            }
        }
        json.dump(config, f)
        temp_config = f.name
    
    try:
        selector = RandomDomSelector(temp_config)
        assert selector.config is not None
        assert "lists" in selector.config
        print("✓ Config loaded successfully")
    finally:
        os.unlink(temp_config)


def test_list_retrieval():
    """Test list retrieval"""
    print("Test 2: List Retrieval...")
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        config = {
            "lists": {
                "test": {
                    "name": "Test List",
                    "items": [{"type": "text", "value": "Task 1"}]
                }
            }
        }
        json.dump(config, f)
        temp_config = f.name
    
    try:
        selector = RandomDomSelector(temp_config)
        test_list = selector.get_list("test")
        assert test_list is not None
        assert test_list["name"] == "Test List"
        assert len(test_list["items"]) == 1
        print("✓ List retrieved successfully")
    finally:
        os.unlink(temp_config)


def test_random_selection():
    """Test random item selection"""
    print("Test 3: Random Selection...")
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        config = {
            "lists": {
                "test": {
                    "name": "Test List",
                    "items": [
                        {"type": "text", "value": "Task 1"},
                        {"type": "text", "value": "Task 2"},
                        {"type": "text", "value": "Task 3"}
                    ]
                }
            }
        }
        json.dump(config, f)
        temp_config = f.name
    
    try:
        selector = RandomDomSelector(temp_config)
        
        # Test multiple selections
        selections = set()
        for _ in range(10):
            item = selector.select_random_item("test")
            assert item is not None
            assert item["type"] == "text"
            assert item["value"] in ["Task 1", "Task 2", "Task 3"]
            selections.add(item["value"])
        
        print(f"✓ Random selection working (selected {len(selections)} unique items)")
    finally:
        os.unlink(temp_config)


def test_nested_lists():
    """Test nested list functionality"""
    print("Test 4: Nested Lists...")
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        config = {
            "lists": {
                "main": {
                    "name": "Main List",
                    "items": [
                        {"type": "nested_list", "value": "sub"}
                    ]
                },
                "sub": {
                    "name": "Sub List",
                    "items": [
                        {"type": "text", "value": "Sub Task"}
                    ]
                }
            }
        }
        json.dump(config, f)
        temp_config = f.name
    
    try:
        selector = RandomDomSelector(temp_config)
        item = selector.select_random_item("main")
        assert item is not None
        assert item["type"] == "nested_list"
        assert item["value"] == "sub"
        print("✓ Nested lists working")
    finally:
        os.unlink(temp_config)


def test_platform_detection():
    """Test platform detection"""
    print("Test 5: Platform Detection...")
    
    selector = RandomDomSelector()
    assert isinstance(selector.is_android, bool)
    print(f"✓ Platform detected: {'Android' if selector.is_android else 'Desktop'}")


def test_list_available_lists():
    """Test listing available lists"""
    print("Test 6: List Available Lists...")
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        config = {
            "lists": {
                "list1": {"name": "List 1", "items": []},
                "list2": {"name": "List 2", "items": []},
                "list3": {"name": "List 3", "items": []}
            }
        }
        json.dump(config, f)
        temp_config = f.name
    
    try:
        selector = RandomDomSelector(temp_config)
        available = selector.list_available_lists()
        assert len(available) == 3
        assert "list1" in available
        assert "list2" in available
        assert "list3" in available
        print("✓ List enumeration working")
    finally:
        os.unlink(temp_config)


def test_malformed_json():
    """Test handling of malformed JSON config"""
    print("Test 7: Malformed JSON Handling...")
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        # Write invalid JSON
        f.write("{invalid json content}")
        temp_config = f.name
    
    try:
        # Should not crash, should use default config
        selector = RandomDomSelector(temp_config)
        assert selector.config is not None
        assert "lists" in selector.config
        print("✓ Malformed JSON handled gracefully")
    finally:
        os.unlink(temp_config)


def test_windows_bat_uses_file_directory_as_cwd():
    """Test that Windows .bat files run from their own directory"""
    print("Test 8: Windows BAT Working Directory...")

    selector = RandomDomSelector()
    bat_path = Path(r"C:\temp\example folder\run-script.bat")

    with mock.patch('randomdom.platform.system', return_value='Windows'), \
         mock.patch('randomdom.subprocess.run') as mock_run:
        mock_run.return_value = mock.Mock(returncode=0, stderr='')

        success = selector.open_path_with_default_app(bat_path)

        assert success is True
        mock_run.assert_called_once_with(
            ['cmd', '/c', str(bat_path)],
            cwd=str(bat_path.parent),
            capture_output=True,
            text=True
        )

    print("✓ Windows BAT uses file directory as cwd")


def run_all_tests():
    """Run all tests"""
    print("=" * 50)
    print("RandomDom Test Suite")
    print("=" * 50)
    print()
    
    try:
        test_config_loading()
        test_list_retrieval()
        test_random_selection()
        test_nested_lists()
        test_platform_detection()
        test_list_available_lists()
        test_malformed_json()
        test_windows_bat_uses_file_directory_as_cwd()
        
        print()
        print("=" * 50)
        print("All tests passed! ✓")
        print("=" * 50)
        return True
    except AssertionError as e:
        print(f"\n✗ Test failed: {e}")
        return False
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
