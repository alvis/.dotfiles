source ~/.common.zshrc

# //
# iTerm2
# //
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    # add iterm2 integration
    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

    # autostart tmux
    # NOTE: do not use autostart, explicitly start/attach session
    # https://github.com/syl20bnr/spacemacs/issues/988
    ZSH_TMUX_AUTOSTART=false
    [[ $TMUX == "" ]] && tmux new-session -A

    # enable notification
    plugins+=(notify)
    zstyle ':notify:*' error-title "🔥  Error!!!"
    zstyle ':notify:*' success-title "🎉  Success!!!"
    zstyle ':notify:*' activate-terminal yes
fi

# //
# // PLUGINS
# //

# MacOS integration
# > usage:
#   - pfd:	return the path of the frontmost Finder window
#   - pfs:	return the current Finder selection
#   - cdf:	cd to the current Finder directory
#   - quick-look: quick-Look a specified file
plugins+=(macos)

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

