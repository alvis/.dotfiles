#!/bin/bash
#
# One-command workstation setup from alvis/.dotfiles.
#
#   curl -fsSL https://raw.githubusercontent.com/alvis/.dotfiles/master/install.sh \
#     | bash -s -- --config <github-user>/.configs
#
# First machine (publishes your settings as a new private history):
#
#   ... | bash -s -- --init --config <github-user>/.configs
#
# Options (all optional):
#   --config OWNER/REPO   your private .configs repository
#   --init                allow creating/publishing a new .configs history
#   --apps a,b            with --init: which registry apps to enroll
#   --config-ref BRANCH   use a branch of the .configs repository
#   --take-remote         on adoption, replace differing local files with .configs (undoable)
#   --skip-packages       do not install packages or tools
#   --dotfiles-dir DIR    checkout location (default ~/.dotfiles)
#   --ref REF             .dotfiles branch, tag, or commit to check out (default master)
#   --dry-run             print what would change
#   --yes                 answer yes to confirmations (never to destructive choices
#                         that have their own flag, such as --take-remote)
#
# The script never runs as root and installs no sudo rules. Homebrew's own
# installer and mise ask for your password only when they create a system
# directory.

set -euo pipefail

DOTFILES_REPO=${DOTFILES_REPO:-https://github.com/alvis/.dotfiles.git}
DOTFILES_DIR=${DOTFILES_DIR:-$HOME/.dotfiles}
DOTFILES_REF=${DOTFILES_REF:-}
MISE_VERSION=2026.11.11
MISE_BIN=${MISE_BIN:-$HOME/.local/bin/mise}

# SHA-256 of the official release archives for MISE_VERSION
mise_sha256() {
  case $1 in
  macos-arm64) echo 3a0b7a727d86bd15a64c6df9ef6531111a4741b07e6f1e2bb6f6bb5b09e2663f ;;
  macos-x64) echo 7784da9fd85c77a0f0df6e6e39a6908089afc2a3f2c7ade78d362147fc4ef222 ;;
  linux-x64) echo 8366f07309794f93cfdd7343e3de3d5294c185165a0ec418426508cf0733e3d7 ;;
  linux-arm64) echo 638faf3b6eb49228557876ebf3826b08011f8359599df377406b3d648a5a1d9b ;;
  *) return 1 ;;
  esac
}

say() { printf '\033[32m==>\033[0m %s\n' "$*" >&2; }
fail() {
  printf '\033[31mERROR:\033[0m %s\n' "$*" >&2
  exit 1
}

usage() { sed -n '3,30p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//' || true; }

version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)" = "$2" ]; }

# Everything runs inside main, so a truncated `curl | bash` download runs
# nothing at all.
main() {

# //
# ARGUMENTS
# //

PASS=()
DRY_RUN=0
SKIP_PACKAGES=0
while [ $# -gt 0 ]; do
  case $1 in
  --dotfiles-dir)
    DOTFILES_DIR=${2:?--dotfiles-dir needs a path}
    shift
    ;;
  --ref)
    DOTFILES_REF=${2:?--ref needs a branch, tag, or commit}
    shift
    ;;
  --config | --apps | --config-ref)
    [ $# -ge 2 ] || fail "$1 needs a value"
    PASS+=("$1" "$2")
    shift
    ;;
  --dry-run)
    DRY_RUN=1
    PASS+=("$1")
    ;;
  --skip-packages)
    SKIP_PACKAGES=1
    PASS+=("$1")
    ;;
  --init | --take-remote | --yes | -y) PASS+=("$1") ;;
  -h | --help)
    usage
    exit 0
    ;;
  *) fail "unknown option: $1 (see --help)" ;;
  esac
  shift
done

