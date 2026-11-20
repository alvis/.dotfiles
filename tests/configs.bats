#!/usr/bin/env bats
#
# .configs initialization (first machine) and adoption (other machines),
# against local bare repositories standing in for the private GitHub repo.

load helpers

setup() {
  common_setup
  ORIGIN=$WORLD/origin.git
  URL=file://$ORIGIN
  make_origin "$ORIGIN"
  provision "$WORLD/a" >/dev/null 2>&1
  mkdir -p "$HOME/.config/jj" "$HOME/.config/micro"
  printf '[user]\nname = "Machine A"\n' >"$HOME/.config/jj/config.toml"
  echo '{"tabsize": 4}' >"$HOME/.config/micro/settings.json"
}

init_a() { dotfiles config init "$URL" --apps jj,micro --yes; }

@test "init publishes only personal files and the tracking manifest" {
  run init_a
  [ "$status" -eq 0 ]
  [[ "$output" == *"remote history verified"* ]]
  run origin_files "$ORIGIN"
  [[ "$output" == *".mise-history/format.toml"* ]]
  [[ "$output" == *"config/config.toml"* ]]
  [[ "$output" == *"home/.config/jj/config.toml"* ]]
  [[ "$output" == *"home/.config/micro/settings.json"* ]]
  # nothing public: no shared layer, no fundamental dotfiles, no checkout
  [[ "$output" != *"conf.d"* ]]
  [[ "$output" != *".zshrc"* ]]
  [[ "$output" != *".dotfiles"* ]]
  [[ "$output" != *"config.local.toml"* ]]
  # the origin is machine-local state
  grep -q "$URL" "$HOME/.config/mise/config.local.toml"
}

@test "init is idempotent once connected" {
  init_a
  run init_a
  [ "$status" -eq 0 ]
  [[ "$output" == *"already connected"* ]]
}

@test "install without --init refuses to publish to an empty repository" {
  run dotfiles install --skip-packages --yes --config "$URL"
  [ "$status" -ne 0 ]
  [[ "$output" == *"is empty"* ]]
  [[ "$output" == *"--init"* ]]
  [ -z "$(git --git-dir="$ORIGIN" for-each-ref)" ]
}

@test "install --init on an empty repository publishes" {
  run dotfiles install --skip-packages --yes --init --apps jj --config "$URL"
  [ "$status" -eq 0 ]
  origin_files "$ORIGIN" | grep -q 'home/.config/jj/config.toml'
}

@test "a missing repository is reported, not created, for non-GitHub URLs" {
  run dotfiles config init "file://$WORLD/nope.git" --apps jj --yes
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
  ! [ -e "$WORLD/nope.git" ]
}

@test "init refuses a repository with unrelated history and changes nothing" {
  local work=$WORLD/work
  git clone -q "$ORIGIN" "$work" 2>/dev/null
  echo '# notes' >"$work/README.md"
  git -C "$work" add README.md
  git -C "$work" commit -qm notes
  git -C "$work" push -q origin HEAD:main
  local before
  before=$(git --git-dir="$ORIGIN" rev-parse main)
  run init_a
  [ "$status" -ne 0 ]
  [[ "$output" == *"not a mise history"* ]]
  [[ "$output" == *"--ref"* ]]
  [ "$(git --git-dir="$ORIGIN" rev-parse main)" = "$before" ]
  ! [ -e "$HOME/.config/mise/config.local.toml" ] || ! grep -q origin "$HOME/.config/mise/config.local.toml"
}

@test "init refuses to publish a history that saved a secret earlier" {
  # tracked by hand before .dotfiles was involved, then cleaned up
  printf 'token = %s\n' "$(fake_github_token)" >"$HOME/.notes"
  mise dot track ~/.notes >/dev/null 2>&1
  echo clean >"$HOME/.notes"
  mise dot save >/dev/null 2>&1
  run init_a
  [ "$status" -ne 0 ]
  [[ "$output" == *"possible secrets in saved history"* ]]
  [[ "$output" != *"$(fake_github_token)"* ]]
  [ -z "$(git --git-dir="$ORIGIN" for-each-ref)" ]
}

@test "init can publish to a new branch of a repository with other content" {
  local work=$WORLD/work
  git clone -q "$ORIGIN" "$work" 2>/dev/null
  echo '# notes' >"$work/README.md"
  git -C "$work" add README.md
  git -C "$work" commit -qm notes
  git -C "$work" push -q origin HEAD:main
  run dotfiles config init "$URL" --apps jj --ref mise-history --yes
  [ "$status" -eq 0 ]
  origin_files "$ORIGIN" mise-history | grep -q '.mise-history/format.toml'
  origin_files "$ORIGIN" mise-history | grep -q 'home/.config/jj/config.toml'
  # the existing branch is untouched
  [ "$(origin_files "$ORIGIN" main)" = README.md ]
  # another machine adopts the branch
  provision "$WORLD/b" >/dev/null 2>&1
  run dotfiles config adopt "$URL" --ref mise-history --yes
  [ "$status" -eq 0 ]
  grep -q 'Machine A' "$HOME/.config/jj/config.toml"
}

