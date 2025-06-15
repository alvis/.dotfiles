# download a file with wget
if command -v wget >/dev/null 2>&1; then
    alias download="wget --continue --tries=0 --read-timeout=30 --random-wait" # removed --debug for general use, it's very verbose
elif command -v curl >/dev/null 2>&1; then
    alias download="curl -O -C - -L"
else
    echo "WARN: wget and curl not found, download alias will not work"
fi

