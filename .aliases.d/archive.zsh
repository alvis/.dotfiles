# archive and unarchive functions with rar/zip fallback + optional GPG encryption + sha-256

# 1) detect available tools
typeset -A HAS
for cmd in rar zip unzip gpg; do
    if command -v $cmd &>/dev/null; then
        HAS[$cmd]=1
    else
        HAS[$cmd]=0
        echo >&2 "WARN: '$cmd' not found. Install via: brew install $cmd"
    fi
done

# 2) helper: generate checksum file
_make_checksum() {
    local file=$1
    local dir
    dir=$(dirname -- "$file")
    local base
    base=$(basename -- "$file")
    base=${base%.*}
    shasum -a 256 "$file" >"${dir}/${base}.sha256"
}

# 3) archive(): [-s] | [-r RECIPIENT] | [-m zip|rar] <src> [out]
archive() {
    local OPTIND opt mode=none recipient method
    while getopts "sr:m:" opt; do
        case $opt in
        s) mode=sym ;;
        r)
            mode=pub
            recipient=$OPTARG
            ;;
        m)
            if [[ $OPTARG == rar || $OPTARG == zip ]]; then
                method=$OPTARG
            else
                echo >&2 "Error: -m must be 'rar' or 'zip'"
                return 1
            fi
            ;;
        *)
            echo >&2 "Usage: archive [-s|-r RECIPIENT] [-m zip|rar] <src> [out]"
            return 1
            ;;
        esac
    done
    shift $((OPTIND - 1))

    local src=$1 dst dst_given=0 arch_method ext target_ext base final tmp
    [[ -z $src ]] && {
        echo >&2 "Usage: archive [-s|-r RECIPIENT] [-m zip|rar] <src> [out]"
        return 1
    }

    if [[ -n $2 ]]; then
        dst=$2
        dst_given=1
    fi

    # 3a) decide archive method
    if [[ $dst_given -eq 1 ]]; then
        # strip .gpg if present
        if [[ $dst == *.gpg ]]; then
            target_ext=${dst%.gpg}
            target_ext=${target_ext##*.}
        else
            target_ext=${dst##*.}
        fi
        if [[ -n $method ]]; then
            arch_method=$method
        else
            case $target_ext in rar | zip) arch_method=$target_ext ;;
            *) arch_method=rar ;;
            esac
        fi
    else
        arch_method=${method:-rar}
    fi

    # fallback if tool missing
    if [[ $arch_method == rar && ${HAS[rar]} -eq 0 ]]; then
        ((HAS[zip])) && arch_method=zip || {
            echo >&2 "Error: no rar or zip available"
            return 1
        }
    fi
    if [[ $arch_method == zip && ${HAS[zip]} -eq 0 ]]; then
        ((HAS[rar])) && arch_method=rar || {
            echo >&2 "Error: no rar or zip available"
            return 1
        }
    fi

    # 3b) build tmp archive name + final name
    if [[ $mode != none || ($dst_given -eq 1 && $dst == *.gpg) ]]; then
        # encryption requested or implied by .gpg
        if [[ $dst_given -eq 1 ]]; then
            final=$dst
            tmp=${dst%.tmp}
        else
            tmp=${src%/}.${arch_method}
            final=${tmp}.gpg
        fi
    else
        # no encryption
        if [[ $dst_given -eq 1 ]]; then final=$dst; else final=${src%/}.${arch_method}; fi
        tmp=$final
    fi

    # 3c) create archive
    case $arch_method in
    rar)
        echo "Archiving → $tmp"
        rar a -rr10% -tsma -idn -t "$tmp" "$src" || {
            rm -f "$tmp"
            return 1
        }
        ;;
    zip)
        echo "Archiving → $tmp"
        zip -r "$tmp" "$src" || {
            rm -f "$tmp"
            return 1
        }
        ;;
    esac

    # 4) optional GPG encryption
    if [[ $mode != none || $final == *.gpg ]]; then
        ((HAS[gpg])) || {
            echo >&2 "Error: gpg not installed"
            rm -f "$tmp"
            return 1
        }
        echo "Encrypting → $final"
        if [[ $mode == sym ]] || { [[ $mode == none ]] && [[ $final == *.gpg ]]; }; then
            gpg --batch --yes --symmetric --cipher-algo AES256 -o "$final" "$tmp"
        else
            gpg --batch --yes --encrypt --recipient "$recipient" -o "$final" "$tmp"
        fi
        if [[ $? -ne 0 ]]; then
            echo >&2 "Error: Encryption failed"
            rm -f "$final" "$tmp"
            return 1
        fi
        rm -f "$tmp"
        _make_checksum "$final"
        echo "✅ Encrypted + SHA256 → $final"
    else
        _make_checksum "$final"
        echo "✅ Archive + SHA256 → $final"
    fi
}

