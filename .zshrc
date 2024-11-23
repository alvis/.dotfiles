source ~/.common.zshrc

# //
# iTerm2
# //

# add iterm2 integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# //
# TMUX
# //

# Do not use autostart, explicitly start/attach session
# https://github.com/syl20bnr/spacemacs/issues/988
ZSH_TMUX_AUTOSTART=false
[[ $TMUX == "" ]] && tmux new-session -A

# //
# // PLUGINS
# //

# MacOS intergration
# > usage:
#   - pfd:	return the path of the frontmost Finder window
#   - pfs:	return the current Finder selection
#   - cdf:	cd to the current Finder directory
#   - quick-look: quick-Look a specified file
plugins+=(macos)

# enable notification
[[ $TERM_PROGRAM == "iTerm.app" ]] && plugins+=(notify)
zstyle ':notify:*' error-title "🔥  Error!!!"
zstyle ':notify:*' success-title "🎉  Success!!!"
zstyle ':notify:*' activate-terminal yes

# source oh my zsh again for the additional plugins
source $ZSH/oh-my-zsh.sh

# enable credential injection via 1password
source ~/.config/op/plugins.sh || true

# //
# DevOps
# //

command -v flux >/dev/null && . <(flux completion zsh)

# //
# GCP
# //

source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
