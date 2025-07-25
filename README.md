# Install
```
./pwn.sh {sudo password}
```
# Configure
```
./tools.sh
```
Update the github list (tools.txt) to add more tooling

```
./software.sh
```
This will install software such as cargo and rustscan. It will also put obsidian and discord on the pwnbox. Use at your descretion because it is a pwnbox. 

Git Sync

```
./git.sh
```
Edit the script
```
GIT_NAME="p3ta"
GIT_EMAIL="p3ta0.0@pm.me"
GITHUB_USERNAME="p3ta00"  # Your GitHub username
FOLDER_PATH="$HOME/hacking"
REPO_NAME="hacking"
```
Edit the script and and run it on both machines. It will create a ~/.local/bin/hacking-autosync.sh script that can be ran manually or every 30 min to look for changes. Ensure that your github is updated with the folder that you want to sync. This will allow you to work in both environments and maintain all of the files that you had previously.

<img width="3387" height="1315" alt="image" src="https://github.com/user-attachments/assets/8cc18177-2a40-4e6f-a977-a7b3a0c10c14" />
