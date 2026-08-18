# shellcheck shell=bash
###############################################################################
# 00-config.sh — Group registry
# Builds the file→group registry and lookup helpers (one file = one group).
###############################################################################

# Globals populated by build_alias_group_registry
ALIAS_GROUP_ORDER=()
ALIAS_GROUP_KEYS=()
ALIAS_GROUP_MEMBERS=()
ALIAS_GROUP_FILES=()
ALIAS_HINT_LINES=""
ALIAS_REGISTRY_ROOT=""

# Set by alias_group_parse_header
_ag_header_group=""
_ag_header_keys=""

# -----------------------------------------------------------------------------
# _alias_group_slug_from_filename — Strip prefix/suffix from a group filename.
# -----------------------------------------------------------------------------
_alias_group_slug_from_filename()
{
    local filename="$1" base
    base="${filename%.sh}"
    case "$base" in
        [0-9][0-9]-*) base="${base#??-}" ;;
    esac
    case "$base" in
        *-aliases) base="${base%-aliases}" ;;
    esac
    printf '%s\n' "$base"
}

# -----------------------------------------------------------------------------
# _alias_group_titlecase_slug — Hyphenated slug → title-cased words.
# -----------------------------------------------------------------------------
_alias_group_titlecase_slug()
{
    local slug="$1" word first rest result="" old_ifs="$IFS"
    IFS='-'
    # Intentionally unquoted: split hyphenated slug into words.
    # shellcheck disable=SC2086
    set -- $slug
    IFS="$old_ifs"
    for word; do
        [ -n "$word" ] || continue
        first=$(printf '%s' "${word:0:1}" | tr '[:lower:]' '[:upper:]')
        rest=$(printf '%s' "${word:1}" | tr '[:upper:]' '[:lower:]')
        result="${result:+$result }${first}${rest}"
    done
    printf '%s\n' "$result"
}

# -----------------------------------------------------------------------------
# alias_group_default_name — Display name from filename.
# -----------------------------------------------------------------------------
alias_group_default_name()
{
    local slug
    slug="$(_alias_group_slug_from_filename "$1")"
    _alias_group_titlecase_slug "$slug"
}

# -----------------------------------------------------------------------------
# alias_group_default_keys — Comma-separated default key from filename slug.
# -----------------------------------------------------------------------------
alias_group_default_keys()
{
    local slug
    slug="$(_alias_group_slug_from_filename "$1")"
    printf '%s\n' "$(printf '%s' "$slug" | tr '[:upper:]' '[:lower:]')"
}

# -----------------------------------------------------------------------------
# alias_group_parse_header — Read # @group: / # @keys: from file top.
# Sets globals _ag_header_group, _ag_header_keys (empty if unset).
# -----------------------------------------------------------------------------
alias_group_parse_header()
{
    local file="$1" line rest
    local comment_re='^[[:space:]]*#(.*)$'
    _ag_header_group=""
    _ag_header_keys=""
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "${line//[[:space:]]/}" ] && continue
        if [[ "$line" =~ $comment_re ]]; then
            rest="${BASH_REMATCH[1]}"
        else
            break
        fi
        rest="${rest#"${rest%%[![:space:]]*}"}"
        case "$rest" in
            @group:*)
                rest="${rest#@group:}"
                rest="${rest#"${rest%%[![:space:]]*}"}"
                rest="${rest%"${rest##*[![:space:]]}"}"
                _ag_header_group="$rest"
                ;;
            @keys:*)
                rest="${rest#@keys:}"
                rest="${rest#"${rest%%[![:space:]]*}"}"
                rest="${rest%"${rest##*[![:space:]]}"}"
                _ag_header_keys="$rest"
                ;;
        esac
    done < "$file"
}

# -----------------------------------------------------------------------------
# alias_group_parse_members — Space-separated alias names from a group file.
# -----------------------------------------------------------------------------
alias_group_parse_members()
{
    local file="$1" line name result=""
    local alias_re='^[[:space:]]*alias[[:space:]]+([A-Za-z0-9_-]+)='
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ $alias_re ]]; then
            name="${BASH_REMATCH[1]}"
            result="${result:+$result }$name"
        fi
    done < "$file"
    printf '%s\n' "$result"
}

