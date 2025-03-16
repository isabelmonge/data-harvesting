#!/bin/bash

# Clone the repository if it doesn't exist
if [ ! -d "$HOME/Auto_Tor_IP_changer" ]; then
    echo "Cloning Auto_Tor_IP_changer repository..."
    git clone https://github.com/FDX100/Auto_Tor_IP_changer.git ~/Auto_Tor_IP_changer
fi

# Create necessary directories
mkdir -p ~/bin

# Copy our modified script to the Auto_Tor_IP_changer directory
cp "$(dirname "$0")/autoTOR_browser_mac.py" ~/Auto_Tor_IP_changer/autoTOR_browser.py

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
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
    echo "Added ~/bin to PATH in ~/.zshrc. Run 'source ~/.zshrc' to update your current session."
fi

echo "Installation complete. Run 'aut' to start the Auto Tor IP Changer."