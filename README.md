Store  these in your /my_data folder if your maintaining your own version. This will keep the files persistent. i believe there is an auto run script that I'm going to work on next, to provide 100% automation. 

# Install
```
./pwn.sh {sudo password}
```
Once complete use kitty as your terminal.

# Configure
```
./tools.sh
```
Update the github list (tools.txt) to add more tooling

```
./software.sh
```
This will install software such as cargo and rustscan. It will also put obsidian and discord on the pwnbox. Use at your descretion because it is a pwnbox. After installation close your terminal and reopen it. I will fix this later.

Git Sync

```
./git.sh
```
Edit the script
```
# Configuration - EDIT THESE VALUES
GIT_NAME="Enter"
GIT_EMAIL="enter@pm.me"
GITHUB_USERNAME="enter"  # Your GitHub username
FOLDER_PATH="$HOME/hacking"
REPO_NAME="hacking"
```
Edit the script and and run it on both machines. It will create a ~/.local/bin/hacking-autosync.sh script that can be ran manually or every 30 min to look for changes. Ensure that your github is updated with the folder that you want to sync. This will allow you to work in both environments and maintain all of the files that you had previously.

Back you your working directory on your main machine, this feature is still a in-progress. I have not lost data yet, but be safe.

<img width="3387" height="1315" alt="image" src="https://github.com/user-attachments/assets/8cc18177-2a40-4e6f-a977-a7b3a0c10c14" />
