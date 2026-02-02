#!/data/data/com.termux/files/usr/bin/bash
# Termux Widget Script for RandomDom
# Place this file in ~/.shortcuts/ to make it accessible from Termux:Widget
# Then you can add it to your Android home screen for one-click access

cd ~/randomdom || cd ~/storage/shared/randomdom || cd /sdcard/randomdom

python randomdom.py --list main