@test "install --init --config-ref publishes to a new branch of a repository with other content" {
  local work=$WORLD/work
  git clone -q "$ORIGIN" "$work" 2>/dev/null
  echo '# notes' >"$work/README.md"
  git -C "$work" add README.md
  git -C "$work" commit -qm notes
  git -C "$work" push -q origin HEAD:main
  run dotfiles install --skip-packages --yes --config "$URL" --config-ref mise-history
  [ "$status" -ne 0 ]
  [[ "$output" == *"re-run with --init"* ]]
  run dotfiles install --skip-packages --yes --init --apps jj --config "$URL" --config-ref mise-history
  [ "$status" -eq 0 ]
  origin_files "$ORIGIN" mise-history | grep -q 'home/.config/jj/config.toml'
  [ "$(origin_files "$ORIGIN" main)" = README.md ]
}

@test "the mise manifest is secret-scanned before it is tracked" {
  printf '[env]\nGITHUB_TOKEN = "%s"\n' "$(fake_github_token)" >"$HOME/.config/mise/config.toml"
  run dotfiles config add jj --yes
  [ "$status" -ne 0 ]
  [[ "$output" == *"config.toml: github-token"* ]]
  [[ "$output" != *"$(fake_github_token)"* ]]
}

@test "init verifies the published branch when the origin's HEAD names another" {
  rm -rf "$ORIGIN"
  git -c init.defaultBranch=master init -q --bare "$ORIGIN"
  run init_a
  [ "$status" -eq 0 ]
  [[ "$output" == *"remote history verified"* ]]
  # a second machine recognizes it as a mise history, not unrelated content
  provision "$WORLD/b" >/dev/null 2>&1
  run dotfiles install --skip-packages --yes --config "$URL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"is mise-history"* ]]
}

@test "enrolling Git moves an identity Git wrote to ~/.config/git/config into ~/.gitconfig" {
  rm -f "$HOME/.gitconfig"
  git config --file "$HOME/.config/git/config" user.name 'Machine A'
  git config --file "$HOME/.config/git/config" user.email 'a@example.invalid'
  run dotfiles config init "$URL" --apps git --yes
  [ "$status" -eq 0 ]
  [ "$(git config --file "$HOME/.gitconfig" user.name)" = 'Machine A' ]
  [ "$(git config --file "$HOME/.gitconfig" user.email)" = 'a@example.invalid' ]
  [ -z "$(git config --file "$HOME/.config/git/config" --get user.name || true)" ]
  # the machine-local part keeps the shared aliases include
  git config --file "$HOME/.config/git/config" --get-all include.path | grep -q 'configs/git/config.conf'
  origin_files "$ORIGIN" | grep -qx 'home/.gitconfig'
}

@test "keeping this machine's file during a paused adoption follows the printed steps" {
  init_a
  provision "$WORLD/b" >/dev/null 2>&1
  local f=$HOME/.config/jj/config.toml
  mkdir -p "$(dirname "$f")"
  printf '[user]\nname = "Machine B"\n' >"$f"
  run dotfiles config adopt "$URL" --yes
  [ "$status" -ne 0 ]
  [[ "$output" == *"keep yours: cp <path> <path>.mine"* ]]
  assert_file_content "$f" "$(printf '[user]\nname = "Machine B"')"
  # --keep-local cannot work yet, and says what to do instead
  run dotfiles config resolve "$f" --keep-local
  [ "$status" -ne 0 ]
  [[ "$output" == *"not tracked on this machine yet"* ]]
  cp "$f" "$f.mine"
  run dotfiles config resolve "$f" --take-remote
  [ "$status" -eq 0 ]
  assert_file_content "$f" "$(printf '[user]\nname = "Machine A"')"
  cp "$f.mine" "$f"
  run dotfiles config sync
  [ "$status" -eq 0 ]
  [ "$(git --git-dir="$ORIGIN" show main:home/.config/jj/config.toml)" = "$(printf '[user]\nname = "Machine B"')" ]
}

@test "adopt restores files and the manifest on a second machine" {
  init_a
  provision "$WORLD/b" >/dev/null 2>&1
  run dotfiles config adopt "$URL" --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"origin verified"* ]]
  assert_file_content "$HOME/.config/jj/config.toml" "$(printf '[user]\nname = "Machine A"')"
  ! [ -L "$HOME/.config/jj/config.toml" ]
  grep -q 'jj/config.toml' "$HOME/.config/mise/config.toml"
  grep -q "$URL" "$HOME/.config/mise/config.local.toml"
  # public layers stay links into this machine's own checkout
  [[ "$(readlink "$HOME/.config/mise/conf.d/00-dotfiles.toml")" == "$WORLD/b/.dotfiles/"* || "$(readlink "$HOME/.config/mise/conf.d/00-dotfiles.toml")" == *"/b/.dotfiles/"* ]]
}

