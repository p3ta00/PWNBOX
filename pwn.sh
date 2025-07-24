#!/bin/bash

# Parrot OS Development Environment Setup Script
# This script installs and configures kitty, neovim, tmux, starship and applies dotfiles
# Usage: ./setup_parrot.sh [password]

set -e

# Get password from command line argument
if [ -z "$1" ]; then
    echo "Usage: $0 <password>"
    echo "Example: $0 vSmCIlKn"
    exit 1
fi

PASSWORD="$1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_status "Starting Parrot OS Development Environment Setup..."

# Update system
print_status "Updating system packages..."
echo "$PASSWORD" | sudo -S DEBIAN_FRONTEND=noninteractive apt update && echo "$PASSWORD" | sudo -S DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade -y

# Install required packages
print_status "Installing required packages..."
echo "$PASSWORD" | sudo -S DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" install -y \
    kitty \
    tmux \
    git \
    curl \
    wget \
    unzip \
    fontconfig \
    zsh \
    build-essential \
    fzf

# Remove existing neovim and install latest version from GitHub
print_status "Removing existing neovim installation..."
echo "$PASSWORD" | sudo -S apt remove -y neovim nvim 2>/dev/null || true
echo "$PASSWORD" | sudo -S rm -rf /opt/nvim 2>/dev/null || true

print_status "Installing latest neovim from GitHub releases..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download latest neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz

# Extract to /opt
echo "$PASSWORD" | sudo -S tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# Create symlink for global access
echo "$PASSWORD" | sudo -S ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
echo "$PASSWORD" | sudo -S ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/neovim

# Clean up
cd "$HOME"
rm -rf "$TEMP_DIR"

print_success "Latest neovim installed successfully"

# Install Oh My Zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_status "Installing Oh My Zsh..."
    export RUNZSH=no
    export CHSH=no
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    print_success "Oh My Zsh already installed"
fi

# Install Starship prompt
print_status "Installing Starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Install CaskaydiaCove Nerd Font
print_status "Installing CaskaydiaCove Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Download and install the font
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

print_status "Downloading CaskaydiaCove Nerd Font..."
wget -q "$FONT_URL" -O CascadiaCode.zip

print_status "Extracting font files..."
unzip -q CascadiaCode.zip

# Copy font files
cp *.ttf "$FONT_DIR/" 2>/dev/null || true
cp *.otf "$FONT_DIR/" 2>/dev/null || true

# Update font cache
fc-cache -fv

print_success "CaskaydiaCove Nerd Font installed"

# Clean up
cd "$HOME"
rm -rf "$TEMP_DIR"

# Install zsh plugins
print_status "Installing zsh plugins..."

# zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    print_success "zsh-syntax-highlighting installed"
else
    print_success "zsh-syntax-highlighting already installed"
fi

# zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    print_success "zsh-autosuggestions installed"
else
    print_success "zsh-autosuggestions already installed"
fi

# Install TMux Plugin Manager
print_status "Installing TMux Plugin Manager..."
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    print_success "TMux Plugin Manager installed"
else
    print_success "TMux Plugin Manager already installed"
fi

# Install NvChad
print_status "Installing NvChad..."
if [ -d "$HOME/.config/nvim" ]; then
    print_warning "Backing up existing nvim config..."
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Clone NvChad starter and fix compatibility issues
git clone https://github.com/NvChad/starter ~/.config/nvim

# Fix the lua compatibility issue
print_status "Fixing NvChad lua compatibility..."
if [ -f "$HOME/.config/nvim/init.lua" ]; then
    # Create a backup of the original init.lua
    cp "$HOME/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua.backup"
    
    # Fix the vim.loop.uv issue by replacing it with vim.uv
    sed -i 's/vim\.loop\.uv/vim.uv/g' "$HOME/.config/nvim/init.lua"
    sed -i 's/vim\.loop/vim.uv/g' "$HOME/.config/nvim/init.lua"
    
    print_success "Fixed NvChad lua compatibility issues"
fi

print_success "NvChad installed and configured"

# Clone dotfiles
print_status "Cloning dotfiles from https://github.com/p3ta00/PWNBOX.git..."
DOTFILES_DIR="$HOME/PWNBOX"
if [ -d "$DOTFILES_DIR" ]; then
    print_warning "PWNBOX directory already exists, backing it up..."
    mv "$DOTFILES_DIR" "${DOTFILES_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
fi

git clone https://github.com/p3ta00/PWNBOX.git "$DOTFILES_DIR"
print_success "Dotfiles cloned successfully"

# Apply dotfiles configurations
print_status "Applying dotfiles configurations..."

# Create necessary directories
mkdir -p "$HOME/.config/kitty"
mkdir -p "$HOME/.config"

