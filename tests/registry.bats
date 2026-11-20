#!/usr/bin/env bats
#
# The application registry: schema, policies, and `dotfiles config` handling.

load helpers

setup() {
  common_setup
  make_home "$WORLD/home"
  install_checkout "$WORLD/home"
  use_home "$WORLD/home"
}

field() { mise config get -f "$1" "$2" 2>/dev/null | sed -e 's/^"//' -e 's/"$//'; }

@test "every registry entry has the required fields and valid values" {
  local f id
  for f in "$REPO_ROOT"/apps/*.toml; do
    id=$(basename "$f" .toml)
    [ "$(field "$f" schema)" = 1 ] || { echo "$id: schema" >&2; return 1; }
    [ "$(field "$f" app.id)" = "$id" ] || { echo "$id: app.id must match the file name" >&2; return 1; }
    [ -n "$(field "$f" app.name)" ] || { echo "$id: app.name" >&2; return 1; }
    case "$(field "$f" sync.strategy)" in
    auto | backup)
      case "$(field "$f" sync.method)" in
      file) [ -n "$(field "$f" sync.paths)" ] || { echo "$id: file method needs paths" >&2; return 1; } ;;
      defaults)
        [ -n "$(field "$f" sync.domain)" ] && [ -n "$(field "$f" sync.bundle_id)" ] ||
          { echo "$id: defaults method needs domain and bundle_id" >&2; return 1; }
        ;;
      *) echo "$id: unknown method" >&2; return 1 ;;
      esac
      case "$(field "$f" sync.reload)" in
      none | restart-if-running | next-launch) ;;
      *) echo "$id: unknown reload" >&2; return 1 ;;
      esac
      ;;
    manual | excluded) ;;
    *) echo "$id: unknown strategy" >&2; return 1 ;;
    esac
    case "$(field "$f" compat.verified)" in true | false) ;; *) echo "$id: compat.verified" >&2; return 1 ;; esac
    [ -n "$(field "$f" unsafe.notes)" ] || { echo "$id: unsafe.notes" >&2; return 1; }
    ! grep -q '\\"' "$f" || { echo "$id: values must not contain quotes" >&2; return 1; }
  done
}

@test "registry paths stay inside the home directory" {
  local f p
  for f in "$REPO_ROOT"/apps/*.toml; do
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      case "$p" in
      "~/"*) ;;
      *) echo "$f: $p" >&2; return 1 ;;
      esac
      case "/$p/" in */../* | */./*) echo "$f: $p" >&2; return 1 ;; esac
    done <<EOF
$(mise config get -f "$f" sync.paths 2>/dev/null | tr ',' '\n' | tr -d '[]"' | sed 's/^ *//')
EOF
  done
}

