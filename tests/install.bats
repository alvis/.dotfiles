#!/usr/bin/env bats
#
# Bootstrap: install.sh argument handling, the blueprint, the fundamental
# dotfile links, idempotence, and resuming after an interruption.

load helpers

setup() {
  common_setup
  make_home "$WORLD/a"
  install_checkout "$WORLD/a"
  use_home "$WORLD/a"
}

@test "install.sh rejects unknown options, bad refs, and relative checkout paths" {
  run "$TEST_BASH" "$REPO_ROOT/install.sh" --bogus
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown option"* ]]
  run "$TEST_BASH" "$REPO_ROOT/install.sh" --ref 'x;id'
  [[ "$output" == *"invalid --ref"* ]]
  run "$TEST_BASH" "$REPO_ROOT/install.sh" --dotfiles-dir relative/path
  [[ "$output" == *"absolute path"* ]]
  run "$TEST_BASH" "$REPO_ROOT/install.sh" --config
  [[ "$output" == *"needs a value"* ]]
}

@test "install.sh pins a checksum for every supported platform" {
  local p
  for p in macos-arm64 macos-x64 linux-x64 linux-arm64; do
    grep -Eq "^  $p\) echo [0-9a-f]{64} ;;" "$REPO_ROOT/install.sh"
  done
}

@test "install.sh refuses a non-checkout at the target directory" {
  mkdir -p "$WORLD/b/notrepo"
  run env HOME="$WORLD/b" MISE_BIN="$MISE_BIN" "$TEST_BASH" "$REPO_ROOT/install.sh" --dotfiles-dir "$WORLD/b/notrepo"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not a Git checkout"* ]]
}

@test "install.sh hands an existing checkout to dotfiles install" {
  run "$TEST_BASH" "$REPO_ROOT/install.sh" --dotfiles-dir "$HOME/.dotfiles" --skip-packages --yes --config 'bad;name'
  [ "$status" -ne 0 ]
  [[ "$output" == *"using the existing checkout"* ]]
  [[ "$output" == *"invalid --config"* ]]
}

@test "dotfiles install on a fresh home links the fundamental dotfiles and layers" {
  run dotfiles install --skip-packages --yes
  [ "$status" -eq 0 ]
  local f
  for f in .zshenv .common.zshrc .aliases.d .tmux.conf .gitignore_global .gemrc; do
    [ -L "$HOME/$f" ]
    [[ "$(readlink "$HOME/$f")" == *"/.dotfiles/$f" ]]
  done
  # .zshrc is the macOS layer; on Linux the machine's own ~/.zshrc loads the core
  if [ "$(uname)" = Darwin ]; then
    [[ "$(readlink "$HOME/.zshrc")" == *"/.dotfiles/.zshrc" ]]
  else
    grep -q 'source ~/.common.zshrc' "$HOME/.zshrc"
  fi
  [[ "$(readlink "$HOME/.config/mise/conf.d/00-dotfiles.toml")" == *"/.dotfiles/mise/global.toml" ]]
  [[ "$(readlink "$HOME/.local/bin/dotfiles")" == *"/.dotfiles/bin/dotfiles" ]]
  # the personal manifest is not created by the public blueprint
  ! [ -e "$HOME/.config/mise/config.toml" ]
  # shared Git aliases come from the machine-local file, once
  [ "$(git config --file "$HOME/.config/git/config" --get-all include.path | grep -c configs/git/config.conf)" -eq 1 ]
  git config --includes --global --get alias.sweep >/dev/null
  # the nano block is managed, user lines kept
  grep -q 'mise:dotfiles' "$HOME/.nanorc"
}

@test "repeated install changes nothing and keeps the single Git include" {
  dotfiles install --skip-packages --yes
  echo 'set tabsize 4' >>"$HOME/.nanorc"
  run dotfiles install --skip-packages --yes
  [ "$status" -eq 0 ]
  [ "$(git config --global --get-all include.path | grep -c configs/git/config.conf)" -eq 1 ]
  grep -q 'set tabsize 4' "$HOME/.nanorc"
  [ "$(grep -c 'mise:dotfiles >>>' "$HOME/.nanorc")" -eq 1 ]
}

