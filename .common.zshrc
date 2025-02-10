
# //
# GENERAL OPTIONS
# //

# don't complain if no match is found on a glob expression
setopt +o nomatch

# remove duplicated command history
setopt hist_ignore_all_dups

# allow any comment starting with a space (` `) will not be remembered in history
setopt hist_ignore_space

# use case-sensitive completion
# CASE_SENSITIVE="true"

# display red dots whilst waiting for completion
COMPLETION_WAITING_DOTS="true"

# disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# disable auto-setting terminal title
# DISABLE_AUTO_TITLE="true"

# disable colors in ls.
# DISABLE_LS_COLORS="true"

# disable marking untracked files under VCS as dirty
# NOTE: This makes repository status check for large repositories much faster
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# enable command auto-correction.
# ENABLE_CORRECTION="true"

# change the command execution time stamp shown in the history command output
# NOTE: either "mm/dd/yyyy", "dd.mm.yyyy", or "yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# use hyphen-insensitive completion
# HYPHEN_INSENSITIVE="true"

# zsh custom folder
# ZSH_CUSTOM=$ZSH/custom

# //
# THEME
# //

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="bullet-train"
BULLETTRAIN_PROMPT_CHAR="%F{red}❯%F{yellow}❯%F{green}❯%f"
BULLETTRAIN_PROMPT_ORDER=(
   time
   status
   custom
   dir
   virtualenv
   git
   cmd_exec_time
   nvm
)

# //
# // PLUGINS
# //

# path to oh-my-zsh installation
export ZSH=~/.oh-my-zsh

# direnv
plugins=(direnv)

# bind ctrl-r for history searching
plugins+=(history-search-multi-word)
zstyle ":history-search-multi-word" highlight-color "fg=yellow,bold"

# enable nvm
plugins+=(zsh-nvm)

# enable aws
plugins+=(aws)

# source oh my zsh
zstyle ':omz:alpha:lib:git' async-prompt no # disable async prompt for git due to https://github.com/ohmyzsh/ohmyzsh/issues/12328
source $ZSH/oh-my-zsh.sh

# autosuggest the rest of a command
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# cd command with an interactive filter
source $ZSH_CUSTOM/plugins/enhancd/init.sh

# highlight commands whilst they are typed
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# //
# Auto Completion
# //

# set options for completion
setopt globdots           # complete hidden files
setopt AUTO_LIST          # automatically list choices
setopt COMPLETE_IN_WORD   # complete from both ends of a word
setopt GLOB_COMPLETE      # automatically list all possible completions with a glob pattern
setopt LIST_AMBIGUOUS     # automatically list completions on an ambiguous completion

# use menu selection for completion
zstyle ':completion:*' menu select

# define completers
zstyle ':completion:*' completer _extensions _complete _approximate

# use cache for commands using cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"

zle -C alias-expension complete-word _generic
bindkey '^Xa' alias-expension
zstyle ':completion:alias-expension:*' completer _expand_alias

# autocomplete options for cd instead of directory stack

zstyle ':completion:*' complete-options true # complete options even if command name is ambiguous
zstyle ':completion:*' file-sort modification

zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}-- %D %d --%f'
zstyle ':completion:*:*:*:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:*:*:*:warnings' format ' %F{red}-- no matches found --%f'

# colors for files and directory
zstyle ':completion:*:*:*:*:default' list-colors ${(s.:.)LS_COLORS} # make colors consistent with ls

# required for completion to be in good groups (named after the tags)
zstyle ':completion:*' group-name ''

zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands

# see ZSHCOMPWID "completion matching control"
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

zstyle ':completion:*' keep-prefix true

# configure SSH host completion from known_hosts files
if [[ -f ~/.ssh/known_hosts || -f /etc/ssh/ssh_known_hosts || -f /etc/ssh_known_hosts ]]; then # use zsh's [[ for tests and check common known_hosts paths
  zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'
fi

# load more completions
fpath+=~/.zfunc

# load zsh-completions
autoload -Uz compinit
compinit

# //
# ALIAS
# //

# inject copilot cli's ??, git? & gh? alias
eval "$(github-copilot-cli alias -- "$0")"

# assume aws role with `assume <profile>`
alias assume=". awsume"

# count the number of files under the current folder
alias filecount="du -a | cut -d/ -f2 | sort | uniq -c | sort -nr"

# edit a file via the default editor
alias edit="$EDITOR"

# download a file with wget
alias download="wget --debug --continue --tries=0 --read-timeout=30 --random-wait"
