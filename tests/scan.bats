#!/usr/bin/env bats
#
# The secret scan that guards every enrollment and the first publication.

load helpers

setup() {
  common_setup
  make_home "$WORLD/home"
  use_home "$WORLD/home"
  # shellcheck source=../lib/common.sh
  . "$REPO_ROOT/lib/common.sh"
  # shellcheck source=../lib/scan.sh
  . "$REPO_ROOT/lib/scan.sh"
}

@test "clean configuration passes" {
  printf '[user]\nname = "a"\nemail = "a@example.invalid"\nsigningkey = 42DA1B768A8B90C0\n' >"$HOME/clean"
  run scan_files "$HOME/clean"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "common credential formats are found, and the values are not printed" {
  local key
  key=$(fake_aws_key)
  printf 'aws_access_key_id = %s\n' "$key" >"$HOME/a"
  printf 'token: %s\n' "$(fake_github_token)" >"$HOME/b"
  printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nxxx\n' >"$HOME/c"
  printf '//registry.npmjs.org/:_authToken=abc\n' >"$HOME/d"
  printf 'url = https://user:hunter22@example.com/x\n' >"$HOME/e"
  printf 'api_key = "0123456789abcdef0123"\n' >"$HOME/f"
  run scan_files "$HOME/a" "$HOME/b" "$HOME/c" "$HOME/d" "$HOME/e" "$HOME/f"
  [ "$status" -eq 1 ]
  [[ "$output" == *"/a: aws-access-key"* ]]
  [[ "$output" == *"/b: github-token"* ]]
  [[ "$output" == *"/c: private-key"* ]]
  [[ "$output" == *"/d: npm-token"* ]]
  [[ "$output" == *"/e: basic-auth-url"* ]]
  [[ "$output" == *"/f: assignment"* ]]
  [[ "$output" != *"$key"* ]]
  [[ "$output" != *hunter22* ]]
}

@test "binary plists are scanned as text" {
  command -v plutil >/dev/null || skip "plutil is macOS-only"
  printf '<?xml version="1.0"?><plist version="1.0"><dict><key>t</key><string>%s</string></dict></plist>' \
    "$(fake_github_token)" >"$HOME/x.plist"
  plutil -convert binary1 "$HOME/x.plist"
  run scan_files "$HOME/x.plist"
  [ "$status" -eq 1 ]
  [[ "$output" == *"github-token"* ]]
}

@test "history scan finds a secret in an earlier commit" {
  local repo=$HOME/h
  git init -q "$repo"
  printf 'k = %s\n' "$(fake_aws_key)" >"$repo/f"
  git -C "$repo" add f
  git -C "$repo" commit -qm one
  echo clean >"$repo/f"
  git -C "$repo" commit -qam two
  run scan_history "$repo/.git"
  [ "$status" -eq 1 ]
  [[ "$output" == *"history:f: aws-access-key"* ]]
}

@test "history scan of a clean history passes" {
  local repo=$HOME/h
  git init -q "$repo"
  echo ok >"$repo/f"
  git -C "$repo" add f
  git -C "$repo" commit -qm one
  run scan_history "$repo/.git"
  [ "$status" -eq 0 ]
}

@test "history scan fails closed when there is no history to read" {
  run scan_history "$HOME/missing.git"
  [ "$status" -eq 2 ]
  mkdir "$HOME/not-a-repo.git"
  run scan_history "$HOME/not-a-repo.git"
  [ "$status" -eq 2 ]
}
