#!/bin/bash
# Quick launch script for RandomDom - Linux/Termux
# Run this for instant random task selection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
python3 randomdom.py --list main
