#!/bin/bash

# Simple GitHub Auto-Sync Setup Script for Arch Linux (No GitHub CLI)
# This script sets up automatic syncing using pure git

set -e  # Exit on any error

# Configuration - EDIT THESE VALUES
GIT_NAME="p3ta"
GIT_EMAIL="p3ta0.0@pm.me"
GITHUB_USERNAME="p3ta00"
REPO_NAME="hacking"
FOLDER_PATH="$HOME/hacking"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up GitHub auto-sync for ~/hacking on Arch Linux${NC}"

# Check if folder exists
if [ ! -d "$FOLDER_PATH" ]; then
    echo -e "${YELLOW}Creating $FOLDER_PATH directory...${NC}"
    mkdir -p "$FOLDER_PATH"
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${BLUE}Installing git...${NC}"
    sudo pacman -S --noconfirm git
fi

cd "$FOLDER_PATH"

# Configure git globally if not already configured
if [ -z "$(git config --global --get user.name)" ] || [ -z "$(git config --global --get user.email)" ]; then
    echo -e "${BLUE}Configuring git identity...${NC}"
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
else
    echo -e "${YELLOW}Git identity already configured${NC}"
fi

# Configure git to handle pulls automatically
git config --global pull.rebase false

# Check if this is already a git repository connected to the right remote
if [ -d ".git" ] && git remote get-url origin &> /dev/null; then
    CURRENT_REMOTE=$(git remote get-url origin)
    EXPECTED_REMOTE="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    
    if [ "$CURRENT_REMOTE" = "$EXPECTED_REMOTE" ]; then
        echo -e "${GREEN}Repository already set up and connected to GitHub!${NC}"
        echo -e "${BLUE}Pulling latest changes...${NC}"
        git pull origin main --no-edit 2>/dev/null || true
    else
        echo -e "${YELLOW}Repository exists but connected to different remote: $CURRENT_REMOTE${NC}"
        echo -e "${BLUE}Updating remote to: $EXPECTED_REMOTE${NC}"
        git remote set-url origin "$EXPECTED_REMOTE"
    fi
else
    # Initialize git repository if not already initialized
    if [ ! -d ".git" ]; then
        echo -e "${BLUE}Initializing git repository...${NC}"
        git init
        
        # Create initial .gitignore
        cat > .gitignore << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Temporary files
*.tmp
*.temp
*~

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Compiled files (add more as needed)
*.o
*.so
*.pyc
__pycache__/
EOF
        
        git add .gitignore
        git commit -m "Initial commit with .gitignore"
    else
        echo -e "${YELLOW}Git repository already exists${NC}"
    fi

    # Add remote origin if not already added
    REPO_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    if ! git remote get-url origin &> /dev/null; then
        echo -e "${BLUE}Adding remote origin...${NC}"
        git remote add origin "$REPO_URL"
    else
        echo -e "${YELLOW}Remote origin already exists${NC}"
    fi

    echo -e "${YELLOW}IMPORTANT: Make sure the repository $REPO_URL exists on GitHub!${NC}"
    echo -e "${YELLOW}If it doesn't exist, create it manually at: https://github.com/new${NC}"
    echo -e "${YELLOW}Repository name: $REPO_NAME (make it private)${NC}"
    echo ""
    read -p "Press Enter when ready to continue..."

    # Initial push with conflict resolution
    echo -e "${BLUE}Pushing to GitHub...${NC}"
    git add .
    if git diff --cached --quiet; then
        echo "No changes to commit, creating initial README..."
        echo "# Hacking Projects" > README.md
        echo "Auto-synced hacking folder - created $(date)" >> README.md
        git add README.md
    fi
    git commit -m "Auto-sync setup - $(date '+%Y-%m-%d %H:%M:%S')" || echo "Nothing new to commit"
    git branch -M main

    # Handle potential conflicts with remote repository
    if ! git push -u origin main 2>/dev/null; then
        echo -e "${YELLOW}Remote repository has conflicting content, resolving...${NC}"
        # Pull remote changes and allow unrelated histories
        git pull origin main --allow-unrelated-histories --no-edit --strategy-option=ours 2>/dev/null || {
            # If there are merge conflicts, resolve them automatically favoring local changes
            echo -e "${BLUE}Resolving merge conflicts automatically...${NC}"
            git status --porcelain | grep "^UU\|^AA\|^DD" | cut -c4- | while read file; do
                echo -e "${YELLOW}Auto-resolving conflict in: $file${NC}"
                git add "$file"
            done
            git commit -m "Auto-resolve merge conflicts - $(date '+%Y-%m-%d %H:%M:%S')" --no-edit || true
        }
        # Now push the merged changes
        git push -u origin main --force-with-lease
    fi

    # Pull any remaining remote files after initial setup
    echo -e "${BLUE}Syncing remote files to local folder...${NC}"
    git pull origin main --no-edit 2>/dev/null || true

    echo -e "${GREEN}Initial push complete! Repository available at: $REPO_URL${NC}"
