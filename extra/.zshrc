[[ $- != *i* ]] && return

# colors
autoload -U colors && colors

# prompt
setopt PROMPT_SUBST
PS1='%F{red}$(if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then echo "$(parse_git_branch) "; fi)%F{blue}%~ %F{blue}$ %f'

# essential stuff
stty -ixon # disable ctrl+s and ctrl+q
HISTFILE=~/.zsh_history
HISTSIZE=1000000000
SAVEHIST=1000000000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS

# essentials
alias grep='grep --color=auto'
alias ff='clear && fastfetch'
alias c='clear'
alias rm='rm -rf'
alias vim='nvim'
alias debloat='~/Documents/debloat.sh'
alias chmod='chmod +x'
alias mpv='mpv --keep-open'
alias record='mkdir -p ~/recordings && ffmpeg -f x11grab -r 60 -s 2560x1440 -i :0.0 -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p -vf "scale=2560:1440" -threads 0 ~/recordings/$(date +"%Y-%m-%d-%H-%M-%S").mp4'
alias history='history 1'
alias ls='ls -hN --group-directories-first --color=auto'
alias fmt='cargo fmt --all'
alias check='cargo fmt --all --check'
alias ..='cd ..'

# git based actions
alias checkout='git checkout'
alias push='git push'
alias fetch='git fetch'
alias merge='git merge'
alias add='git add .'
alias stash='git stash && git stash drop'
alias status='git status'
alias log='git log'

# env's
export EDITOR='nvim'
export VISUAL='nvim'
export TERMINAL='kitty'
export BROWSER='firefox'

# parse the branch and transfer it to the prompt
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

# stashes changes before pulling and then releases the changes
pull() {
    git stash
    git pull
    git stash pop
}

# commit with a message dynamically
commit() {
    git add .
    git commit -m "$*"
    git push
}

# cloning and cding into that cloned repo
clone() { 
    git clone "$1" 2>/dev/null && cd "$(basename "$1" .git)"
}

# dynamically delete branches while on the branch you want to delete
branch() {
    if [ "$1" = "-d" ] && [ -n "$2" ]; then
        git checkout main 2>/dev/null || git checkout master 2>/dev/null
        git branch -d "$2"
    else
        git branch "$@"
    fi
}

# rebasing
rebase() {
    if [ "$1" = "--abort" ]; then
        git rebase --abort
        return
    fi
    if [[ "$1" =~ ^[0-9]+$ ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git rebase -i HEAD~"$1"
    fi
}

eval "$(zoxide init zsh --cmd cd)"

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor)
typeset -gA ZSH_HIGHLIGHT_STYLES

ZSH_HIGHLIGHT_STYLES[comment]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[function]='fg=green'
ZSH_HIGHLIGHT_STYLES[command]='fg=green'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=green,italic'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=yellow,italic'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=green'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=green'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=red'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-unquoted]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=red'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=red'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=red'
ZSH_HIGHLIGHT_STYLES[command-substitution-quoted]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-quoted]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]='fg=red'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]='fg=red'
ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]='fg=red'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[assign]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red'
ZSH_HIGHLIGHT_STYLES[path]='fg=20283C,underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=red,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=20283C,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=red,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=magenta'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]='fg=red'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[default]='fg=20283C'
ZSH_HIGHLIGHT_STYLES[cursor]='fg=20283C'

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