@test "the default enrollment is the confirmed initial set" {
  local f defaults=''
  for f in "$REPO_ROOT"/apps/*.toml; do
    [ "$(field "$f" sync.default)" = true ] && defaults="$defaults $(basename "$f" .toml)"
  done
  [ "$defaults" = " bartender git htop iterm2 jj micro" ]
}

@test "credential and live-database entries are never automatic" {
  local id
  for id in npm docker buku macos geektool; do
    [ "$(field "$REPO_ROOT/apps/$id.toml" sync.strategy)" = excluded ]
  done
  [ "$(field "$REPO_ROOT/apps/little-snitch.toml" sync.strategy)" = manual ]
}

@test "raw plists of preference-domain apps are listed as unsafe" {
  local f domain
  for f in "$REPO_ROOT"/apps/*.toml; do
    [ "$(field "$f" sync.method)" = defaults ] || continue
    domain=$(field "$f" sync.domain)
    grep -Fq "~/Library/Preferences/$domain.plist" "$f" || { echo "$f" >&2; return 1; }
  done
}

@test "config list shows the platform's applications and policies" {
  run dotfiles config list
  [ "$status" -eq 0 ]
  [[ "$output" == *"git"*"Git identity"*"auto"*"file"* ]]
  [[ "$output" == *"npm"*"excluded"* ]]
  if [ "$(uname -s)" = Darwin ]; then
    [[ "$output" == *"bartender"*"defaults"* ]]
  else
    [[ "$output" != *"bartender"* ]]
  fi
}

@test "config add refuses excluded, manual, unverified, unknown, and malformed apps" {
  run dotfiles config add npm
  [ "$status" -ne 0 ]
  [[ "$output" == *"excluded"* ]]
  run dotfiles config add nope
  [[ "$output" == *"unknown application"* ]]
  run dotfiles config add '../etc'
  [[ "$output" == *"invalid application id"* ]]
  if [ "$(uname -s)" = Darwin ]; then
    run dotfiles config add little-snitch
    [[ "$output" == *"manual-only"* ]]
    run dotfiles config add rectangle
    [[ "$output" == *"--unverified"* ]]
  fi
}

@test "config add tracks a file in place and the manifest itself" {
  mkdir -p "$HOME/.config/jj"
  printf '[user]\nname = "t"\n' >"$HOME/.config/jj/config.toml"
  run dotfiles config add jj
  [ "$status" -eq 0 ]
  run mise dot paths
  [[ "$output" == *".config/jj/config.toml"* ]]
  [[ "$output" == *".config/mise/config.toml"* ]]
  # the live file stays a regular file
  [ -f "$HOME/.config/jj/config.toml" ] && ! [ -L "$HOME/.config/jj/config.toml" ]
  # idempotent
  run dotfiles config add jj
  [ "$status" -eq 0 ]
  [[ "$output" == *"already tracked"* ]]
}

@test "config remove stops tracking without touching the settings" {
  mkdir -p "$HOME/.config/htop"
  echo 'fields=0 48' >"$HOME/.config/htop/htoprc"
  dotfiles config add htop
  run dotfiles config remove htop
  [ "$status" -eq 0 ]
  assert_file_content "$HOME/.config/htop/htoprc" 'fields=0 48'
  run mise dot paths
  [[ "$output" != *"htoprc"* ]]
}

@test "config add converts a Mackup link into a regular file and keeps the Mackup copy" {
  mkdir -p "$HOME/Dropbox/Mackup/.config/micro" "$HOME/.config/micro"
  echo '{"tabsize": 2}' >"$HOME/Dropbox/Mackup/.config/micro/settings.json"
  ln -s "$HOME/Dropbox/Mackup/.config/micro/settings.json" "$HOME/.config/micro/settings.json"
  run dotfiles config add micro --yes
  [ "$status" -eq 0 ]
  ! [ -L "$HOME/.config/micro/settings.json" ]
  assert_file_content "$HOME/.config/micro/settings.json" '{"tabsize": 2}'
  assert_file_content "$HOME/Dropbox/Mackup/.config/micro/settings.json" '{"tabsize": 2}'
  ls "$HOME"/.local/state/dotfiles/backups/*/.config/micro/settings.json.mackup-link
}

@test "config add leaves a broken Mackup link alone" {
  mkdir -p "$HOME/.config/micro"
  ln -s "$HOME/Dropbox/Mackup/.config/micro/settings.json" "$HOME/.config/micro/settings.json"
  run dotfiles config add micro --yes
  [[ "$output" == *"broken Mackup link"* ]]
  [ -L "$HOME/.config/micro/settings.json" ]
}

@test "config add tolerates a missing application file" {
  run dotfiles config add jj
  [ "$status" -eq 0 ]
  [[ "$output" == *"does not exist yet"* ]]
}

@test "config add refuses a file that contains a secret, before any checkpoint" {
  mkdir -p "$HOME/.aws"
  printf '[default]\nregion = x\naws_access_key_id = %s\n' "$(fake_aws_key)" >"$HOME/.aws/config"
  run dotfiles config add aws
  [ "$status" -ne 0 ]
  [[ "$output" == *"possible secrets"* ]]
  [[ "$output" != *"$(fake_aws_key)"* ]]
  run mise dot history
  [[ "$output" != *".aws"* ]]
}
