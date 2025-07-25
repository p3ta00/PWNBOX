# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export TERM=xterm-256color
#ZSH_THEME
eval "$(starship init zsh)"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
# Add wisely, as too many plugins slow down shell startup.
plugins=( git zsh-syntax-highlighting zsh-autosuggestions )
#source $ZSH/oh-my-zsh.sh

# Alias
#alias clear="printf '\033[2J\033[3J\033[H\033Ptmux;\033\033_Ga=d\033\033\\'"
alias zsource='source ~/.zshrc'

tmux() {
    command tmux "$@"
    clear
}
export STARSHIP_CONFIG=~/.config/starship.toml

export PATH=$PATH:/bin
