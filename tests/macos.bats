#!/usr/bin/env bats
#
# macOS preference domains through the real cfprefsd. cfprefsd serves the
# logged-in user's domains whatever $HOME says, so these tests use throwaway
# `dev.dotfiles.test.*` domains only (the code refuses any other domain in a
# test run) and delete them afterwards. They run when DOTFILES_TEST_DEFAULTS=1.
#
# What this verifies: export, sanitizing, applying incoming copies through
# cfprefsd, the per-key merge, and mise's reload hook. It does not verify that
# a particular application re-reads its settings; see README: limitations.

load helpers

setup() {
  [ "$(uname -s)" = Darwin ] || skip "macOS only"
  [ "${DOTFILES_TEST_DEFAULTS:-0}" = 1 ] || skip "set DOTFILES_TEST_DEFAULTS=1 to write test preference domains"
  common_setup
  DOMAIN=dev.dotfiles.test.$$.$RANDOM
  provision "$WORLD/a" >/dev/null 2>&1
  cat >"$HOME/.dotfiles/apps/testapp.toml" <<EOF
schema = 1

[app]
id = "testapp"
name = "Test App"
platforms = ["macos"]
install = ""

[compat]
verified = true
versions = "1"
checked = "test"

[sync]
strategy = "auto"
default = false
method = "defaults"
reload = "restart-if-running"
domain = "$DOMAIN"
bundle_id = "$DOMAIN"
deny_keys = ["cachedThing"]

[unsafe]
paths = ["~/Library/Preferences/$DOMAIN.plist"]
notes = "test fixture"
EOF
  defaults write "$DOMAIN" Theme -string dark
  defaults write "$DOMAIN" FontSize -int 12
  defaults write "$DOMAIN" apiToken -string not-for-sync
  defaults write "$DOMAIN" cachedThing -string local-cache
  defaults write "$DOMAIN" "NSWindow Frame Main" -string "0 0 10 10"
  PREFS=$HOME/.config/dotfiles/prefs/$DOMAIN.plist
}

teardown() {
  [ -n "${DOMAIN:-}" ] || return 0
  defaults delete "$DOMAIN" >/dev/null 2>&1 || true
  # cfprefsd keeps an empty file in the real user's preferences folder
  local real_home
  real_home=$(dscl . -read "/Users/$(id -un)" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
  case $DOMAIN in
  dev.dotfiles.test.*) [ -z "$real_home" ] || rm -f "$real_home/Library/Preferences/$DOMAIN.plist" ;;
  esac
}

key() { plutil -extract "$2" raw -o - "$1" 2>/dev/null; }

@test "real application domains are refused in a test run" {
  run dotfiles config add bartender
  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing real preference domain"* ]]
}

@test "enrolling exports a sanitized copy and tracks only that copy" {
  run dotfiles config add testapp
  [ "$status" -eq 0 ]
  [ "$(key "$PREFS" Theme)" = dark ]
  [ "$(key "$PREFS" FontSize)" = 12 ]
  ! key "$PREFS" apiToken
  ! key "$PREFS" cachedThing
  ! key "$PREFS" "NSWindow Frame Main"
  [ "$(stat -f %Lp "$PREFS")" = 600 ]
  run mise dot paths
  [[ "$output" == *"prefs/$DOMAIN.plist"* ]]
  [[ "$output" != *"Library/Preferences"* ]]
}

@test "a local change is exported on the next tick" {
  dotfiles config add testapp
  defaults write "$DOMAIN" FontSize -int 14
  run dotfiles prefs tick
  [ "$status" -eq 0 ]
  [[ "$output" == *"testapp	exported"* ]]
  [ "$(key "$PREFS" FontSize)" = 14 ]
  run dotfiles prefs tick
  [[ "$output" == *"testapp	unchanged"* ]]
}

@test "an incoming copy is applied through cfprefsd and keeps local-only keys" {
  dotfiles config add testapp
  plutil -replace Theme -string light "$PREFS"
  run dotfiles prefs tick
  [ "$status" -eq 0 ]
  [[ "$output" == *"testapp	applied"* ]]
  [ "$(defaults read "$DOMAIN" Theme)" = light ]
  [ "$(defaults read "$DOMAIN" apiToken)" = not-for-sync ]
  [ "$(defaults read "$DOMAIN" cachedThing)" = local-cache ]
}

@test "an app enrolled on another Mac is picked up once the synced manifest arrives" {
  dotfiles config add testapp
  # as on a Mac whose policy predates the pulled manifest entry
  printf '{"state_dir": "%s", "apps": []}' "$HOME/.local/state/dotfiles/prefs" >"$HOME/.local/state/dotfiles/prefs/policy.json"
  touch -t 200001010000 "$HOME/.local/state/dotfiles/prefs/policy.json"
  plutil -replace Theme -string light "$PREFS"
  run dotfiles prefs tick
  [ "$status" -eq 0 ]
  [[ "$output" == *"testapp	applied"* ]]
  [ "$(defaults read "$DOMAIN" Theme)" = light ]
}

@test "the same key changed on both sides keeps this Mac's value and reports it" {
  dotfiles config add testapp
  plutil -replace FontSize -integer 20 "$PREFS"
  defaults write "$DOMAIN" FontSize -int 16
  run dotfiles prefs tick
  [ "$status" -eq 0 ]
  [ "$(defaults read "$DOMAIN" FontSize)" = 16 ]
  [ "$(key "$PREFS" FontSize)" = 16 ]
  grep -q FontSize "$HOME/.local/state/dotfiles/prefs/conflicts.jsonl"
  run dotfiles config status
  [[ "$output" == *"testapp: FontSize"* ]]
}

@test "mise's reload hook applies a restored copy" {
  dotfiles config add testapp
  defaults write "$DOMAIN" Theme -string blue
  dotfiles prefs tick >/dev/null
  mise dot save >/dev/null 2>&1
  # roll the tracked copy back to the enrolled version, as a pull would write it
  run mise dot rollback "$PREFS" --yes
  [ "$status" -eq 0 ]
  [ "$(defaults read "$DOMAIN" Theme)" = dark ]
}

@test "the service and reload hook are declared in the macOS layer" {
  run mise bootstrap services status
  [[ "$output" == *"user-service:dotfiles-watch"* ]]
  [[ "$output" == *"user-service:mise-history"* ]]
  run mise config get -f "$HOME/.config/mise/conf.d/01-dotfiles-macos.toml" history.reload
  [[ "$output" == *"dotfiles prefs tick"* ]]
}