# Copy configuration files from different possible locations
if [ -f "$DOTFILES_DIR/config/kitty/kitty.conf" ]; then
    cp "$DOTFILES_DIR/config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    print_success "Kitty configuration applied from config/kitty/kitty.conf"
elif [ -f "$DOTFILES_DIR/config/kitty.conf" ]; then
    cp "$DOTFILES_DIR/config/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    print_success "Kitty configuration applied from config/kitty.conf"
elif [ -f "$DOTFILES_DIR/kitty/kitty.conf" ]; then
    cp "$DOTFILES_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    print_success "Kitty configuration applied from kitty/kitty.conf"
elif [ -f "$DOTFILES_DIR/kitty.conf" ]; then
    cp "$DOTFILES_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    print_success "Kitty configuration applied from root kitty.conf"
else
    print_warning "No kitty.conf found in dotfiles"
fi

# Copy all files from config/kitty/ directory if it exists
if [ -d "$DOTFILES_DIR/config/kitty" ]; then
    cp -r "$DOTFILES_DIR/config/kitty/"* "$HOME/.config/kitty/"
    print_success "All kitty configuration files copied from config/kitty/"
fi

if [ -f "$DOTFILES_DIR/config/starship.toml" ]; then
    cp "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
    print_success "Starship configuration applied from config/starship.toml"
elif [ -f "$DOTFILES_DIR/starship.toml" ]; then
    mkdir -p "$HOME/.config"
    cp "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
    print_success "Starship configuration applied"
elif [ -f "$DOTFILES_DIR/.config/starship.toml" ]; then
    cp "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
    print_success "Starship configuration applied from .config/"
else
    print_warning "No starship.toml found in dotfiles"
    print_status "Creating basic starship configuration..."
    cat > "$HOME/.config/starship.toml" << 'EOF'
# Basic Starship Configuration
format = """
[╭─user@hostname](bold blue) $all[╰─➤](bold blue) """

[username]
format = "[$user]($style)"
style_user = "bold blue"
style_root = "bold red"
show_always = true

[hostname]
ssh_only = false
format = "[$hostname]($style)"
style = "bold blue"

[directory]
format = "[$path]($style)[$read_only]($read_only_style) "
style = "bold cyan"

[git_branch]
format = "[$symbol$branch]($style) "
style = "bold green"

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold red"
EOF
    print_success "Basic starship configuration created"
fi

# Set zsh as default shell if not already
if [ "$SHELL" != "$(which zsh)" ]; then
    print_status "Setting zsh as default shell..."
    echo "$(which zsh)" | echo "$PASSWORD" | sudo -S tee -a /etc/shells >/dev/null 2>&1
    echo "$PASSWORD" | sudo -S chsh -s $(which zsh) $USER
    print_success "Zsh set as default shell"
fi

# Add auto-switch to zsh in .bashrc for immediate effect
print_status "Adding auto-switch to zsh in .bashrc..."
if ! grep -q "Auto-switch to Zsh" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# Auto-switch to Zsh if running interactively and not already in Zsh
if [ -t 1 ] && [ "$SHELL" != "/usr/bin/zsh" ] && [ -z "$ZSH_VERSION" ]; then
  exec /usr/bin/zsh
fi
EOF
    print_success "Auto-switch to zsh added to .bashrc"
else
    print_success "Auto-switch to zsh already present in .bashrc"
fi

# Overwrite the system-wide zsh configuration with user's .zshrc
print_status "Overwriting system-wide zsh configuration..."
if [ -f "$DOTFILES_DIR/.zshrc" ] || [ -f "$DOTFILES_DIR/zshrc" ]; then
    ZSHRC_SOURCE=""
    if [ -f "$DOTFILES_DIR/.zshrc" ]; then
        ZSHRC_SOURCE="$DOTFILES_DIR/.zshrc"
    elif [ -f "$DOTFILES_DIR/zshrc" ]; then
        ZSHRC_SOURCE="$DOTFILES_DIR/zshrc"
    fi
    
    if [ -n "$ZSHRC_SOURCE" ]; then
        echo "$PASSWORD" | sudo -S cp "$ZSHRC_SOURCE" /etc/zsh/zshrc
        print_success "System-wide zsh configuration overwritten with user's .zshrc"
    fi
else
    print_warning "No user .zshrc found to copy to system-wide configuration"
fi

# Final instructions
print_success "Installation completed successfully!"
echo
print_status "Next steps:"
echo "1. Close and reopen your terminal or run: source ~/.zshrc"
echo "2. Launch tmux and press prefix + I (usually Ctrl+b + I) to install tmux plugins"
echo "3. Launch nvim to complete NvChad setup"
echo "4. The CaskaydiaCove Nerd Font is installed - configure your terminal to use it"
echo "5. Restart your terminal application to ensure all changes take effect"
echo
print_warning "Note: You may need to log out and log back in for all changes to take effect"
print_success "Enjoy your new development environment!"
