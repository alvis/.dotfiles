# shellcheck shell=bash disable=SC2034
#
# Shared helpers for bin/dotfiles. Compatible with the bash 3.2 that ships with
# macOS: no associative arrays, no mapfile, no ${var,,}.

# //
# OUTPUT
# //

if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
  _c_red=$'\033[31m' _c_yel=$'\033[33m' _c_grn=$'\033[32m' _c_dim=$'\033[2m' _c_off=$'\033[0m'
else
  _c_red='' _c_yel='' _c_grn='' _c_dim='' _c_off=''
fi

log() { printf '%s==>%s %s\n' "$_c_grn" "$_c_off" "$*" >&2; }
info() { printf '    %s\n' "$*" >&2; }
warn() {
  printf '%sWARN:%s %s\n' "$_c_yel" "$_c_off" "$*" >&2
  # `dotfiles install` repeats these at the end, past the package output
  [ -z "${DOTFILES_WARN_LOG:-}" ] || printf '%s\n' "$*" >>"$DOTFILES_WARN_LOG" 2>/dev/null || true
}
err() { printf '%sERROR:%s %s\n' "$_c_red" "$_c_off" "$*" >&2; }
die() {
  err "$*"
  exit 1
}
dim() { printf '%s%s%s\n' "$_c_dim" "$*" "$_c_off" >&2; }

# run a command, or only print it when DRY_RUN=1
act() {
  if [ "${DRY_RUN:-0}" = 1 ]; then
    printf '    [dry-run] %s\n' "$*" >&2
    return 0
  fi
  "$@"
}

# ask a yes/no question; ASSUME_YES=1 answers yes, no terminal answers no
confirm() {
  local prompt=$1 reply
  if [ "${ASSUME_YES:-0}" = 1 ]; then
    return 0
  fi
  if ! [ -t 0 ] && ! { [ -r /dev/tty ] && [ -w /dev/tty ]; }; then
    warn "no terminal to confirm: $prompt (re-run with --yes to accept)"
    return 1
  fi
  printf '%s [y/N] ' "$prompt" >/dev/tty
  IFS= read -r reply </dev/tty || return 1
  case $reply in
  y | Y | yes | YES) return 0 ;;
  *) return 1 ;;
  esac
}

# //
# PLATFORM
# //

# prints `macos` or `linux`; fails for anything else
platform_os() {
  case "$(uname -s)" in
  Darwin) echo macos ;;
  Linux) echo linux ;;
  *) return 1 ;;
  esac
}

# prints `arm64` or `x64`; fails for anything else
platform_arch() {
  case "$(uname -m)" in
  arm64 | aarch64) echo arm64 ;;
  x86_64 | amd64) echo x64 ;;
  *) return 1 ;;
  esac
}

# Homebrew's standard prefix for this machine
brew_prefix() {
  case "$(platform_os)-$(platform_arch)" in
  macos-arm64) echo /opt/homebrew ;;
  macos-x64) echo /usr/local ;;
  *) echo /home/linuxbrew/.linuxbrew ;;
  esac
}

# //
# PATHS
# //

: "${DOTFILES_DIR:=$HOME/.dotfiles}"
: "${MISE_BIN:=$HOME/.local/bin/mise}"
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${DOTFILES_STATE_DIR:=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles}"
MISE_CONFIG_DIR_EFFECTIVE=${MISE_CONFIG_DIR:-$XDG_CONFIG_HOME/mise}
MISE_MANIFEST=$MISE_CONFIG_DIR_EFFECTIVE/config.toml
MISE_LOCAL_CONFIG=$MISE_CONFIG_DIR_EFFECTIVE/config.local.toml
SHARED_LAYER_LINK=$MISE_CONFIG_DIR_EFFECTIVE/conf.d/00-dotfiles.toml
PREFS_DIR=$XDG_CONFIG_HOME/dotfiles/prefs

mise_cmd() {
  if [ -x "$MISE_BIN" ]; then
    "$MISE_BIN" "$@"
  elif command -v mise >/dev/null 2>&1; then
    command mise "$@"
  else
    die "mise is not installed; run install.sh first"
  fi
}

# expand a leading ~/ to $HOME
expand_home() {
  case $1 in
  "~") printf '%s\n' "$HOME" ;;
  "~/"*) printf '%s/%s\n' "$HOME" "${1#\~/}" ;;
  *) printf '%s\n' "$1" ;;
  esac
}

