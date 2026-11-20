# shellcheck shell=bash
#
# Shared fixtures: every test runs in its own disposable home directory, with
# its own mise state, and never touches the real user's files, services, or
# network repositories. Origins are local bare Git repositories.

REPO_ROOT=$(cd "$BATS_TEST_DIRNAME/.." && pwd -P)
export REPO_ROOT

# mise under test: MISE_TEST_BIN, else the one on PATH
_mise_bin() {
  if [ -n "${MISE_TEST_BIN:-}" ]; then
    printf '%s\n' "$MISE_TEST_BIN"
  else
    command -v mise
  fi
}

# the shell the scripts run under; macOS's own bash 3.2 by default there
TEST_BASH=${TEST_BASH:-/bin/bash}

# make <dir> a fresh, isolated home for one simulated machine
make_home() {
  local home=$1
  mkdir -p "$home/.local/bin" "$home/.config"
  ln -sf "$(_mise_bin)" "$home/.local/bin/mise"
}

# use <dir> as the current machine's home
use_home() {
  export HOME=$1
  unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
  unset MISE_CONFIG_DIR MISE_DATA_DIR MISE_STATE_DIR MISE_CACHE_DIR MISE_GLOBAL_CONFIG_FILE MISE_ENV
  export MISE_BIN=$HOME/.local/bin/mise
  export PATH="$HOME/.local/bin:$ORIGINAL_PATH"
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.invalid
  export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.invalid
  # fast watcher timing for tests; real machines use mise/global.toml values
  export MISE_HISTORY_WATCH_DEBOUNCE=1s MISE_HISTORY_SYNC_INTERVAL=1s MISE_HISTORY_FETCH_INTERVAL=1s
  export MISE_HISTORY_NOTIFY=false
  cd "$HOME" || return 1
}

common_setup() {
  : "${ORIGINAL_PATH:=$PATH}"
  export ORIGINAL_PATH
  export DOTFILES_SKIP_SERVICES=1
  # offline: no plugin clones; the bootstrap task skips network and host steps
  export DOTFILES_BOOTSTRAP_SKIP=repos
  export DOTFILES_OFFLINE=1
  # never read or write the real user's app preference domains
  export DOTFILES_TEST_DOMAINS_ONLY=1
  export NO_COLOR=1
  WORLD=$BATS_TEST_TMPDIR/world
  mkdir -p "$WORLD"
}

# a checkout of this repository at <home>/.dotfiles, as install.sh makes it
install_checkout() {
  local home=$1 f
  mkdir -p "$home/.dotfiles"
  (cd "$REPO_ROOT" && find . \( -name .git -o -name .jj -o -name .state -o -name .DS_Store \) -prune -o -type f -print) | while IFS= read -r f; do
    f=${f#./}
    mkdir -p "$home/.dotfiles/$(dirname "$f")"
    cp -p "$REPO_ROOT/$f" "$home/.dotfiles/$f"
  done
  git -c init.defaultBranch=master -C "$home/.dotfiles" init -q
  # offline stand-in for a file that comes from a cloned plugin repository
  mkdir -p "$home/.oh-my-zsh/custom/themes/bullet-train"
  : >"$home/.oh-my-zsh/custom/themes/bullet-train/bullet-train.zsh-theme"
}

# a machine with the public blueprint applied (no packages, services, network)
provision() {
  local home=$1
  make_home "$home"
  install_checkout "$home"
  use_home "$home"
  dotfiles install --skip-packages --yes
}

# an empty bare repository acting as a private .configs origin
make_origin() {
  git -c init.defaultBranch=main init -q --bare "$1"
}

dotfiles() { "$TEST_BASH" "$HOME/.dotfiles/bin/dotfiles" "$@"; }

# one service cycle: mise's history-watch saves (sync mode is manual), then the
# dotfiles-watch service exchanges through its publish and incoming gates
watch_once() {
  mise dot watch --once >/dev/null 2>&1 || true
  dotfiles config sync
}

assert_file_content() {
  local file=$1 want=$2 got
  got=$(cat "$file")
  if [ "$got" != "$want" ]; then
    printf 'expected %s to contain:\n%s\nbut found:\n%s\n' "$file" "$want" "$got" >&2
    return 1
  fi
}

# the list of files on an origin's branch
origin_files() {
  git --git-dir="$1" ls-tree -r --name-only "${2:-main}"
}

# build credential-looking strings at runtime so none is committed verbatim
fake_aws_key() { printf 'AKIA%s' "ABCDEFGHIJKLMNOP"; }
fake_github_token() { printf 'ghp_%s' "abcdefghijklmnopqrstuvwxyz0123456789"; }
