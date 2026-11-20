#!/usr/bin/env bats
#
# End-to-end automatic synchronization between two isolated machines (two
# homes with separate mise state) through a local bare origin.
#
# `watch_once` is one cycle of the history-watch service (save, push, fetch,
# apply); "the real watcher" tests run `mise dot watch` itself in the
# background, which is the process the LaunchAgent starts.

load helpers

setup() {
  common_setup
  ORIGIN=$WORLD/origin.git
  URL=file://$ORIGIN
  make_origin "$ORIGIN"
  A=$WORLD/a
  B=$WORLD/b
  provision "$B" >/dev/null 2>&1
  provision "$A" >/dev/null 2>&1
  mkdir -p "$A/.config/jj"
  printf 'v1\n' >"$A/.config/jj/config.toml"
  # 1-2. initialize .configs on machine A and enroll a configuration file
  dotfiles config init "$URL" --apps jj --yes >/dev/null 2>&1
  # 5. restore on machine B
  use_home "$B"
  dotfiles config adopt "$URL" --yes >/dev/null 2>&1
  use_home "$A"
}

teardown() {
  [ -z "${WATCH_PID:-}" ] || kill "$WATCH_PID" 2>/dev/null || true
  [ -z "${GATE_PID:-}" ] || kill "$GATE_PID" 2>/dev/null || true
}

# the two background services: mise's watcher and the gated exchange
start_services() {
  mise dot watch >"$BATS_TEST_TMPDIR/watch-$1.log" 2>&1 &
  WATCH_PID=$!
  # exec, so that the PID is the service itself and not a wrapper shell
  (DOTFILES_WATCH_INTERVAL=1 DOTFILES_SYNC_INTERVAL=1 exec "$TEST_BASH" "$HOME/.dotfiles/bin/dotfiles" watch) >"$BATS_TEST_TMPDIR/gate-$1.log" 2>&1 &
  GATE_PID=$!
}
stop_services() {
  kill "$WATCH_PID" "$GATE_PID" 2>/dev/null || true
  wait "$WATCH_PID" "$GATE_PID" 2>/dev/null || true
  WATCH_PID='' GATE_PID=''
}

on() { use_home "$1"; }
jj_file() { printf '%s/.config/jj/config.toml\n' "$1"; }

# wait until the origin's main branch differs from <commit>, up to <seconds>
wait_for_push() {
  local before=$1 limit=${2:-60} i=0
  while [ "$(git --git-dir="$ORIGIN" rev-parse main)" = "$before" ]; do
    i=$((i + 1))
    [ $i -le "$limit" ] || return 1
    sleep 1
  done
}

@test "machine B starts with A's file as a regular file" {
  assert_file_content "$(jj_file "$B")" v1
  ! [ -L "$(jj_file "$B")" ]
}

@test "an edit on A arrives on B, and an edit on B arrives back on A" {
  # 3-4. edit on A; the watcher cycle captures and publishes it
  on "$A"
  printf 'v2 from A\n' >"$(jj_file "$A")"
  watch_once
  # 6. B's watcher cycle fetches and applies it
  on "$B"
  watch_once
  assert_file_content "$(jj_file "$B")" 'v2 from A'
  # 7-8. edit on B propagates back to A
  printf 'v3 from B\n' >"$(jj_file "$B")"
  watch_once
  on "$A"
  watch_once
  assert_file_content "$(jj_file "$A")" 'v3 from B'
}

@test "permissions of a private file are preserved across machines" {
  on "$A"
  chmod 600 "$(jj_file "$A")"
  printf 'private\n' >"$(jj_file "$A")"
  watch_once
  on "$B"
  watch_once
  assert_file_content "$(jj_file "$B")" private
  [ "$(stat -c %a "$(jj_file "$B")" 2>/dev/null || stat -f %Lp "$(jj_file "$B")")" = 600 ]
}