@test "an interrupted install resumes: a partial run is completed by the next" {
  # simulate a run killed after linking only some files
  ln -s "$HOME/.dotfiles/.zshenv" "$HOME/.zshenv"
  mkdir -p "$HOME/.config/mise/conf.d"
  run dotfiles install --skip-packages --yes
  [ "$status" -eq 0 ]
  [ -L "$HOME/.tmux.conf" ]
  [ -L "$HOME/.config/mise/conf.d/00-dotfiles.toml" ]
}

@test "an existing personal .zshenv is never replaced without confirmation" {
  echo 'my own' >"$HOME/.zshenv"
  run dotfiles install --skip-packages </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" == *"is your own"* ]]
  assert_file_content "$HOME/.zshenv" 'my own'
}

@test "with --yes a conflicting file is backed up before linking" {
  echo 'my own' >"$HOME/.zshenv"
  ln -s /etc/hosts "$HOME/.tmux.conf"
  ln -s "$HOME/nowhere" "$HOME/.gemrc"
  run dotfiles install --skip-packages --yes
  [ "$status" -eq 0 ]
  [ -L "$HOME/.zshenv" ]
  local backup
  backup=$(ls -d "$HOME"/.local/state/dotfiles/backups/*)
  assert_file_content "$backup/.zshenv" 'my own'
  [ "$(readlink "$backup/.tmux.conf")" = /etc/hosts ]
  [ -L "$backup/.gemrc" ]
}

@test "a link to the expected checkout under another spelling is accepted silently" {
  ln -s "$HOME/.dotfiles/bin/../.zshenv" "$HOME/.zshenv"
  run dotfiles link --check </dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"ok        ~/.zshenv"* || "$output" == *"already points to this checkout"* ]]
  [ "$(readlink "$HOME/.zshenv")" = "$HOME/.dotfiles/bin/../.zshenv" ]
}

@test "link --dry-run reports the plan and changes nothing" {
  echo 'my own' >"$HOME/.zshenv"
  dotfiles install --skip-packages --yes >/dev/null 2>&1 || true
  rm -f "$HOME/.tmux.conf"
  echo 'mine' >"$HOME/.tmux.conf"
  run dotfiles link --dry-run --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run] mv"* ]]
  assert_file_content "$HOME/.tmux.conf" 'mine'
}

@test "an existing global git include in ~/.gitconfig is not duplicated" {
  git config --file "$HOME/.gitconfig" --add include.path "$HOME/.dotfiles/configs/git/config.conf"
  run dotfiles install --skip-packages --yes
  [ "$status" -eq 0 ]
  [ "$(git config --global --get-all include.path | grep -c configs/git/config.conf)" -eq 1 ]
}

@test "gpg-agent settings are merged into an existing file" {
  [ "$(uname -s)" = Darwin ] || skip "macOS only"
  mkdir -p "$HOME/.gnupg"
  printf 'pinentry-program /old/path\nkeep-me 1\n' >"$HOME/.gnupg/gpg-agent.conf"
  dotfiles install --skip-packages --yes
  dotfiles install --skip-packages --yes
  run cat "$HOME/.gnupg/gpg-agent.conf"
  [ "$(grep -c '^pinentry-program' "$HOME/.gnupg/gpg-agent.conf")" -eq 1 ]
  local prefix=/usr/local
  [ "$(uname -m)" != arm64 ] || prefix=/opt/homebrew
  grep -q "pinentry-program $prefix/bin/pinentry-mac" "$HOME/.gnupg/gpg-agent.conf"
  grep -q '^keep-me 1' "$HOME/.gnupg/gpg-agent.conf"
  grep -q '^allow-preset-passphrase' "$HOME/.gnupg/gpg-agent.conf"
}

@test "the blueprint declares the fixed application set for the platform" {
  run mise -C "$HOME/.dotfiles" config get -f "$HOME/.dotfiles/mise.toml" bootstrap.packages
  [ "$status" -eq 0 ]
  local pkg
  for pkg in brew:tmux brew:zsh brew:git brew:gh brew:jj brew:micro brew:bat brew:eza; do
    [[ "$output" == *"\"$pkg\""* ]] || { echo "missing $pkg" >&2; return 1; }
  done
  for pkg in bartender iterm2 little-snitch visual-studio-code docker-desktop 1password-cli slack notion; do
    [[ "$output" == *"\"brew-cask:$pkg\""* ]] || { echo "missing cask $pkg" >&2; return 1; }
  done
}