# -----------------------------------------------------------------------------
# alias_group_parse_hints — Lines of name<TAB>hint from # @hint + alias pairs.
# -----------------------------------------------------------------------------
alias_group_parse_hints()
{
    local file="$1" line hint="" name out="" rest
    local comment_re='^[[:space:]]*#(.*)$'
    local alias_re='^[[:space:]]*alias[[:space:]]+([A-Za-z0-9_-]+)='
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ $comment_re ]]; then
            rest="${BASH_REMATCH[1]}"
            rest="${rest#"${rest%%[![:space:]]*}"}"
            case "$rest" in
                @hint|@hint[[:space:]]*)
                    hint="${rest#@hint}"
                    hint="${hint#"${hint%%[![:space:]]*}"}"
                    hint="${hint%"${hint##*[![:space:]]}"}"
                    ;;
            esac
        elif [[ "$line" =~ $alias_re ]]; then
            name="${BASH_REMATCH[1]}"
            if [ -n "$hint" ]; then
                out="${out}${out:+$'\n'}$name$(printf '\t')$hint"
                hint=""
            fi
        fi
    done < "$file"
    printf '%s\n' "$out"
}

# -----------------------------------------------------------------------------
# bash_alias_dir — Directory of group files (override with BASH_ALIAS_DIR).
# -----------------------------------------------------------------------------
bash_alias_dir()
{
    printf '%s\n' "${BASH_ALIAS_DIR:-$HOME/.bash/aliases}"
}

bash_alias_core_dir()
{
    printf '%s\n' "$(bash_alias_dir)/core"
}

bash_alias_custom_dir()
{
    printf '%s\n' "$(bash_alias_dir)/custom"
}

