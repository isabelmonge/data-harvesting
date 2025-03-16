#!/bin/bash

# Check if Tor Browser is installed
if [ ! -d "$HOME/tor-browser" ]; then
    echo "Tor Browser not found. Downloading and installing..."
    cd ~/Downloads
    wget https://www.torproject.org/dist/torbrowser/13.0.7/tor-browser-linux64-13.0.7_ALL.tar.xz
    tar -xf tor-browser-linux64-13.0.7_ALL.tar.xz
    mv tor-browser ~/tor-browser
    echo "Tor Browser installed."
fi

# Clone the repository if it doesn't exist
if [ ! -d "$HOME/Auto_Tor_IP_changer" ]; then
    echo "Cloning Auto_Tor_IP_changer repository..."
    git clone https://github.com/FDX100/Auto_Tor_IP_changer.git ~/Auto_Tor_IP_changer
fi

# Create necessary directories
mkdir -p ~/bin

# Copy our modified script to the Auto_Tor_IP_changer directory
cp "$(dirname "$0")/autoTOR_browser_linux.py" ~/Auto_Tor_IP_changer/autoTOR_browser.py

# Make the script executable
chmod +x ~/Auto_Tor_IP_changer/autoTOR_browser.py

# Create a launcher script
cat > ~/bin/aut << 'EOF'
#!/bin/bash
python3 ~/Auto_Tor_IP_changer/autoTOR_browser.py
EOF

# Make the launcher executable
chmod +x ~/bin/aut

# Add ~/bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
    echo "Added ~/bin to PATH in ~/.bashrc. Run 'source ~/.bashrc' to update your current session."
fi

echo "Installation complete. Run 'aut' to start the Auto Tor IP Changer."