@test "concurrent edits are preserved, reported, resolved, and sync resumes" {
  # 9. both machines edit the same file before seeing each other's change
  on "$A"
  printf 'A wins?\n' >"$(jj_file "$A")"
  watch_once
  on "$B"
  printf 'B wins?\n' >"$(jj_file "$B")"
  run watch_once
  # 10. B keeps its own version; A's is in the origin; the conflict is reported
  assert_file_content "$(jj_file "$B")" 'B wins?'
  [ "$(git --git-dir="$ORIGIN" show main:home/.config/jj/config.toml)" = 'A wins?' ]
  run dotfiles config status
  [[ "$output" == *"onflict"* ]]
  run mise dot conflicts "$(jj_file "$B")"
  [[ "$output" == *"A wins?"* && "$output" == *"B wins?"* ]]
  # 11. resolve on B, keeping B's version
  run dotfiles config resolve "$(jj_file "$B")" --keep-local
  [ "$status" -eq 0 ]
  watch_once
  on "$A"
  watch_once
  assert_file_content "$(jj_file "$A")" 'B wins?'
  # 12. synchronization resumes in both directions
  printf 'after the conflict\n' >"$(jj_file "$A")"
  watch_once
  on "$B"
  watch_once
  assert_file_content "$(jj_file "$B")" 'after the conflict'
}

@test "taking the remote version during a conflict keeps the local one undoable" {
  on "$A"
  printf 'remote\n' >"$(jj_file "$A")"
  watch_once
  on "$B"
  printf 'local\n' >"$(jj_file "$B")"
  run watch_once
  run dotfiles config resolve "$(jj_file "$B")" --take-remote
  [ "$status" -eq 0 ]
  assert_file_content "$(jj_file "$B")" remote
  mise dot undo --yes
  assert_file_content "$(jj_file "$B")" local
}

@test "a temporary network outage defers the push and recovers afterwards" {
  on "$A"
  mv "$ORIGIN" "$ORIGIN.away"
  printf 'written offline\n' >"$(jj_file "$A")"
  run watch_once
  [ "$status" -ne 0 ]
  # saved locally even though it could not be published
  run mise dot history --path "$(jj_file "$A")"
  [ "$status" -eq 0 ]
  run mise dot status
  [[ "$output" == *"rror"* || "$output" == *"fail"* || "$output" == *"unavailable"* ]]
  mv "$ORIGIN.away" "$ORIGIN"
  # automatic retries back off; an explicit sync recovers at once
  run dotfiles config sync
  [ "$status" -eq 0 ]
  on "$B"
  watch_once
  assert_file_content "$(jj_file "$B")" 'written offline'
}

@test "a failed background exchange is reported until an exchange succeeds" {
  on "$A"
  local state=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles i=0
  mv "$ORIGIN" "$ORIGIN.away"
  start_services outage
  until [ -f "$state/exchange-failed" ]; do
    i=$((i + 1))
    [ $i -le 60 ] || { cat "$state/watch.log" >&2; return 1; }
    sleep 1
  done
  stop_services
  # the service's own log keeps the reason; the LaunchAgent discards output
  grep -q . "$state/watch.log"
  run dotfiles config doctor
  [ "$status" -ne 0 ]
  [[ "$output" == *"last automatic exchange with .configs failed"* ]]
  run dotfiles config status
  [[ "$output" == *"retry now with: dotfiles config sync"* ]]
  mv "$ORIGIN.away" "$ORIGIN"
  run dotfiles config sync
  [ "$status" -eq 0 ]
  ! [ -f "$state/exchange-failed" ]
}

@test "doctor reports when the background environment cannot reach the origin" {
  on "$A"
  run dotfiles config doctor
  [[ "$output" == *"background authentication: ok"* ]]
  chmod 000 "$ORIGIN"
  run dotfiles config doctor
  chmod 755 "$ORIGIN"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot authenticate"* ]]
}

@test "a new enrollment on A, including its manifest entry, reaches B" {
  on "$A"
  mkdir -p "$A/.config/htop"
  printf 'fields=0 48\n' >"$A/.config/htop/htoprc"
  dotfiles config add htop
  watch_once
  on "$B"
  watch_once
  assert_file_content "$B/.config/htop/htoprc" 'fields=0 48'
  grep -q 'htop/htoprc' "$B/.config/mise/config.toml"
  # and B's later edits to it sync back
  printf 'fields=0 1\n' >"$B/.config/htop/htoprc"
  watch_once
  on "$A"
  watch_once
  assert_file_content "$A/.config/htop/htoprc" 'fields=0 1'
}

