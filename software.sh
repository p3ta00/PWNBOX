#!/bin/bash

# Software Installation Script
# Installs Cargo, RustScan, and latest Obsidian

set -e  # Exit on any error

echo "🚀 Starting software installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on a Debian/Ubuntu system
if ! command -v apt &> /dev/null; then
    print_error "This script requires apt package manager (Debian/Ubuntu)"
    exit 1
fi

# Update package list
print_status "Updating package list..."
sudo apt update

# Install Rust and Cargo
print_status "Installing Rust and Cargo..."
if command -v cargo &> /dev/null; then
    print_warning "Cargo is already installed"
    cargo --version
else
    print_status "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    print_status "Rust and Cargo installed successfully"
    cargo --version
fi

# Install RustScan
print_status "Installing RustScan..."
if command -v rustscan &> /dev/null; then
    print_warning "RustScan is already installed"
    rustscan --version
else
    print_status "Installing RustScan..."
    
    # Try installing from git (latest version) to avoid dependency conflicts
    print_status "Attempting to install RustScan from git repository..."
    if cargo install --git https://github.com/RustScan/RustScan.git rustscan; then
        print_status "RustScan installed successfully from git"
    else
        print_warning "Git installation failed, trying alternative methods..."
        
        # Try installing a specific working version
        print_status "Trying to install RustScan v2.3.0 (known working version)..."
        if cargo install rustscan --version 2.3.0; then
            print_status "RustScan v2.3.0 installed successfully"
        else
            print_warning "Cargo installation failed, trying .deb package..."
            
            # Try installing from .deb package as last resort
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            
            # Download the .deb package
            RUSTSCAN_URL="https://github.com/RustScan/RustScan/releases/download/2.3.0/rustscan_2.3.0_amd64.deb"
            print_status "Downloading RustScan .deb package..."
            
            if curl -L -o rustscan.deb "$RUSTSCAN_URL"; then
                print_status "Installing RustScan from .deb package..."
                sudo dpkg -i rustscan.deb
                sudo apt install -f -y  # Fix any dependency issues
                print_status "RustScan installed from .deb package"
            else
                print_error "All RustScan installation methods failed"
                print_error "You may need to install RustScan manually"
            fi
            
            cd - > /dev/null
            rm -rf "$TEMP_DIR"
        fi
    fi
fi

# Install Discord
print_status "Installing Discord..."

# Check if Discord is already installed
if command -v discord &> /dev/null; then
    print_warning "Discord is already installed"
    read -p "Do you want to update to the latest version? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping Discord installation"
        INSTALL_DISCORD=false
    else
        INSTALL_DISCORD=true
    fi
else
    INSTALL_DISCORD=true
fi

if [[ "$INSTALL_DISCORD" == "true" ]]; then
    print_status "Downloading latest Discord..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Discord always provides the latest version at this URL
    DISCORD_URL="https://discord.com/api/download?platform=linux&format=deb"
    
    print_status "Downloading Discord from: $DISCORD_URL"
    curl -L -o discord.deb "$DISCORD_URL"
    
    # Install Discord
    print_status "Installing Discord..."
    sudo dpkg -i discord.deb
    
    # Fix any dependency issues
    sudo apt install -f -y
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    print_status "Discord installed successfully"
fi

# Install Obsidian
print_status "Installing Obsidian..."

# Function to get latest Obsidian release
get_latest_obsidian_url() {
    local api_url="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"
    local download_url=$(curl -s "$api_url" | grep -o '"browser_download_url": "[^"]*amd64\.deb"' | cut -d'"' -f4)
    echo "$download_url"
}

# Check if Obsidian is already installed
if command -v obsidian &> /dev/null; then
    print_warning "Obsidian is already installed"
    print_status "Current version: $(obsidian --version 2>/dev/null || echo 'Version info not available')"
    read -p "Do you want to update to the latest version? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping Obsidian installation"
    else
        INSTALL_OBSIDIAN=true
    fi
else
    INSTALL_OBSIDIAN=true
fi

if [[ "$INSTALL_OBSIDIAN" == "true" ]]; then
    print_status "Fetching latest Obsidian release information..."
    
    # Get the latest download URL
    OBSIDIAN_URL=$(get_latest_obsidian_url)
    
    if [[ -z "$OBSIDIAN_URL" ]]; then
        print_error "Could not fetch latest Obsidian release URL"
        print_status "Falling back to provided URL..."
        OBSIDIAN_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.8.10/obsidian_1.8.10_amd64.deb"
    fi
    
    print_status "Downloading Obsidian from: $OBSIDIAN_URL"
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download the .deb file
    OBSIDIAN_DEB=$(basename "$OBSIDIAN_URL")
    curl -L -o "$OBSIDIAN_DEB" "$OBSIDIAN_URL"
    
    # Install dependencies that might be needed
    print_status "Installing dependencies..."
    sudo apt install -y wget gpg
    
    # Install the .deb package
    print_status "Installing Obsidian..."
    sudo dpkg -i "$OBSIDIAN_DEB"
    
    # Fix any dependency issues
    sudo apt install -f -y
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    print_status "Obsidian installed successfully"
fi

# Verify installations
echo
print_status "Verifying installations..."

echo "Cargo version:"
cargo --version

echo "RustScan version:"
if command -v rustscan &> /dev/null; then
    rustscan --version
else
    print_error "RustScan not found in PATH. You may need to restart your shell or run 'source ~/.cargo/env'"
fi

echo "Discord:"
if command -v discord &> /dev/null; then
    print_status "Discord is installed and available"
else
    print_warning "Discord command not found, but package should be installed"
fi

echo "Obsidian:"
if command -v obsidian &> /dev/null; then
    print_status "Obsidian is installed and available"
else
    print_warning "Obsidian command not found, but package should be installed"
fi

print_status "Installation script completed!"
echo
print_status "Note: You may need to restart your terminal or run 'source ~/.cargo/env' to use cargo tools"
print_status "You can launch Obsidian from your applications menu or by running 'obsidian' in terminal"
print_status "You can launch Discord from your applications menu or by running 'discord' in terminal"