# collapse $HOME back to ~ for display and for [dotfiles] keys
tilde_path() {
  case $1 in
  "$HOME") printf '~\n' ;;
  "$HOME"/*) printf '~/%s\n' "${1#"$HOME"/}" ;;
  *) printf '%s\n' "$1" ;;
  esac
}

# physical path of an existing path (follows every symlink)
real_path() {
  local target=$1 dir base link n=0
  while [ -L "$target" ] && [ $n -lt 40 ]; do
    link=$(readlink "$target")
    case $link in
    /*) target=$link ;;
    *) target=$(dirname "$target")/$link ;;
    esac
    n=$((n + 1))
  done
  dir=$(cd -P "$(dirname "$target")" 2>/dev/null && pwd) || return 1
  base=$(basename "$target")
  if [ "$base" = / ] || [ "$base" = . ]; then
    printf '%s\n' "$dir"
  else
    printf '%s/%s\n' "$dir" "$base"
  fi
}

# true when a home-relative path stays inside $HOME (no .. segments)
is_safe_home_path() {
  local p=$1
  case $p in
  "~/"*) ;;
  *) return 1 ;;
  esac
  case "/$p/" in
  */../* | */./*) return 1 ;;
  esac
  return 0
}

# //
# REPOSITORY SPECS
# //

# Validate a `--config` value and print the Git URL it names.
#
# Accepts OWNER/REPO (GitHub), https://host/path(.git), git@host:path(.git),
# ssh://..., file:///abs/path, or an absolute local path. Rejects embedded
# credentials, queries, fragments, whitespace, and shell metacharacters.
configs_url() {
  local spec=$1 owner repo
  case $spec in
  *[[:space:]]* | *'`'* | *'$'* | *';'* | *'|'* | *'&'* | *'<'* | *'>'* | *\\* | *'"'* | *"'"* | *'('* | *')'* | *'*'* | *'?'* | *'#'* | *'['* | *']'* | *'{'* | *'}'* | *'!'*)
    return 1
    ;;
  esac
  case $spec in
  https://*@* | http://* | *://*:*@*) return 1 ;;
  https://?*/?* | ssh://?*/?* | git@?*:?* | file:///?*)
    printf '%s\n' "$spec"
    return 0
    ;;
  /*)
    case "/$spec/" in */../*) return 1 ;; esac
    printf '%s\n' "$spec"
    return 0
    ;;
  esac
  case $spec in
  */*/* | */ | /*) return 1 ;;
  ?*/?*) ;;
  *) return 1 ;;
  esac
  owner=${spec%%/*}
  repo=${spec#*/}
  repo=${repo%.git}
  # GitHub: owner 1-39 alnum or single hyphens, not leading/trailing hyphen;
  # repository 1-100 of alnum . _ -, and not . or ..
  printf '%s\n' "$owner" | grep -Eq '^[A-Za-z0-9]([A-Za-z0-9]|-[A-Za-z0-9]){0,38}$' || return 1
  printf '%s\n' "$repo" | grep -Eq '^[A-Za-z0-9._-]{1,100}$' || return 1
  case $repo in . | ..) return 1 ;; esac
  printf 'https://github.com/%s/%s.git\n' "$owner" "$repo"
}

# OWNER/REPO for a github.com URL, empty otherwise
github_slug() {
  local url=$1
  case $url in
  https://github.com/*/*)
    url=${url#https://github.com/}
    printf '%s\n' "${url%.git}"
    ;;
  git@github.com:*/*)
    url=${url#git@github.com:}
    printf '%s\n' "${url%.git}"
    ;;
  esac
}

# remove anything that looks like credentials from text before printing it
redact() {
  sed -E \
    -e 's#(https?://)[^/@[:space:]]+@#\1***@#g' \
    -e 's#([a-z+]+://[^/:@[:space:]]+):[^/@[:space:]]+@#\1:***@#g' \
    -e 's/(gh[pousr]_|github_pat_)[A-Za-z0-9_]+/\1***/g' \
    -e 's/(x-access-token:)[^@[:space:]]+/\1***/g'
}

# //
# TOML (via mise, which every machine already has)
# //

# print one scalar value from a TOML file (empty when absent)
toml_get() {
  local value
  value=$(mise_cmd config get -f "$1" "$2" 2>/dev/null) || return 0
  case $value in
  \"*\") value=${value#\"} value=${value%\"} ;;
  esac
  printf '%s\n' "$value"
}

# print each string of a TOML array of strings on its own line
toml_get_list() {
  local raw
  raw=$(mise_cmd config get -f "$1" "$2" 2>/dev/null) || return 0
  # a character scanner: portable to BSD awk, handles \" and \\ escapes
  printf '%s\n' "$raw" | awk '
    { s = s $0 "\n" }
    END {
      n = length(s); inside = 0; v = ""
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (!inside) {
          if (c == "\"") { inside = 1; v = "" }
          continue
        }
        if (c == "\\") {
          i++
          v = v substr(s, i, 1)
        } else if (c == "\"") {
          print v
          inside = 0
        } else {
          v = v c
        }
      }
    }'
}