@test "a secret written after enrollment pauses publishing until it is gone from file and history" {
  on "$A"
  local before token
  before=$(git --git-dir="$ORIGIN" rev-parse main)
  token=$(fake_github_token)
  printf 'token = %s\n' "$token" >"$(jj_file "$A")"
  # the dotfiles-watch service runs this check every 15 seconds
  run dotfiles guard
  [ "$status" -ne 0 ]
  [[ "$output" == *"github-token"* ]]
  [[ "$output" != *"$token"* ]]
  # mise keeps saving locally, but nothing reaches the origin
  run watch_once
  [ "$(git --git-dir="$ORIGIN" rev-parse main)" = "$before" ]
  run dotfiles config status
  [[ "$output" == *"publishing is paused"* ]]
  run dotfiles config doctor
  [ "$status" -ne 0 ]
  # an explicit sync stays paused while the file holds the secret
  run dotfiles config sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"remove it from the file"* ]]
  # ... and while a saved checkpoint does
  printf 'clean\n' >"$(jj_file "$A")"
  run dotfiles config sync
  [ "$status" -ne 0 ]
  [[ "$output" == *"--replace-history"* ]]
  run dotfiles config adopt "$URL" --replace-history --yes
  [ "$status" -eq 0 ]
  assert_file_content "$(jj_file "$A")" clean
  run dotfiles config sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"publishing is active"* ]]
  [ "$(git --git-dir="$ORIGIN" show main:home/.config/jj/config.toml)" = clean ]
  # the secret never reached the origin
  ! git --git-dir="$ORIGIN" log -p --all | grep -q "$token"
  on "$B"
  watch_once
  assert_file_content "$(jj_file "$B")" clean
}

@test "a compromised origin's mise configuration is refused before it is applied" {
  # A pushes with plain mise, bypassing every dotfiles check
  on "$A"
  cat >>"$A/.config/mise/config.toml" <<'EOF'

[hooks]
enter = "touch ~/pwned-hook"

[history.reload]
"~/.config/jj/*" = "touch ~/pwned-reload"
EOF
  printf 'from a compromised origin\n' >"$(jj_file "$A")"
  mise dot save >/dev/null 2>&1
  mise dot sync >/dev/null 2>&1
  on "$B"
  run watch_once
  [ "$status" -ne 0 ]
  [[ "$output" == *"NOT applied"* ]]
  [[ "$output" == *"[hooks]"* && "$output" == *"[history.reload]"* ]]
  assert_file_content "$(jj_file "$B")" v1
  ! grep -q hooks "$B/.config/mise/config.toml"
  ! [ -e "$B/pwned-hook" ] && ! [ -e "$B/pwned-reload" ]
  run dotfiles config status
  [[ "$output" == *"incoming .configs changes were refused"* ]]
  run dotfiles config doctor
  [ "$status" -ne 0 ]
}

@test "the real services save and publish on their own, and again after a restart" {
  on "$A"
  local before
  before=$(git --git-dir="$ORIGIN" rev-parse main)
  start_services a1
  sleep 3
  printf 'by the watcher\n' >"$(jj_file "$A")"
  wait_for_push "$before" 90 || { cat "$BATS_TEST_TMPDIR"/*-a1.log >&2; return 1; }
  [ "$(git --git-dir="$ORIGIN" show main:home/.config/jj/config.toml)" = 'by the watcher' ]
  # the service manager restarts stopped services; nothing is lost meanwhile
  stop_services
  printf 'while stopped\n' >"$(jj_file "$A")"
  before=$(git --git-dir="$ORIGIN" rev-parse main)
  start_services a2
  wait_for_push "$before" 90 || { cat "$BATS_TEST_TMPDIR"/*-a2.log >&2; return 1; }
  [ "$(git --git-dir="$ORIGIN" show main:home/.config/jj/config.toml)" = 'while stopped' ]
  # and B's services apply it
  stop_services
  on "$B"
  start_services b
  local i=0
  until [ "$(cat "$(jj_file "$B")")" = 'while stopped' ]; do
    i=$((i + 1))
    [ $i -le 90 ] || { cat "$BATS_TEST_TMPDIR"/*-b.log >&2; return 1; }
    sleep 1
  done
}