# Return 0 if $1 is under the core aliases directory.
alias_path_is_under_core()
{
    local file="$1" core
    core="${ALIAS_REGISTRY_ROOT:-$(bash_alias_dir)}/core"
    case "$file" in
        "$core"/*) return 0 ;;
        *) return 1 ;;
    esac
}

# Scan one subdirectory for 20–99 group files; append to registry arrays.
_alias_group_registry_scan_dir()
{
    local dir="$1" f base name keys members hint_lines i duplicate_index
    [ -d "$dir" ] || return 0
    for f in "$dir"/*.sh; do
        [ -r "$f" ] || continue
        base="$(basename "$f")"
        case "$base" in
            [2-9][0-9]-*.sh) ;;
            *) continue ;;
        esac

        _ag_header_group=""
        _ag_header_keys=""
        alias_group_parse_header "$f"
        name="${_ag_header_group:-$(alias_group_default_name "$base")}"
        keys="${_ag_header_keys:-$(alias_group_default_keys "$base")}"
        members="$(alias_group_parse_members "$f")"

        duplicate_index=""
        for i in "${!ALIAS_GROUP_ORDER[@]}"; do
            if [ "${ALIAS_GROUP_ORDER[$i]}" = "$name" ]; then
                duplicate_index="$i"
                break
            fi
        done
        if [ -n "$duplicate_index" ]; then
            echo "⚠️  Duplicate alias group '$name'; using later file: $f" >&2
            ALIAS_GROUP_KEYS[duplicate_index]="$keys"
            ALIAS_GROUP_MEMBERS[duplicate_index]="$members"
            ALIAS_GROUP_FILES[duplicate_index]="$f"
        else
            ALIAS_GROUP_ORDER+=("$name")
            ALIAS_GROUP_KEYS+=("$keys")
            ALIAS_GROUP_MEMBERS+=("$members")
            ALIAS_GROUP_FILES+=("$f")
        fi

        hint_lines="$(alias_group_parse_hints "$f")"
        if [ -n "$hint_lines" ]; then
            ALIAS_HINT_LINES="${ALIAS_HINT_LINES}${ALIAS_HINT_LINES:+$'\n'}${hint_lines}"
        fi
    done
}

# -----------------------------------------------------------------------------
# build_alias_group_registry — Scan core/ then custom/ under aliases root.
# -----------------------------------------------------------------------------
build_alias_group_registry()
{
    local root="$1"
    ALIAS_REGISTRY_ROOT="$root"
    ALIAS_GROUP_ORDER=()
    ALIAS_GROUP_KEYS=()
    ALIAS_GROUP_MEMBERS=()
    ALIAS_GROUP_FILES=()
    ALIAS_HINT_LINES=""

    _alias_group_registry_scan_dir "$root/core"
    _alias_group_registry_scan_dir "$root/custom"
}

# -----------------------------------------------------------------------------
# group_keys — Comma-separated filter tokens for a canonical group name.
# -----------------------------------------------------------------------------
group_keys()
{
    local i
    for i in "${!ALIAS_GROUP_ORDER[@]}"; do
        if [ "${ALIAS_GROUP_ORDER[$i]}" = "$1" ]; then
            printf '%s\n' "${ALIAS_GROUP_KEYS[$i]}"
            return 0
        fi
    done
}

# -----------------------------------------------------------------------------
# group_members — Space-separated alias names for a canonical group name.
# -----------------------------------------------------------------------------
group_members()
{
    local i
    for i in "${!ALIAS_GROUP_ORDER[@]}"; do
        if [ "${ALIAS_GROUP_ORDER[$i]}" = "$1" ]; then
            printf '%s\n' "${ALIAS_GROUP_MEMBERS[$i]}"
            return 0
        fi
    done
}

# -----------------------------------------------------------------------------
# resolve_group_name — Map a user token to a canonical group name.
# -----------------------------------------------------------------------------
resolve_group_name()
{
    local token lowered g k i
    token="$1"
    lowered=$(printf '%s' "$token" | tr '[:upper:]' '[:lower:]')
    for i in "${!ALIAS_GROUP_ORDER[@]}"; do
        g="${ALIAS_GROUP_ORDER[$i]}"
        IFS=, read -r -a keys <<<"${ALIAS_GROUP_KEYS[$i]}"
        for k in "${keys[@]}"; do
            k=$(printf '%s' "$k" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ "$lowered" = "$k" ]; then
                printf '%s\n' "$g"
                return 0
            fi
        done
    done
    return 1
}

# -----------------------------------------------------------------------------
# classify_group — Return the group containing an alias, or empty if unknown.
# -----------------------------------------------------------------------------
classify_group()
{
    local name="$1" i members
    for i in "${!ALIAS_GROUP_ORDER[@]}"; do
        members="${ALIAS_GROUP_MEMBERS[$i]}"
        case " $members " in
            *" $name "*) printf '%s\n' "${ALIAS_GROUP_ORDER[$i]}"; return 0 ;;
        esac
    done
    printf '\n'
    return 1
}

# -----------------------------------------------------------------------------
# alias_hint_for — Hint text for an alias, or empty if none.
# -----------------------------------------------------------------------------
alias_hint_for()
{
    local name="$1" line
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        case "$line" in
            "$name"$'\t'*) printf '%s\n' "${line#*$'\t'}"; return 0 ;;
        esac
    done <<EOF
$ALIAS_HINT_LINES
EOF
}

# -----------------------------------------------------------------------------
# alias_quote_single — Escape a string for use inside single-quoted alias values.
# -----------------------------------------------------------------------------
alias_quote_single()
{
    printf '%s' "$1" | sed "s/'/'\\\\''/g"
}

# -----------------------------------------------------------------------------
# alias_format_line — Emit: alias name='escaped-command'
# -----------------------------------------------------------------------------
alias_format_line()
{
    local name="$1" cmd="$2"
    printf "alias %s='%s'\n" "$name" "$(alias_quote_single "$cmd")"
}

# -----------------------------------------------------------------------------
# alias_is_hint_line — 0 if line is a # @hint directive (optional indent).
# -----------------------------------------------------------------------------
alias_is_hint_line()
{
    local line="$1" rest
    case "$line" in
        \#*|[[:space:]]\#*) ;;
        *) return 1 ;;
    esac
    rest="${line#*\#}"
    rest="${rest#"${rest%%[![:space:]]*}"}"
    case "$rest" in
        @hint|@hint[[:space:]]*) return 0 ;;
    esac
    return 1
}

# -----------------------------------------------------------------------------
# alias_group_file_for_name — Path of the group file that defines an alias.
# -----------------------------------------------------------------------------
alias_group_file_for_name()
{
    local name="$1" i members
    for i in "${!ALIAS_GROUP_ORDER[@]}"; do
        members="${ALIAS_GROUP_MEMBERS[$i]}"
        case " $members " in
            *" $name "*) printf '%s\n' "${ALIAS_GROUP_FILES[$i]}"; return 0 ;;
        esac
    done
    return 1
}

# -----------------------------------------------------------------------------
# alias_group_file_for_canonical — Path for a canonical group display name.
# -----------------------------------------------------------------------------
alias_group_file_for_canonical()
{
    local i
    for i in "${!ALIAS_GROUP_ORDER[@]}"; do
        if [ "${ALIAS_GROUP_ORDER[$i]}" = "$1" ]; then
            printf '%s\n' "${ALIAS_GROUP_FILES[$i]}"
            return 0
        fi
    done
    return 1
}

# -----------------------------------------------------------------------------
# alias_next_group_nn — Next free numeric prefix in 20–89 (prefer tens).
# -----------------------------------------------------------------------------
alias_next_group_nn()
{
    local dir="$1" used="" f n
    for f in "$dir"/[2-9][0-9]-*.sh; do
        [ -e "$f" ] || continue
        n=$(basename "$f")
        n=${n%%-*}
        used="$used $n"
    done
    for n in 20 30 40 50 60 70 80; do
        case " $used " in
            *" $n "*) continue ;;
        esac
        printf '%s\n' "$n"
        return 0
    done
    n=21
    while [ "$n" -le 89 ]; do
        case " $used " in
            *" $n "*) ;;
            *) printf '%s\n' "$n"; return 0 ;;
        esac
        n=$((n + 1))
    done
    return 1
}

# -----------------------------------------------------------------------------
# alias_slugify — Lowercase hyphenated slug for new group files.
# -----------------------------------------------------------------------------
alias_slugify()
{
    printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | tr -cs 'a-z0-9' '-' \
        | sed 's/^-//;s/-$//'
}

# -----------------------------------------------------------------------------
# alias_create_group_file — Create NN-slug.sh with header; print path.
# -----------------------------------------------------------------------------
alias_create_group_file()
{
    local dir="$1" raw_slug="$2" nn slug title path
    nn=$(alias_next_group_nn "$dir") || {
        echo "❌ No free group prefix left under $dir (20–89)." >&2
        return 1
    }
    slug=$(alias_slugify "$raw_slug")
    if [ -z "$slug" ]; then
        echo "❌ Invalid group slug: $raw_slug" >&2
        return 1
    fi
    title=$(alias_group_default_name "${nn}-${slug}.sh")
    path="$dir/${nn}-${slug}.sh"
    if [ -e "$path" ]; then
        echo "❌ Group file already exists: $path" >&2
        return 1
    fi
    {
        printf '%s\n' "###############################################################################"
        printf '%s\n' "# ${nn}-${slug}.sh — ${title}"
        printf '%s\n' "# Aliases for the ${title} group."
        printf '%s\n' "###############################################################################"
        printf '\n'
        printf '%s\n' "# @group: ${title}"
        printf '%s\n' "# @keys: ${slug}"
        printf '\n'
    } >"$path"
    printf '%s\n' "$path"
}

# -----------------------------------------------------------------------------
# alias_append_to_file — Append an alias line to a group file.
# -----------------------------------------------------------------------------
alias_append_to_file()
{
    local file="$1" name="$2" cmd="$3"
    alias_format_line "$name" "$cmd" >>"$file"
}

# -----------------------------------------------------------------------------
# alias_replace_in_file — Replace the definition line for name (keep @hint).
# -----------------------------------------------------------------------------
alias_replace_in_file()
{
    local file="$1" name="$2" cmd="$3" tmp line replaced=0
    tmp=$(mktemp) || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+${name}= ]]; then
            alias_format_line "$name" "$cmd" >>"$tmp"
            replaced=1
        else
            printf '%s\n' "$line" >>"$tmp"
        fi
    done <"$file"
    if [ "$replaced" -ne 1 ]; then
        rm -f "$tmp"
        return 1
    fi
    mv "$tmp" "$file"
}

# -----------------------------------------------------------------------------
# alias_remove_from_file — Remove alias line and its preceding @hint (if any).
# -----------------------------------------------------------------------------
alias_remove_from_file()
{
    local file="$1" name="$2" tmp line pending="" removed=0
    tmp=$(mktemp) || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+${name}= ]]; then
            pending=""
            removed=1
            continue
        fi
        if [ -n "$pending" ]; then
            printf '%s\n' "$pending" >>"$tmp"
            pending=""
        fi
        if alias_is_hint_line "$line"; then
            pending="$line"
        else
            printf '%s\n' "$line" >>"$tmp"
        fi
    done <"$file"
    if [ -n "$pending" ]; then
        printf '%s\n' "$pending" >>"$tmp"
    fi
    if [ "$removed" -ne 1 ]; then
        rm -f "$tmp"
        return 1
    fi
    mv "$tmp" "$file"
}

# ===================================== EOF ====================================
