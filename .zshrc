# //
# GENERAL OPTIONS
# //

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

# preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='nano'
else
   export EDITOR='micro'
fi

# //
# TMUX
# //

# Do not use autostart, explicitly start/attach session
# https://github.com/syl20bnr/spacemacs/issues/988
ZSH_TMUX_AUTOSTART=false
[[ $TMUX == "" ]] && tmux new-session

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

# direnv
eval "$(direnv hook zsh)"

# path to oh-my-zsh installation
export ZSH=~/.oh-my-zsh

# MacOS intergration
# > usage:
#   - pfd:	return the path of the frontmost Finder window
#   - pfs:	return the current Finder selection
#   - cdf:	cd to the current Finder directory
#   - quick-look: quick-Look a specified file
plugins=(osx)

# desktop notifications for long-running commands
plugins+=(notify)

# bind ctrl-r for history searching
plugins+=(history-search-multi-word)
zstyle ":history-search-multi-word" highlight-color "fg=yellow,bold"

# enable notification
plugins+=(notify)
zstyle ':notify:*' error-title "🔥  Error!!!"
zstyle ':notify:*' success-title "🎉  Success!!!"
zstyle ':notify:*' activate-terminal yes

# enable nvm
plugins+=(nvm)

# source oh my zsh
source $ZSH/oh-my-zsh.sh

# autosuggest the rest of a command
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# cd command with an interactive filter
source $ZSH_CUSTOM/plugins/enhancd/init.sh

# highlight commands whilst they are typed
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# //
# GO
# //

export GOPATH=$HOME/go
export GOROOT=/usr/local/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

# //
# SSH
# //

export SSH_KEY_PATH="~/.ssh/id_rsa"

# //
# GCP
# //

export CLOUDSDK_PYTHON="/usr/local/opt/python@3.8/libexec/bin/python"
source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

# //
# ALIAS
# //

# assume aws role with `assume <profile>`
alias assume=". awsume"

# count the number of files under the current folder
alias filecount="du -a | cut -d/ -f2 | sort | uniq -c | sort -nr"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/usr/local/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/usr/local/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