[ "$(id -u)" != 0 ] || fail "do not run this installer as root; it asks for sudo itself when needed"
case $DOTFILES_DIR in
/*) ;;
*) fail "--dotfiles-dir must be an absolute path" ;;
esac
if [ -n "$DOTFILES_REF" ] && ! printf '%s\n' "$DOTFILES_REF" | grep -Eq '^[A-Za-z0-9._/-]{1,100}$'; then
  fail "invalid --ref: $DOTFILES_REF"
fi

# //
# PLATFORM AND PREREQUISITES
# //

case "$(uname -s)" in
Darwin) OS=macos ;;
Linux) OS=linux ;;
*) fail "unsupported operating system: $(uname -s)" ;;
esac
case "$(uname -m)" in
arm64 | aarch64) ARCH=arm64 ;;
x86_64 | amd64) ARCH=x64 ;;
*) fail "unsupported CPU architecture: $(uname -m)" ;;
esac
say "platform: $OS $ARCH"

if [ "$OS" = macos ]; then
  major=$(sw_vers -productVersion | cut -d. -f1)
  [ "$major" -ge 14 ] || printf 'WARN: macOS %s is older than the supported macOS 14 (Sonoma)\n' "$(sw_vers -productVersion)" >&2
  if ! xcode-select -p >/dev/null 2>&1; then
    say "installing the Xcode Command Line Tools (git, python3); a system dialog opens"
    [ $DRY_RUN = 1 ] || xcode-select --install || true
    fail "finish the Command Line Tools installation, then run this command again"
  fi
fi
# mise's Homebrew installer rewrites each program's ELF headers into a layout
# that only Linux 5.18 and later load correctly (the kernel fixed its AT_PHDR
# calculation then); x86_64 emulators still use the old calculation
if [ "$OS" = linux ] && [ "$SKIP_PACKAGES" = 0 ]; then
  kernel=$(uname -r | sed 's/[^0-9.].*//')
  version_ge "$kernel" 5.18 ||
    fail "Linux $kernel is older than 5.18, which cannot start the Homebrew packages mise installs; use a current release such as Ubuntu 26.04, or re-run with --skip-packages"
  if [ "$ARCH" = x64 ] && grep -qs -e VirtualApple -e 'CPU implementer' /proc/cpuinfo; then
    fail "this x86_64 Linux is emulated on an ARM machine (Rosetta or QEMU), which cannot start the Homebrew packages mise installs; use an arm64 image, which runs natively, or re-run with --skip-packages"
  fi
fi

for tool in git curl tar; do
  command -v "$tool" >/dev/null 2>&1 || fail "$tool is required (Linux: install it with your package manager)"
done
command -v python3 >/dev/null 2>&1 || fail "python3 is required (macOS: xcode-select --install; Linux: apt install python3)"
if command -v shasum >/dev/null 2>&1; then
  SHA256="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
  SHA256=sha256sum
else
  fail "shasum or sha256sum is required"
fi

# Homebrew on macOS: casks and Intel formulae need the real Homebrew
if [ "$OS" = macos ]; then
  prefix=/opt/homebrew
  [ "$ARCH" = arm64 ] || prefix=/usr/local
  if ! [ -x "$prefix/bin/brew" ]; then
    say "installing Homebrew (its installer asks for your password)"
    if [ $DRY_RUN = 0 ]; then
      brew_installer=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
      # Ask for the password once, on the terminal (stdin is the download
      # pipe under `curl | bash`). Homebrew then runs non-interactively: its
      # sudo -n reuses that, and it skips its "Press RETURN" pause.
      if (exec </dev/tty) 2>/dev/null; then
        # shellcheck disable=SC2024 # the redirect is meant for sudo's prompt
        /usr/bin/sudo -v </dev/tty || fail "Homebrew needs an administrator password to create $prefix"
      fi
      NONINTERACTIVE=1 /bin/bash -c "$brew_installer" </dev/null
    fi
  fi
  [ $DRY_RUN = 1 ] || [ -x "$prefix/bin/brew" ] || fail "Homebrew was not installed at $prefix"
  export PATH="$prefix/bin:$PATH"
