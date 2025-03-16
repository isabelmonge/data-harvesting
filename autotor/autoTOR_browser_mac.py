#!/usr/bin/env python3
import os
import subprocess
import time
import signal
import sys
import requests

# Path to Tor Browser on macOS
TOR_BROWSER_PATH = "/Applications/Tor Browser.app/Contents/MacOS/firefox"

def get_original_ip():
    try:
        response = requests.get('https://api.ipify.org')
        return response.text
    except:
        return "Failed to get IP"

def start_tor_browser():
    print("[+] Starting Tor Browser in background...")
    # Start Tor Browser in background
    subprocess.Popen([TOR_BROWSER_PATH, "-n"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(10)  # Allow time for Tor to connect

# ... rest of Python code ...

if __name__ == "__main__":
    main()