# 5) unarchive(): out
unarchive() {
    local infile="$1" workfile tmp ext mime base sha
    [[ -z $infile ]] && {
        echo >&2 "Usage: unarchive <archive_file>"
        return 1
    }

    workfile="$infile"

    # 1) detect & decrypt GPG-encrypted archives (OpenPGP packets)
    if gpg --batch --list-packets "$infile" 2>&1 | grep -q 'encrypted data packet'; then
        echo "🔒 Encrypted archive detected: decrypting…"
        tmp="$(mktemp)"
        if ! gpg --decrypt --output "$tmp" "$infile"; then
            echo >&2 "Error: decryption failed"
            rm -f "$tmp"
            return 1
        fi
        workfile="$tmp"
    fi

    # 2) verify SHA256 if a .sha256 exists next to the original (infile)
    base="${infile%.*}"
    sha="${base}.sha256"
    if [[ -f $sha ]]; then
        echo "🔍 Verifying SHA256…"
        if ! shasum -a 256 -c "$sha"; then
            read -q "?SHA mismatch. Continue anyway? (y/N) " yn
            echo
            [[ $yn != [Yy] ]] && {
                echo "Aborted"
                [[ -n $tmp ]] && rm -f "$tmp"
                return 1
            }
            echo "⚠️ Proceeding despite mismatch"
        fi
    else
        echo "⚠️ No SHA256 file found. Skipping verification"
    fi

    # 3) determine format by MIME (fallback to magic bytes)
    mime=$(file --brief --mime-type "$workfile")
    case "$mime" in
    application/zip) ext=zip ;;
    application/x-rar*) ext=rar ;;
    *)
        # fallback on signatures
        if head -c 6 "$workfile" | grep -q 'Rar!\|Rar \x1A'; then
            ext=rar
        elif head -c 4 "$workfile" | grep -q 'PK..'; then
            ext=zip
        else
            echo >&2 "Error: unknown archive format"
            [[ -n $tmp ]] && rm -f "$tmp"
            return 1
        fi
        ;;
    esac

    # 4) integrity test + extraction
    if [[ $ext == rar ]]; then
        ((HAS[rar])) || {
            echo >&2 "Error: 'rar' not installed"
            [[ -n $tmp ]] && rm -f "$tmp"
            return 1
        }
        echo "🧪 Testing RAR integrity…"
        if ! rar t "$workfile" >/dev/null; then
            echo >&2 "Error: corrupt RAR"
            [[ -n $tmp ]] && rm -f "$tmp"
            return 1
        fi
        echo "⏳ Extracting RAR…"
        rar x -idn "$workfile" || {
            echo >&2 "Error: RAR extraction failed"
            [[ -n $tmp ]] && rm -f "$tmp"
            return 1
        }
    else # zip
        ((HAS[unzip])) || {
            echo >&2 "Error: 'unzip' not installed"
            [[ -n $tmp ]] && rm -f "$tmp"
            return 1
        }
        echo "🧪 Testing ZIP integrity…"
        if ! unzip -tq "$workfile"; then
            echo >&2 "Error: corrupt ZIP"
            [[ -n $tmp ]] && rm -f "$tmp"
            return 1
        fi
        echo "⏳ Extracting ZIP…"
        unzip "$workfile" || {
            echo >&2 "Error: ZIP extraction failed"
            [[ -n $tmp ]] && rm -f "$tmp"
            return 1
        }
    fi

    echo "✅ Unarchived successfully"

    # 5) cleanup temp decrypted copy
    [[ -n $tmp ]] && rm -f "$tmp"
}

# 6) tab‐completion
_archive_comp() {
    local state ret
    local -a comps

    # define flags and positional specs; on match return
    _arguments -C \
        '-s[encrypt symmetrically]' \
        '-r+[encrypt to recipient]:recipient:' \
        '-m+[compression method]:method:(rar zip)' \
        '1:source file or directory:_files' \
        '2:destination archive:->dest' && return

    # handle 'dest' state for second positional
    if [[ $state == dest ]]; then
        local src_word base i

        # walk through words[2] .. words[CURRENT-1], skipping flags and their args
        for ((i = 2; i < CURRENT; i++)); do
            case "${words[i]}" in
            -r | -m) ((i++)) ;; # skip the next token (the flag-arg)
            -*)                 # any other flag (e.g. -s)
                continue
                ;;
            *)
                src_word=${words[i]} # record the last non-flag token
                ;;
            esac
        done

        # if we didn't find anything, fall back to empty
        [[ -z $src_word ]] && src_word=""

        # strip any trailing slash and strip any existing extension
        base=${src_word%/}
        base=${base%.*}

        comps=("${base}.rar" "${base}.zip")

        # if encryption was requested anywhere, offer .gpg too
        if [[ " ${words[*]} " == *" -s "* ]] || [[ " ${words[*]} " == *" -r "* ]]; then
            comps+=("${base}.rar.gpg" "${base}.zip.gpg")
        fi

        _describe 'archives' comps && return
    fi

    return 1
}
compdef _archive_comp archive

_unarchive_comp() { _files -g '*.(rar|zip)(.gpg|)'; }
compdef _unarchive_comp unarchive

