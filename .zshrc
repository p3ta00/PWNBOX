# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export TERM=xterm-256color
#ZSH_THEME
eval "$(starship init zsh)"

# Add wisely, as too many plugins slow down shell startup.
plugins=( git zsh-syntax-highlighting zsh-autosuggestions )
source $ZSH/oh-my-zsh.sh
source <(fzf --zsh)

# Alias
#alias clear="printf '\033[2J\033[3J\033[H\033Ptmux;\033\033_Ga=d\033\033\\'"
alias zsource='source ~/.zshrc'
alias GitTools='~/tools/GitTools.sh'
alias burppro='burpsuitepro >/dev/null 2>&1 & disown'
alias blackarch='distrobox enter blackarch'
alias evil-winrm='evil-winrm 2> >(grep -v "warning:" >&2)'

tmux() {
    command tmux "$@"
    clear
}
export STARSHIP_CONFIG=~/.config/starship.toml

export PATH=$PATH:/bin
