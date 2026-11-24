# bootstrap Homebrew environment variables
case "$(uname)" in
Darwin)
    # macOS:
    case "$(uname -m)" in
    arm64) export HOMEBREW_PREFIX="/opt/homebrew" ;;
    *) export HOMEBREW_PREFIX="/usr/local" ;;
    esac
    ;;
Linux)
    # linux
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    ;;
*)
    # unsupported OS
    echo "FATAL: THIS SETUP DOES NOT SUPPORT $(uname)" >&2
    ;;
esac

# load Homebrew only once it is installed
if [[ -x "$HOMEBREW_PREFIX/bin/brew" ]]; then
    eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
elif [[ -d "$HOMEBREW_PREFIX/bin" ]]; then
    # on Linux, mise installs Homebrew packages into the prefix without the
    # brew command itself, so put the prefix on the search paths directly
    export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
    export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
    export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
fi

# //
# DEVELOPMENT
# //

# compilation flags: build native extensions for this Mac's own architecture
[[ "$(uname)" == Darwin ]] && export ARCHFLAGS="-arch $(uname -m)"

# language environment: a UTF-8 locale this machine has (minimal Linux installs
# ship only C.UTF-8; a missing locale drops zsh to ASCII and breaks the prompt)
export LANG=en_US.UTF-8
if [[ "$(uname)" == Linux ]] && ! locale -a 2>/dev/null | grep -Eqix 'en_US\.utf-?8'; then
    export LANG=C.UTF-8
fi

# preferred editors
if command -v micro >/dev/null; then
    export EDITOR='micro'
elif command -v nano >/dev/null; then
    export EDITOR='nano'
elif command -v code >/dev/null; then
    # using 'code --wait' makes VSCode act more like a traditional blocking text editor
    export EDITOR='code --wait'
fi

# //
# TOOLS
# //

[[ -d "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin" ]] && export PATH=$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH

# //
# NODE
# //

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # loads nvm

# //
# BUN
# //

# Homebrew provides bun itself; `bun add -g` puts commands in $BUN_INSTALL/bin
export BUN_INSTALL=${BUN_INSTALL:-$HOME/.bun}
export PATH=$BUN_INSTALL/bin:$PATH

# //
# GO
# //

export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH
if [[ -d "$HOMEBREW_PREFIX/opt/go/libexec" ]]; then
    export GOROOT=$HOMEBREW_PREFIX/opt/go/libexec
    export PATH=$GOROOT/bin:$PATH
fi

# //
# PYTHON
# //
export PATH=$HOME/.local/bin:$PATH

# //
# RUST
# //
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
