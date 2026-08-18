# shellcheck shell=bash
###############################################################################
# 10-functions.sh — Core helper functions
# Alias-management implementations for list/add/edit/delete/check helpers.
###############################################################################

# -----------------------------------------------------------------------------
# list_aliases_wrapper — Pretty list of aliases by group (optional filter)
# -----------------------------------------------------------------------------
list_aliases_wrapper()
{
    local filter_group=""
    if [ $# -ge 1 ]; then
        # Map user token (e.g., "git") to canonical group name ("Git")
        if ! filter_group="$(resolve_group_name "$1")"; then
            echo "❌ Unknown group '$1'"
            list_alias_groups_wrapper
            return 1
        fi
    fi

    # Collect aliases as sorted "name=cmd" lines
    local lines
    # Only match single-line aliases of the form: alias name='value'
    lines="$(alias -p | sed -nE "s/^alias ([^=]+)='([^']*)'$/\1=\2/p" | sort)"

    # Table formatting
    echo
    local rule_left="----------------------------------------"
    local rule_right="------------------------------------------------------------"

    local printed_any=0

    # Iterate over canonical groups in configured order
    for group in "${ALIAS_GROUP_ORDER[@]}"; do
        # Apply optional group filter
        if [ -n "$filter_group" ] && [ "$group" != "$filter_group" ]; then
            continue
        fi

        # Group header
        printf "%-40s-+-%s\n" "$rule_left" "$rule_right"
        printf "%-40s | %s\n" "Alias group: $group" "Alias command"
        printf "%-40s-+-%s\n" "$rule_left" "$rule_right"

        # Walk each alias (name=cmd) and render those that belong to this group
        while IFS='=' read -r name cmd; do
            # Skip self to avoid recursive/awkward display
            case "$name" in
                list_aliases_wrapper|list-aliases) continue ;;
            esac

            # Determine alias' group
            local g
            if ! g="$(classify_group "$name")"; then
                continue
            fi
            [ "$g" != "$group" ] && continue

            # Parameter hints from the group registry
            local display="$name" hint
            hint="$(alias_hint_for "$name")"
            if [ -n "$hint" ]; then
                display="$name $hint"
            fi

            printf "%-40s | %s\n" "$display" "$cmd"
            printed_any=1
        done <<EOF
$lines
EOF

        # Group footer separator
        printf "%-40s-+-%s\n" "$rule_left" "$rule_right"
        echo
    done

    # If a filter was supplied but nothing matched, tell the user
    if [ -n "$filter_group" ] && [ $printed_any -eq 0 ]; then
        echo "ℹ️  No aliases found for group: $filter_group"
    fi
}

# -----------------------------------------------------------------------------
# list_alias_groups_wrapper — List available groups and their filter tokens
# -----------------------------------------------------------------------------
list_alias_groups_wrapper()
{
    echo
    echo "Available alias groups (use with: list-aliases <group>)"
    echo
    local g keys
    for g in "${ALIAS_GROUP_ORDER[@]}"; do
        keys="$(group_keys "$g")"
        printf "  • %-17s (keys: %s)\n" "$g" "$keys"
    done
    echo
    echo "Examples:"
    echo "  list-aliases"
    echo "  list-aliases git"
    echo "  list-aliases alias"
    echo "  list-aliases other"
    echo
}

# -----------------------------------------------------------------------------
# _alias_mgmt_define — Define an alias in the current session
# -----------------------------------------------------------------------------
_alias_mgmt_define()
{
    local name="$1" cmd="$2"
    eval "alias ${name}=$(printf '%q' "$cmd")"
}

# -----------------------------------------------------------------------------
# _alias_mgmt_refresh_registry — Rebuild registry from BASH_ALIAS_DIR
# -----------------------------------------------------------------------------
_alias_mgmt_refresh_registry()
{
    build_alias_group_registry "$(bash_alias_dir)"
}

# -----------------------------------------------------------------------------
# add_alias_wrapper — Append an alias to a group file (create group if needed)
# -----------------------------------------------------------------------------
add_alias_wrapper()
{
    if [ $# -lt 3 ]; then
        echo "❌ Usage: add-alias <group> <name> <command...>"
        return 1
    fi

    local group_token="$1" name="$2"
    shift 2
    local cmd="$*" root dir canonical file

    root="$(bash_alias_dir)"
    if [ ! -d "$root" ]; then
        echo "❌ Alias directory not found: $root"
        return 1
    fi
    dir="$root/custom"
    if ! mkdir -p "$dir"; then
        echo "❌ Could not create custom alias directory: $dir"
        return 1
    fi

    case "$name" in
        *[!A-Za-z0-9_-]*|"")
            echo "❌ Invalid alias name: $name"
            return 1
            ;;
    esac

    if alias "$name" >/dev/null 2>&1 || alias_group_file_for_name "$name" >/dev/null 2>&1; then
        echo "❌ Alias '$name' already exists. Use edit-alias to change it."
        return 1
    fi

    if canonical="$(resolve_group_name "$group_token" 2>/dev/null)"; then
        file="$(alias_group_file_for_canonical "$canonical")" || {
            echo "❌ Resolved group '$canonical' but no file is registered."
            return 1
        }
        if alias_path_is_under_core "$file"; then
            echo "❌ Group '$canonical' is in core/ and cannot be modified. Add a new group under custom/ instead."
            return 1
        fi
    else
        echo "📁 Creating new group from slug '$group_token'..."
        file="$(alias_create_group_file "$dir" "$group_token")" || return 1
        echo "   → $file"
    fi

    alias_append_to_file "$file" "$name" "$cmd" || return 1
    _alias_mgmt_define "$name" "$cmd"
    _alias_mgmt_refresh_registry

    echo "✅ Added alias $name → $cmd"
    echo "   Group file: $file"
}

