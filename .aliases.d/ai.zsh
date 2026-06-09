# check if copilot is installed
if ! command -v copilot >/dev/null 2>&1; then
    echo "WARN: 'copilot' not found -> run: brew install copilot-cli" >&2
    return  # or exit if in a script
fi

# creates a suggestion function for a given tool/context
make_copilot_helper() {
    local tool_name="$1"          # e.g. "aws", "docker", "general"
    local allowed_tool="$2"       # e.g. "shell(aws)", "shell", "shell(git)"
    local prompt_prefix="$3"      # optional custom prefix, defaults sensibly
    local helper_name             # generated helper function name

    case "$tool_name" in
        general) helper_name="??" ;;
        explain) helper_name="?" ;;
        *) helper_name="${tool_name}?" ;;
    esac

    # default prompt prefix if not provided
    [ -z "$prompt_prefix" ] && {
        if [ "$tool_name" = "general" ]; then
            prompt_prefix="Suggest or run a shell command for"
        else
            prompt_prefix="Suggest or run a command using ${tool_name} for"
        fi
    }

    # define the function dynamically
    eval "
        '${helper_name}'() {
            local input=\"\$*\"
            [ -z \"\$input\" ] && { echo \"Usage: ${helper_name} your question here\"; return 1; }
            copilot -i \"${prompt_prefix}: \$input\" --allow-tool \"${allowed_tool}\"
        }
    "
}

# ── Create the helpers ──────────────────────────────────────────

# general shell suggestions       →   ?? list files recursively by size
make_copilot_helper "general" "shell"

# explain anything                 →   ?! kubectl describe pod my-pod
make_copilot_helper "explain" "shell" "explain this command or error"

# Tool-specific helpers (add more as needed)
make_copilot_helper "git"     "shell(git)"
make_copilot_helper "gh"      "shell(gh)"
make_copilot_helper "aws"     "shell(aws)"
make_copilot_helper "docker"  "shell(docker)"
make_copilot_helper "kubectl" "shell(kubectl)"
make_copilot_helper "terraform" "shell(terraform)"
make_copilot_helper "ansible" "shell(ansible)"
make_copilot_helper "gcp"     "shell(gcloud)"   # or "shell(gcp)" if using gcp alias
make_copilot_helper "helm"    "shell(helm)"

# last-command explainer for zsh (avoid !! because zsh expands it before function lookup)
?!() {
    local last_cmd
    # Read recent history and skip helper commands themselves.
    last_cmd="$(
        fc -ln -20 2>/dev/null \
            | sed -e 's/^[[:space:]]*//' -e '/^$/d' \
            | grep -Ev '^(last\?|\?!!)([[:space:]]|$)' \
            | tail -n 1
    )"

    if [ -z "$last_cmd" ]; then
        echo "WARN: no previous command found in history" >&2
        return 1
    fi

    copilot -sp "explain this shell command and likely error/output: ${last_cmd}" --allow-tool "shell"
}

# ── Usage examples ──────────────────────────────────────────────
# ?? "find largest files in current dir"
# aws? "list all S3 buckets in us-east-1"
# docker? "remove all stopped containers and dangling images"
# git? "undo last commit but keep changes staged"
# ?! "git rebase -i HEAD~5"
# last?   # after a command fails