fi

# Create auto-sync script
AUTO_SYNC_SCRIPT="$HOME/.local/bin/hacking-autosync.sh"
mkdir -p "$HOME/.local/bin"

cat > "$AUTO_SYNC_SCRIPT" << 'EOF'
#!/bin/bash

FOLDER_PATH="$HOME/hacking"
cd "$FOLDER_PATH"

# Configure git for automatic merging if not already set
git config pull.rebase false 2>/dev/null || true

# Pull any remote changes first
echo "$(date): Checking for remote changes..."
git pull origin main --no-edit 2>/dev/null || true

# Check if there are local changes to sync
if [[ -n $(git status --porcelain) ]]; then
    echo "$(date): Changes detected, syncing..."
    git add .
    git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main
    echo "$(date): Sync complete"
else
    echo "$(date): No changes to sync"
fi
EOF

chmod +x "$AUTO_SYNC_SCRIPT"

# Create systemd user service for auto-sync
SERVICE_DIR="$HOME/.config/systemd/user"
mkdir -p "$SERVICE_DIR"

cat > "$SERVICE_DIR/hacking-autosync.service" << EOF
[Unit]
Description=Auto-sync hacking folder to GitHub
After=network-online.target

[Service]
Type=oneshot
ExecStart=$AUTO_SYNC_SCRIPT
WorkingDirectory=$FOLDER_PATH

[Install]
WantedBy=default.target
EOF

# Create systemd timer
cat > "$SERVICE_DIR/hacking-autosync.timer" << EOF
[Unit]
Description=Auto-sync hacking folder every 30 minutes
Requires=hacking-autosync.service

[Timer]
OnCalendar=*:0/30
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
systemctl --user daemon-reload
systemctl --user enable hacking-autosync.timer
systemctl --user start hacking-autosync.timer

# Run first sync immediately
echo -e "${BLUE}Running initial sync...${NC}"
"$AUTO_SYNC_SCRIPT"

# Force pull all remote files to ensure everything is synced
echo -e "${BLUE}Ensuring all remote files are synced locally...${NC}"
cd "$FOLDER_PATH"
git fetch origin
git reset --hard origin/main
echo -e "${GREEN}All files synced from GitHub!${NC}"

echo -e "${GREEN}Setup complete!${NC}"
echo -e "${BLUE}Your ~/hacking folder is now set up for auto-sync with GitHub.${NC}"
echo ""
echo -e "${YELLOW}What was set up:${NC}"
echo "• Git repository initialized in ~/hacking"
echo "• Remote origin pointing to: $REPO_URL"
echo "• Auto-sync script created at ~/.local/bin/hacking-autosync.sh"
echo "• Systemd timer set to sync every 30 minutes"
echo "• Initial sync completed"
echo ""
echo -e "${YELLOW}Commands you can use:${NC}"
echo "• Check sync status: systemctl --user status hacking-autosync.timer"
echo "• Manual sync: ~/.local/bin/hacking-autosync.sh"
echo "• Stop auto-sync: systemctl --user stop hacking-autosync.timer"
echo "• Disable auto-sync: systemctl --user disable hacking-autosync.timer"
echo "• View sync logs: journalctl --user -u hacking-autosync.service -f"
echo ""
echo -e "${GREEN}Your folder is now automatically syncing to GitHub every 30 minutes!${NC}"
echo -e "${BLUE}Next sync in: $(systemctl --user list-timers | grep hacking | awk '{print $1, $2}' || echo 'Timer starting...')${NC}"