# -----------------------------------------------------------------------------
# edit_alias_wrapper — Change an alias command in its group file
# -----------------------------------------------------------------------------
edit_alias_wrapper()
{
    if [ $# -lt 1 ]; then
        echo "❌ Usage: edit-alias <name> <new command...>"
        return 1
    fi

    local name="$1"
    shift
    local cmd="$*" file

    if ! file="$(alias_group_file_for_name "$name")"; then
        echo "⚠️  Alias '$name' is not in any group file."
        return 1
    fi

    if alias_path_is_under_core "$file"; then
        echo "❌ Alias '$name' is defined in core/ and cannot be edited here."
        echo "   Copy or redefine it under custom/ if you need a personal version."
        return 1
    fi

    if [ -z "$cmd" ]; then
        if alias "$name" >/dev/null 2>&1; then
            echo "Current: $(alias "$name")"
        fi
        read -rp "New command for '$name': " cmd
        echo
        if [ -z "$cmd" ]; then
            echo "🚫 Empty command — cancelled."
            return 1
        fi
    fi

    if ! alias_replace_in_file "$file" "$name" "$cmd"; then
        echo "❌ Could not update alias '$name' in $file"
        return 1
    fi

    _alias_mgmt_define "$name" "$cmd"
    _alias_mgmt_refresh_registry

    echo "✅ Updated alias $name → $cmd"
    echo "   Group file: $file"
}

# -----------------------------------------------------------------------------
# delete_alias_wrapper — Delete an alias (session and/or group file)
# -----------------------------------------------------------------------------
delete_alias_wrapper()
{
    if [ $# -lt 1 ]; then
        echo "❌ Usage: delete-alias <name> [--session|--file]"
        return 1
    fi

    local name="$1" mode="" file=""
    shift || true

    while [ $# -gt 0 ]; do
        case "$1" in
            --session|-s) mode="session" ;;
            --file|-f)    mode="file" ;;
            *)
                echo "❌ Unknown option: $1"
                echo "   Usage: delete-alias <name> [--session|--file]"
                return 1
                ;;
        esac
        shift
    done

    file="$(alias_group_file_for_name "$name" 2>/dev/null)" || file=""

    if ! alias "$name" >/dev/null 2>&1 && [ -z "$file" ]; then
        echo "⚠️  Alias '$name' does not exist in this session or any group file."
        return 1
    fi

    if alias "$name" >/dev/null 2>&1; then
        echo "🗑️  Session: $(alias "$name")"
    fi
    if [ -n "$file" ]; then
        echo "📄 File:    $file"
    fi

    if [ -z "$mode" ]; then
        echo
        echo "Delete '$name' how?"
        echo "  s) session only"
        if [ -n "$file" ]; then
            echo "  f) remove from group file (permanent)"
        fi
        echo "  n) cancel"
        read -rp "Choice [s/f/n]: " ans
        echo
        case "$ans" in
            [Ss]) mode="session" ;;
            [Ff])
                if [ -z "$file" ]; then
                    echo "⚠️  No group file for '$name'; session-only delete."
                    mode="session"
                else
                    mode="file"
                fi
                ;;
            *)
                echo "🚫 Deletion cancelled."
                return 1
                ;;
        esac
    fi

    if [ "$mode" = "file" ]; then
        if [ -z "$file" ]; then
            echo "❌ Alias '$name' is not stored in a group file."
            return 1
        fi
        if alias_path_is_under_core "$file"; then
            echo "❌ Alias '$name' is defined in core/ and cannot be removed from disk via delete-alias."
            echo "   Use --session to drop it for this shell only."
            return 1
        fi
        if ! alias_remove_from_file "$file" "$name"; then
            echo "❌ Failed to remove '$name' from $file"
            return 1
        fi
        unalias "$name" 2>/dev/null || true
        _alias_mgmt_refresh_registry
        echo "✅ Alias '$name' removed from $file (and this session)."
        return 0
    fi

    # session
    if ! alias "$name" >/dev/null 2>&1; then
        echo "⚠️  Alias '$name' is not defined in this session."
        return 1
    fi
    if unalias "$name"; then
        echo "✅ Alias '$name' deleted for this session (group file unchanged)."
    else
        echo "❌ Failed to delete alias '$name'."
        return 1
    fi
}


# -----------------------------------------------------------------------------
# check_alias_groups_wrapper — Verify group registry matches loaded aliases
# -----------------------------------------------------------------------------
check_alias_groups_wrapper()
{
    local ok=1 i name members f
    echo "🔎 Checking alias groups (file → group registry)..."

    if [ "${#ALIAS_GROUP_ORDER[@]}" -eq 0 ]; then
        echo "⚠️  No groups registered. Did build_alias_group_registry run?"
        return 1
    fi

    for i in "${!ALIAS_GROUP_ORDER[@]}"; do
        f="${ALIAS_GROUP_FILES[$i]}"
        if [ ! -r "$f" ]; then
            echo "⚠️  Group '${ALIAS_GROUP_ORDER[$i]}': file not readable: $f"
            ok=0
            continue
        fi
        members="${ALIAS_GROUP_MEMBERS[$i]}"
        for name in $members; do
            if ! alias "$name" >/dev/null 2>&1; then
                echo "⚠️  In group '${ALIAS_GROUP_ORDER[$i]}': alias '$name' not found (typo or not loaded yet?)"
                ok=0
            fi
        done
    done

    [ $ok -eq 1 ] && echo "✅ Groups look good."
    return $((!ok))
}

# ===================================== EOF ====================================
