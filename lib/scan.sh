# shellcheck shell=bash
#
# Secret scan for files about to enter .configs history, and for the history
# itself before its first publication. The rules are deliberately simple and
# auditable; they complement mise's own credential-name filter and do not
# replace a dedicated scanner. When gitleaks is installed it runs as well.

# extended regular expressions, one per line: <rule id> <tab> <pattern>
secret_rules() {
  cat <<'EOF'
private-key	-----BEGIN ([A-Z0-9]+ )?PRIVATE KEY( BLOCK)?-----
aws-access-key	(^|[^A-Z0-9])(AKIA|ASIA)[A-Z0-9]{16}([^A-Z0-9]|$)
aws-secret	aws_secret_access_key[[:space:]]*=[[:space:]]*[A-Za-z0-9/+=]{30,}
github-token	(^|[^A-Za-z0-9_])(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})
gitlab-token	glpat-[A-Za-z0-9_-]{20,}
slack-token	xox[abpors]-[A-Za-z0-9-]{10,}
slack-webhook	hooks\.slack\.com/services/[A-Za-z0-9/]{20,}
google-api-key	AIza[0-9A-Za-z_-]{35}
stripe-key	(sk|rk)_live_[0-9A-Za-z]{20,}
npm-token	(_authToken|npm_[A-Za-z0-9]{36})
openai-key	sk-(proj-)?[A-Za-z0-9_-]{32,}
anthropic-key	sk-ant-[A-Za-z0-9_-]{32,}
jwt	eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}
basic-auth-url	[a-z][a-z0-9+.-]*://[^/[:space:]:@]+:[^/[:space:]@]+@
assignment	(api[_-]?key|secret|passw(or)?d|access[_-]?token|auth[_-]?token|refresh[_-]?token|oauth[_-]?token|client[_-]?secret)["']?[[:space:]]*[:=][[:space:]]*["']?[^[:space:]"']{16,}
password	passw(or)?d["']?[[:space:]]*[:=][[:space:]]*["']?[^[:space:]"']{8,}
bearer	[Bb]earer[[:space:]]+[A-Za-z0-9._~+/=-]{20,}
EOF
}

# scan_stream <label>: read text on stdin, print "<label>: <rule>" per finding
scan_stream() {
  local label=$1 text rule pattern
  text=$(LC_ALL=C tr -d '\000')
  while IFS="$(printf '\t')" read -r rule pattern; do
    [ -n "$rule" ] || continue
    if printf '%s\n' "$text" | LC_ALL=C grep -Eiq -- "$pattern"; then
      printf '%s: %s\n' "$label" "$rule"
    fi
  done <<EOF
$(secret_rules)
EOF
}

# text form of a file for scanning: binary plists are converted to XML
scan_text_of() {
  local file=$1
  case $file in
  *.plist)
    if command -v plutil >/dev/null 2>&1; then
      plutil -convert xml1 -o - -- "$file" 2>/dev/null && return 0
    fi
    ;;
  esac
  cat -- "$file"
}

# scan_files <path>...: scan files and directories; prints findings, returns 1 on any
scan_files() {
  local found=0 path file out
  for path in "$@"; do
    [ -e "$path" ] || continue
    if [ -d "$path" ]; then
      while IFS= read -r file; do
        out=$(scan_text_of "$file" | scan_stream "$(tilde_path "$file")")
        [ -z "$out" ] || {
          printf '%s\n' "$out"
          found=1
        }
      done <<EOF
$(find "$path" -type f -not -path '*/.git/*' 2>/dev/null)
EOF
    else
      out=$(scan_text_of "$path" | scan_stream "$(tilde_path "$path")")
      [ -z "$out" ] || {
        printf '%s\n' "$out"
        found=1
      }
    fi
  done
  if [ $found = 0 ] && command -v gitleaks >/dev/null 2>&1; then
    for path in "$@"; do
      [ -e "$path" ] || continue
      gitleaks dir --no-banner --redact --exit-code 1 -- "$path" >/dev/null 2>&1 || {
        printf '%s: gitleaks\n' "$(tilde_path "$path")"
        found=1
      }
    done
  fi
  return $found
}

# scan_history <bare git dir>: scan every blob reachable from any ref.
# Status: 0 clean, 1 findings, 2 the history could not be read (fail closed).
scan_history() {
  local git_dir=$1 found=0 type oid path out tmp objects
  [ -d "$git_dir" ] || return 2
  tmp=$(mktemp "${TMPDIR:-/tmp}/dotfiles-scan.XXXXXX") || return 2
  objects=$(git --git-dir="$git_dir" rev-list --objects --all 2>/dev/null |
    git --git-dir="$git_dir" cat-file --batch-check='%(objecttype) %(objectname) %(rest)' 2>/dev/null) || {
    rm -f "$tmp"
    return 2
  }
  while read -r type oid path; do
    [ "$type" = blob ] || continue
    case $path in
    .mise-history/*) continue ;;
    esac
    git --git-dir="$git_dir" cat-file blob "$oid" >"$tmp" 2>/dev/null || continue
    if [ "$(LC_ALL=C head -c 6 "$tmp")" = bplist ]; then
      out=$(plutil -convert xml1 -o - -- "$tmp" 2>/dev/null | scan_stream "history:$path")
    else
      out=$(scan_stream "history:$path" <"$tmp")
    fi
    [ -z "$out" ] || {
      printf '%s\n' "$out"
      found=1
    }
  done <<EOF
$objects
EOF
  rm -f "$tmp"
  return $found
}
