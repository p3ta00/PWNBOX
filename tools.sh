#!/bin/bash

# Script to automatically git clone repositories from tools.txt into a tools folder

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

# Check if tools.txt exists
if [[ ! -f "tools.txt" ]]; then
    print_error "tools.txt file not found in current directory!"
    echo "Please create a tools.txt file with one repository URL per line."
    exit 1
fi

# Set the target directory for tools folder
TOOLS_DIR="$HOME/tools"

# Create tools directory if it doesn't exist in home directory
if [[ ! -d "$TOOLS_DIR" ]]; then
    print_status "Creating tools directory at $TOOLS_DIR..."
    mkdir -p "$TOOLS_DIR"
    print_success "Tools directory created at $TOOLS_DIR"
else
    print_status "Tools directory already exists at $TOOLS_DIR"
fi

# Read the tools.txt file and process each line
print_status "Reading repositories from tools.txt..."

line_count=0
success_count=0
error_count=0

while IFS= read -r repo_url; do
    # Skip empty lines and comments (lines starting with #)
    if [[ -z "$repo_url" ]] || [[ "$repo_url" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    line_count=$((line_count + 1))
    
    # Remove leading/trailing whitespace
    repo_url=$(echo "$repo_url" | xargs)
    
    print_status "Processing repository $line_count: $repo_url"
    
    # Extract repository name from URL for folder naming
    repo_name=$(basename "$repo_url" .git)
    
    # Check if directory already exists
    if [[ -d "$TOOLS_DIR/$repo_name" ]]; then
        print_warning "Directory $TOOLS_DIR/$repo_name already exists, skipping..."
        continue
    fi
    
    # Clone the repository into the tools directory
    if git clone "$repo_url" "$TOOLS_DIR/$repo_name"; then
        print_success "Successfully cloned $repo_name"
        success_count=$((success_count + 1))
    else
        print_error "Failed to clone $repo_url"
        error_count=$((error_count + 1))
    fi
    
    echo "" # Empty line for better readability
    
done < tools.txt

# Print summary
echo "=================================================="
print_status "Cloning completed!"
echo -e "Total repositories processed: ${BLUE}$line_count${NC}"
echo -e "Successfully cloned: ${GREEN}$success_count${NC}"
echo -e "Failed to clone: ${RED}$error_count${NC}"
echo "=================================================="

# Exit with appropriate code
if [[ $error_count -gt 0 ]]; then
    exit 1
else
    exit 0
fi
