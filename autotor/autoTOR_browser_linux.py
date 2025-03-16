#!/usr/bin/env python3
import os
import subprocess
import time
import signal
import sys
import requests

# Path to Tor Browser on Linux
TOR_BROWSER_PATH = os.path.expanduser("~/tor-browser/Browser/start-tor-browser")

def get_original_ip():
    try:
        response = requests.get('https://api.ipify.org')
        return response.text
    except:
        return "Failed to get IP"

def start_tor_browser():
    print("[+] Starting Tor Browser in background...")
    # Start Tor Browser in background
    subprocess.Popen([TOR_BROWSER_PATH, "--detach"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(10)  # Allow time for Tor to connect

def check_tor_ip():
    try:
        session = requests.session()
        session.proxies = {'http': 'socks5h://127.0.0.1:9150', 'https': 'socks5h://127.0.0.1:9150'}
        response = session.get('https://api.ipify.org')
        return response.text
    except:
        return "Failed to get IP through Tor"

def restart_tor():
    print("[+] Restarting Tor to change IP...")
    # Kill Tor Browser
    os.system("pkill -f firefox-bin")
    time.sleep(3)
    # Start it again
    start_tor_browser()
    time.sleep(10)

def main():
    print("\n" + "#" * 40)
    print("#" + " " * 10 + "Auto Tor IP Changer" + " " * 10 + "#")
    print("#" + " " * 10 + "Using Tor Browser" + " " * 11 + "#")
    print("#" * 40 + "\n")
    
    # Get original IP
    original_ip = get_original_ip()
    print(f"[+] Tor Browser found. Starting...")
    print(f"[+] Your original IP: {original_ip}")
    
    # Start Tor Browser
    start_tor_browser()
    
    # Get Tor IP
    tor_ip = check_tor_ip()
    print(f"[+] Your Tor IP: {tor_ip}")
    print(f"[+] Tor Browser is running and proxying connections on 127.0.0.1:9150")
    print(f"[+] Configure your applications to use SOCKS5 proxy at 127.0.0.1:9150")
    
    # Ask for time between changes
    change_time = input("[+] Time between IP changes in seconds [default=60]: ")
    if not change_time:
        change_time = 60
    else:
        change_time = int(change_time)
    
    # Ask for number of changes
    changes = input("[+] How many times to change IP? [Enter for infinite]: ")
    if not changes:
        changes = float('inf')
    else:
        changes = int(changes)
    
    print("[+] Starting infinite IP changes. Press Ctrl+C to stop.")
    
    count = 0
    try:
        while count < changes:
            if count > 0:
                restart_tor()
            
            count += 1
            ip = check_tor_ip()
            print(f"[+] IP changed {count} times. Current IP: {ip}")
            
            time.sleep(change_time)
            
    except KeyboardInterrupt:
        print("\n[+] Stopping IP rotation...")
        os.system("pkill -f firefox-bin")
        print("[+] Done. Goodbye!")

if __name__ == "__main__":
    main()