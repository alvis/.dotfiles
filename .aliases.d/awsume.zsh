# assume aws role with `assume <profile>`
if command -v awsume >/dev/null 2>&1; then
    alias assume=". awsume"
elif [[ $OSTYPE == darwin* ]]; then # the blueprint installs awsume on macOS only
    echo "WARN: awsume not found, install with: brew install awsume" >&2
fi

