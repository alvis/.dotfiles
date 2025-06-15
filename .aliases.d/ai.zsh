# detect current shell
if [ -n "$ZSH_VERSION" ]; then
    _COPILOT_SHELL=zsh
elif [ -n "$BASH_VERSION" ]; then
    _COPILOT_SHELL=bash
else
    _COPILOT_SHELL=""
fi

# only proceed if gh & copilot extension exist, and shell is bash or zsh
if command -v gh >/dev/null 2>&1 &&
    gh extension list | grep -q '^gh copilot' &&
    { [ "$_COPILOT_SHELL" = "zsh" ] || [ "$_COPILOT_SHELL" = "bash" ]; }; then
    eval "$(gh copilot alias -- zsh)"

    alias '??'='ghcs'
    alias '?!'='ghce'
    alias 'gh?'='ghcs -t gh'
    alias 'git?'='ghcs -t git'

    COPILOT_TOOLS=(aws gcp docker)

    for tool in "${COPILOT_TOOLS[@]}"; do
        # the trailing space is deliberate so you can do: aws? check current deployed resources
        alias "${tool}?"="ghcs suggest a command using ${tool} for"
    done

else
    echo "WARN: github copilot cli extension not found or shell unsupported, skipping ??, ?!, <tool>? aliases" >&2
fi