@test "install --config adopts an existing history" {
  init_a
  provision "$WORLD/b" >/dev/null 2>&1
  run dotfiles install --skip-packages --yes --config "$URL"
  [ "$status" -eq 0 ]
  [[ "$output" == *"is mise-history"* ]]
  [ -f "$HOME/.config/micro/settings.json" ]
}

@test "adopt pauses for a differing local file and keeps it" {
  init_a
  provision "$WORLD/b" >/dev/null 2>&1
  mkdir -p "$HOME/.config/jj"
  echo 'mine' >"$HOME/.config/jj/config.toml"
  run dotfiles config adopt "$URL" --yes
  [ "$status" -ne 0 ]
  [[ "$output" == *"adoption paused"* ]]
  assert_file_content "$HOME/.config/jj/config.toml" mine
}

@test "adopt --take-remote replaces differing files and can be undone" {
  init_a
  provision "$WORLD/b" >/dev/null 2>&1
  mkdir -p "$HOME/.config/jj"
  echo 'mine' >"$HOME/.config/jj/config.toml"
  run dotfiles config adopt "$URL" --yes --take-remote
  [ "$status" -eq 0 ]
  grep -q 'Machine A' "$HOME/.config/jj/config.toml"
  run mise dot undo --yes
  assert_file_content "$HOME/.config/jj/config.toml" mine
}

@test "adopt refuses empty and unrelated repositories" {
  provision "$WORLD/b" >/dev/null 2>&1
  run dotfiles config adopt "$URL" --yes
  [ "$status" -ne 0 ]
  [[ "$output" == *"is empty, not a .configs history"* ]]
}

@test "adopt refuses a manifest that declares tasks, even with --yes" {
  init_a
  printf '\n[tasks.surprise]\nrun = "touch ~/pwned"\n' >>"$HOME/.config/mise/config.toml"
  mise dot save >/dev/null 2>&1
  mise dot sync >/dev/null 2>&1
  provision "$WORLD/b" >/dev/null 2>&1
  run dotfiles config adopt "$URL" --yes
  [ "$status" -ne 0 ]
  [[ "$output" == *"[tasks.surprise]"* ]]
  [[ "$output" == *"not adopted"* ]]
  ! [ -e "$HOME/pwned" ]
  [ -z "$(grep -s url "$HOME/.config/mise/config.local.toml")" ]
}

@test "a machine connected to one origin refuses to switch silently" {
  init_a
  make_origin "$WORLD/other.git"
  run dotfiles config adopt "file://$WORLD/other.git" --yes
  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing to switch"* || "$output" == *"is empty"* ]]
  grep -q "$URL" "$HOME/.config/mise/config.local.toml"
}

@test "the manifest policy allows tracking registry paths and refuses everything else" {
  local m=$WORLD/m.toml
  cat >"$m" <<'TOML'
min_version = "2026.11.11"
[dotfiles]
"~/.config/jj/config.toml" = { mode = "track" }
"~/.config/mise/config.toml" = { mode = "track" }
"~/.gitconfig" = { mode = "track", encrypt = true }
[history]
exclude = [
  "*.bak",
]
[settings.history]
sync_interval = "5m"
TOML
  run dotfiles config policy "$m"
  [ "$status" -eq 0 ]
  refused() {
    printf '%s\n' "$1" >"$m"
    run dotfiles config policy "$m"
    [ "$status" -ne 0 ] || { echo "allowed: $1" >&2; return 1; }
  }
  refused $'[env]\nFOO = "1"'
  refused $'[env]\n_.source = "/tmp/x.sh"'
  refused $'\'hooks\'.enter = "touch ~/pwned"'
  refused $'[tasks.x]\nrun = "id"'
  refused $'[tools]\nnode = "22"'
  refused $'[history.reload]\n"~/.config/jj/*" = "id"'
  refused $'[dotfiles]\n"~/Library/LaunchAgents/x.plist" = { mode = "track" }'
  refused $'[dotfiles]\n"~/.zprofile" = { mode = "track" }'
  refused $'[dotfiles]\n"~/.config/jj/config.toml" = { mode = "track", allow_plaintext = true }'
  refused $'[dotfiles]\n"~/.config/jj/config.toml" = { mode = "symlink", source = "/tmp/x" }'
  refused $'[settings.history]\nallow_plaintext_history = true'
  refused $'[settings.history.encryption]\nrecipients = ["age1x"]'
  refused $'[settings]\nhistory.sync = "sync"'
  refused 'not toml ['
}