fi

# //
# MISE (pinned and checksum-verified)
# //

have=''
[ -x "$MISE_BIN" ] && have=$("$MISE_BIN" --version 2>/dev/null | awk '{print $1}')
if [ -z "$have" ] || ! version_ge "$have" "$MISE_VERSION"; then
  say "installing mise $MISE_VERSION to $MISE_BIN"
  if [ $DRY_RUN = 0 ]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    archive="mise-v$MISE_VERSION-$OS-$ARCH.tar.gz"
    curl -fsSL -o "$tmp/$archive" "https://github.com/jdx/mise/releases/download/v$MISE_VERSION/$archive"
    want=$(mise_sha256 "$OS-$ARCH") || fail "no pinned checksum for $OS-$ARCH"
    got=$($SHA256 "$tmp/$archive" | awk '{print $1}')
    [ "$got" = "$want" ] || fail "checksum mismatch for $archive (expected $want, got $got)"
    tar -xzf "$tmp/$archive" -C "$tmp"
    mkdir -p "$(dirname "$MISE_BIN")"
    install -m 0755 "$tmp/mise/bin/mise" "$MISE_BIN"
    rm -rf "$tmp" # the EXIT trap does not survive the exec below
  else
    printf '    [dry-run] download, verify, and install mise %s\n' "$MISE_VERSION" >&2
    say "dry run stops here: the remaining steps need mise, which is not installed yet"
    exit 0
  fi
else
  say "mise $have already installed"
fi
MISE_BIN_DIR=$(dirname "$MISE_BIN")
export PATH="$MISE_BIN_DIR:$PATH"

# //
# THE PUBLIC CHECKOUT
# //

if [ -d "$DOTFILES_DIR/.git" ] || [ -f "$DOTFILES_DIR/.git" ]; then
  say "using the existing checkout at $DOTFILES_DIR"
  [ -z "$DOTFILES_REF" ] ||
    printf 'WARN: --ref applies to a new clone only; %s is left at its current commit (git -C %s checkout %s)\n' "$DOTFILES_DIR" "$DOTFILES_DIR" "$DOTFILES_REF" >&2
  if ! [ -f "$DOTFILES_DIR/mise.toml" ] || ! [ -x "$DOTFILES_DIR/bin/dotfiles" ]; then
    fail "$DOTFILES_DIR is not a mise-based .dotfiles checkout; update it (git -C $DOTFILES_DIR pull) or move it aside"
  fi
elif [ -e "$DOTFILES_DIR" ]; then
  fail "$DOTFILES_DIR exists but is not a Git checkout; move it aside first"
else
  say "cloning $DOTFILES_REPO to $DOTFILES_DIR"
  if [ $DRY_RUN = 1 ]; then
    printf '    [dry-run] git clone %s %s\n' "$DOTFILES_REPO" "$DOTFILES_DIR" >&2
    say "dry run stops here: the remaining steps read the checkout, which does not exist yet"
    exit 0
  fi
  git clone --quiet "$DOTFILES_REPO" "$DOTFILES_DIR"
  if [ -n "$DOTFILES_REF" ]; then
    git -C "$DOTFILES_DIR" checkout --quiet "$DOTFILES_REF"
  fi
  [ -x "$DOTFILES_DIR/bin/dotfiles" ] ||
    fail "the clone at $DOTFILES_DIR has no bin/dotfiles (no default branch checked out?); try --ref master"
fi

# under `curl | bash` stdin is the download pipe: mise reads its questions'
# answers from stdin, would see end-of-file, and silently skip every step.
# Hand the rest of the setup the terminal instead.
if ! [ -t 0 ] && (exec </dev/tty) 2>/dev/null; then
  exec </dev/tty
fi
exec "$DOTFILES_DIR/bin/dotfiles" install ${PASS[@]+"${PASS[@]}"}
}

main "$@"
