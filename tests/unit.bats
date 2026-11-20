#!/usr/bin/env bats
#
# Pure helpers: argument validation, path handling, redaction, TOML reading.

load helpers

setup() {
  common_setup
  make_home "$WORLD/home"
  use_home "$WORLD/home"
  # shellcheck source=../lib/common.sh
  . "$REPO_ROOT/lib/common.sh"
}

@test "configs_url expands OWNER/REPO to a GitHub HTTPS URL" {
  run configs_url octocat/.configs
  [ "$status" -eq 0 ]
  [ "$output" = "https://github.com/octocat/.configs.git" ]
  run configs_url some-user/my.repo_name-1.git
  [ "$output" = "https://github.com/some-user/my.repo_name-1.git" ]
}

@test "configs_url accepts explicit URLs and absolute paths" {
  run configs_url https://github.com/a/b.git
  [ "$output" = "https://github.com/a/b.git" ]
  run configs_url git@github.com:a/b.git
  [ "$output" = "git@github.com:a/b.git" ]
  run configs_url file:///tmp/origin.git
  [ "$output" = "file:///tmp/origin.git" ]
  run configs_url /srv/git/configs.git
  [ "$output" = "/srv/git/configs.git" ]
}

@test "configs_url rejects injection, traversal, and credentials" {
  local bad
  for bad in \
    'a/b;rm -rf ~' 'a/$(id)' 'a/`id`' 'a/b c' 'a/b|x' 'a/b&' 'a/../b' '../a/b' 'a/..' 'a/.' \
    '-a/b' 'a-/b' 'a/b/c' 'a/' '/a/../b' 'https://user:pw@github.com/a/b.git' \
    'https://x-access-token:t@github.com/a/b' 'http://github.com/a/b' 'a/b?ref=x' 'a/b#frag' \
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/b' "a/b'" 'a/b"' 'a/b\x' ''; do
    run configs_url "$bad"
    if [ "$status" -eq 0 ]; then
      echo "accepted: $bad -> $output" >&2
      return 1
    fi
  done
}

@test "github_slug extracts OWNER/REPO from GitHub URLs only" {
  [ "$(github_slug https://github.com/a/b.git)" = a/b ]
  [ "$(github_slug git@github.com:a/b.git)" = a/b ]
  [ -z "$(github_slug file:///tmp/x.git)" ]
}

@test "redact hides credentials in URLs and tokens" {
  local token
  token=$(fake_github_token)
  run bash -c ". '$REPO_ROOT/lib/common.sh'; printf '%s\n' 'https://me:secret@github.com/a/b.git $token' | redact"
  [[ "$output" != *secret* ]]
  [[ "$output" != *"$token"* ]]
  [[ "$output" == *"https://***@github.com/a/b.git"* ]]
}

@test "home path helpers round-trip and refuse traversal" {
  [ "$(expand_home '~/.zshrc')" = "$HOME/.zshrc" ]
  [ "$(tilde_path "$HOME/.config/x")" = "~/.config/x" ]
  is_safe_home_path '~/.config/jj/config.toml'
  ! is_safe_home_path '~/../etc/passwd'
  ! is_safe_home_path '/etc/passwd'
  ! is_safe_home_path '~/./x'
}

@test "toml_get_list reads arrays of strings with spaces" {
  cat >"$HOME/t.toml" <<'EOF'
[sync]
paths = ["~/Library/Application Support/x", "~/a,b", "~/plain"]
EOF
  run toml_get_list "$HOME/t.toml" sync.paths
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "~/Library/Application Support/x" ]
  [ "${lines[1]}" = '~/a,b' ]
  [ "${lines[2]}" = "~/plain" ]
  [ "$(toml_get "$HOME/t.toml" sync.missing)" = "" ]
}

@test "platform detection names a supported OS and architecture" {
  run platform_os
  [[ "$output" == macos || "$output" == linux ]]
  run platform_arch
  [[ "$output" == arm64 || "$output" == x64 ]]
  case "$(platform_os)-$(platform_arch)" in
  macos-arm64) [ "$(brew_prefix)" = /opt/homebrew ] ;;
  macos-x64) [ "$(brew_prefix)" = /usr/local ] ;;
  *) [ "$(brew_prefix)" = /home/linuxbrew/.linuxbrew ] ;;
  esac
}

@test "confirm refuses without a terminal and accepts with ASSUME_YES" {
  run bash -c ". '$REPO_ROOT/lib/common.sh'; confirm 'go?' </dev/null" </dev/null
  [ "$status" -ne 0 ] || skip "a controlling terminal is attached"
  ASSUME_YES=1 confirm 'go?'
}

@test "Ghostty is absent from the setup" {
  run grep -RIil ghostty "$REPO_ROOT" --exclude-dir=.git --exclude-dir=.jj --exclude-dir=tests
  [ "$status" -ne 0 ]
}

@test "shell scripts parse under the bash that ships with macOS" {
  local f
  for f in install.sh setup.sh bin/dotfiles lib/common.sh lib/scan.sh; do
    "$TEST_BASH" -n "$REPO_ROOT/$f"
  done
  sh -n "$REPO_ROOT/configs/git/setup.sh"
}

@test "zsh configuration parses" {
  command -v zsh >/dev/null || skip "zsh not installed"
  local f
  for f in .zshrc .zshenv .common.zshrc utilities/jj.zsh $(cd "$REPO_ROOT" && ls .aliases.d/*.zsh); do
    zsh -n "$REPO_ROOT/$f"
  done
}
