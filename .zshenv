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
    echo "FATAL: THIS SETUP DOES NOT SUPPORT $(uname)"
    ;;
esac

eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"

# //
# DEVELOPMENT
# //

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
# TOOLS
# //

export PATH=$PATH:$(brew --prefix)/opt/coreutils/libexec/gnubin

# //
# GO
# //

export GOPATH=$HOME/go
export GOROOT=$(brew --prefix)/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

# //
# PYTHON
# //
export PATH=$PATH:$HOME/.local/bin
