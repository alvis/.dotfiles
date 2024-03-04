source ~/.zprofile

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

# compilation flags
export ARCHFLAGS="-arch x86_64"

# language environment
export LANG=en_US.UTF-8

# preferred editors
if command -v emacsclient >/dev/null; then
   # using the emacs deamon with a new frame on the current screen
   export EDITOR='emacsclient -c'
elif command -v micro >/dev/null; then
   export EDITOR='micro'
elif command -v nano >/dev/null; then
   export EDITOR='nano'
elif command -v code >/dev/null; then
   # using 'code --wait' makes VSCode act more like a traditional blocking text editor
   export EDITOR='code --wait'
fi

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
source $ZSH/oh-my-zsh.sh

# autosuggest the rest of a command
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# cd command with an interactive filter
source $ZSH_CUSTOM/plugins/enhancd/init.sh

# highlight commands whilst they are typed
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# setup auto completion
autoload -Uz compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc

# //
# GO
# //

export GOPATH=$HOME/go
export GOROOT=$(brew --prefix)/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

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
