#!/bin/bash

# Fully automated Burp Suite Pro installer for Parrot OS (with license auto-paste)
# Author: ChatGPT

set -e

REPO_URL="https://github.com/sdmrf/BurpSuite-Pro.git"
BURP_DIR="/usr/share/burpsuitepro"
BURP_CLONE_DIR="$HOME/BurpSuite-Pro"
BURP_SCRIPT="/usr/local/bin/burppro"
BURP_DESKTOP="/usr/share/applications/burppro.desktop"
BURP_ICON="$BURP_DIR/icon.png"
BURP_LICENSE_FILE="$BURP_DIR/license.txt"
BURP_RELEASES_URL="https://portswigger.net/burp/releases"
JDK_DIR="/opt/jdk-21"
JAVA_PATH="$JDK_DIR/bin/java"
JDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.3%2B9/OpenJDK21U-jdk_x64_linux_hotspot_21.0.3_9.tar.gz"

LICENSE_KEY="enter your key"

print_status() {
    echo -e "\e[1;34m[+] $1\e[0m"
}

error_status() {
    echo -e "\e[1;31m[!] $1\e[0m"
    exit 1
}

uninstall_existing_burp() {
    print_status "Uninstalling previous Burp Suite Pro and Community Edition..."
    sudo rm -rf "$BURP_DIR" "$BURP_SCRIPT" "$BURP_CLONE_DIR" "$BURP_DESKTOP"
    if dpkg -l | grep -q burpsuite; then
        sudo apt purge -y burpsuite || error_status "Failed to remove Burp Community"
        sudo apt autoremove -y
    fi
}

install_java21() {
    if [ -x "$JAVA_PATH" ]; then
        print_status "Java 21 already installed."
        return
    fi

    print_status "Installing Java 21 from Adoptium..."
    sudo rm -rf "$JDK_DIR"
    wget -q "$JDK_URL" -O /tmp/jdk21.tar.gz || error_status "Java 21 download failed"
    sudo tar -xzf /tmp/jdk21.tar.gz -C /opt
    sudo mv /opt/jdk-21.0.3+9 "$JDK_DIR"
    sudo update-alternatives --install /usr/bin/java java "$JAVA_PATH" 121
    sudo update-alternatives --set java "$JAVA_PATH"
    "$JAVA_PATH" -version
}

clone_repo() {
    print_status "Cloning optional helper repo..."
    git clone "$REPO_URL" "$BURP_CLONE_DIR" || error_status "Git clone failed"
}

download_burpsuite() {
    print_status "Downloading the latest Burp Suite Pro JAR..."
    sudo mkdir -p "$BURP_DIR"
    html=$(curl -s "$BURP_RELEASES_URL")
    version=$(echo "$html" | grep -Po '(?<=/burp/releases/professional-community-)[0-9]{4}\.[0-9]+\.[0-9]+' | head -n 1)
    download_link="https://portswigger-cdn.net/burp/releases/download?product=pro&type=Jar&version=$version"
    sudo wget "$download_link" -O "$BURP_DIR/burpsuite_pro.jar" -q --progress=bar:force || error_status "Burp download failed"
    print_status "Downloaded Burp Pro version: $version"

    print_status "Downloading icon..."
    wget -q https://portswigger.net/favicon.ico -O /tmp/burp.ico && \
    convert /tmp/burp.ico "$BURP_ICON" 2>/dev/null || echo "Icon conversion skipped (missing ImageMagick)"
}

write_license_file() {
    print_status "Writing license key to $BURP_LICENSE_FILE"
    sudo tee "$BURP_LICENSE_FILE" > /dev/null <<< "$LICENSE_KEY"
}

generate_script() {
    print_status "Creating launcher script..."
    sudo tee "$BURP_SCRIPT" > /dev/null << EOF
#!/bin/bash
exec $JAVA_PATH -jar $BURP_DIR/burpsuite_pro.jar &
EOF
    sudo chmod +x "$BURP_SCRIPT"
}

create_desktop_entry() {
    print_status "Creating .desktop entry..."
    sudo tee "$BURP_DESKTOP" > /dev/null << EOF
[Desktop Entry]
Name=Burp Suite Professional
Exec=$BURP_SCRIPT
Icon=$BURP_ICON
Type=Application
Terminal=false
Categories=Development;Security;
StartupNotify=true
EOF
    sudo chmod +x "$BURP_DESKTOP"
    sudo update-desktop-database
}

simulate_license_input() {
    if ! command -v xdotool &> /dev/null; then
        print_status "Installing xdotool for license paste automation..."
        sudo apt install -y xdotool
    fi

    print_status "Simulating license key paste (X11 only)..."
    sleep 5
    xdotool type "$LICENSE_KEY"
    xdotool key Return
}

launch_burp() {
    print_status "Launching Burp Suite Pro..."
    $BURP_SCRIPT &
    simulate_license_input
}

main() {
    uninstall_existing_burp
    install_java21
    clone_repo
    download_burpsuite
    write_license_file
    generate_script
    create_desktop_entry
    launch_burp
    print_status "✅ Burp Suite Pro installed and licensed!"
}

main "$@"
