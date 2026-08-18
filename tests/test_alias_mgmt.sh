#!/usr/bin/env bash
# shellcheck shell=bash
# Sourced by run-tests.sh after 00-config.sh

test_alias_quote_and_format() {
    echo "test_alias_quote_and_format"
    assert_eq "no quotes" "alias foo='bar'" "$(alias_format_line foo bar | tr -d '\n')"
    local got
    got=$(alias_format_line foo "it's" | tr -d '\n')
    assert_eq "embed quote" "alias foo='it'\\''s'" "$got"
}

test_alias_next_group_nn() {
    echo "test_alias_next_group_nn"
    local dir
    dir=$(mktemp -d)
    touch "$dir/20-alias-management.sh" "$dir/30-git-aliases.sh" "$dir/90-other-aliases.sh"
    assert_eq "next tens slot" "40" "$(alias_next_group_nn "$dir")"
    rm -rf "$dir"
}

test_alias_file_roundtrip() {
    echo "test_alias_file_roundtrip"
    local dir file
    dir=$(mktemp -d)
    mkdir -p "$dir/custom"
    export BASH_ALIAS_DIR="$dir"
    file=$(alias_create_group_file "$dir/custom" "docker")
    assert_eq "first free nn" "20" "$(basename "$file" | cut -d- -f1)"

    alias_append_to_file "$file" "dps" "docker ps"
    build_alias_group_registry "$dir"
    assert_eq "members after add" "dps" "$(group_members Docker)"
    assert_eq "file for name" "$file" "$(alias_group_file_for_name dps)"

    alias_replace_in_file "$file" "dps" "docker ps -a"
    if grep -Fq "docker ps -a" "$file"; then
        assert_eq "replace command" "ok" "ok"
    else
        assert_eq "replace command" "ok" "missing"
    fi

    {
        printf '%s\n' '# @group: Docker'
        printf '%s\n' '# @keys: docker'
        printf '%s\n' '# @hint <all>'
        alias_format_line dps "docker ps -a"
    } >"$file"

    alias_remove_from_file "$file" "dps"
    if grep -q 'alias dps=' "$file"; then
        assert_eq "alias removed" "gone" "present"
    else
        assert_eq "alias removed" "gone" "gone"
    fi
    if grep -q '@hint' "$file"; then
        assert_eq "hint removed with alias" "gone" "present"
    else
        assert_eq "hint removed with alias" "gone" "gone"
    fi
    unalias dps 2>/dev/null || true
    unset BASH_ALIAS_DIR
    rm -rf "$dir"
}

test_add_alias_writes_custom_only() {
    echo "test_add_alias_writes_custom_only"
    local root
    root=$(mktemp -d)
    mkdir -p "$root/core" "$root/custom"
    export BASH_ALIAS_DIR="$root"
    # Minimal core group (must not receive new aliases)
    cat >"$root/core/20-alias-management.sh" <<'EOF'
# @group: Alias management
# @keys: alias,aliases,management
alias list-aliases='echo list'
EOF
    # shellcheck source=/dev/null
    . "$REPO_ROOT/.bash/aliases/core/10-functions.sh"
    build_alias_group_registry "$root"

    add_alias_wrapper docker dps 'docker ps' >/dev/null
    local f
    f="$(alias_group_file_for_name dps)"
    case "$f" in
        "$root/custom"/*) assert_eq "created under custom" "yes" "yes" ;;
        *) assert_eq "created under custom" "yes" "no:$f" ;;
    esac
    assert_eq "expected custom path" "$root/custom/20-docker.sh" "$f"

    if add_alias_wrapper management coreonly 'echo no' >/dev/null 2>&1; then
        assert_eq "refuse add to core group" "refused" "allowed"
    else
        assert_eq "refuse add to core group" "refused" "refused"
    fi
    unalias dps 2>/dev/null || true
    unset BASH_ALIAS_DIR
    rm -rf "$root"
}

test_edit_delete_refuse_core_file() {
    echo "test_edit_delete_refuse_core_file"
    local root
    root=$(mktemp -d)
    mkdir -p "$root/core" "$root/custom"
    export BASH_ALIAS_DIR="$root"
    cat >"$root/core/20-alias-management.sh" <<'EOF'
# @group: Alias management
# @keys: alias,aliases,management
alias list-aliases='echo list'
EOF
    # shellcheck source=/dev/null
    . "$REPO_ROOT/.bash/aliases/core/10-functions.sh"
    build_alias_group_registry "$root"
    alias list-aliases='echo list'

    if edit_alias_wrapper list-aliases 'echo changed' >/dev/null 2>&1; then
        assert_eq "edit core refused" "refused" "allowed"
    else
        assert_eq "edit core refused" "refused" "refused"
    fi

    if delete_alias_wrapper list-aliases --file >/dev/null 2>&1; then
        assert_eq "delete --file core refused" "refused" "allowed"
    else
        assert_eq "delete --file core refused" "refused" "refused"
    fi

    if delete_alias_wrapper list-aliases --session >/dev/null 2>&1; then
        assert_eq "session delete core ok" "ok" "ok"
    else
        assert_eq "session delete core ok" "ok" "failed"
    fi
    unset BASH_ALIAS_DIR
    rm -rf "$root"
}

test_core_guard_uses_registry_root() {
    echo "test_core_guard_uses_registry_root"
    local root_a root_b before after
    root_a=$(mktemp -d)
    root_b=$(mktemp -d)
    mkdir -p "$root_a/core" "$root_a/custom" "$root_b/core" "$root_b/custom"
    cat >"$root_a/core/20-alias-management.sh" <<'EOF'
# @group: Alias management
# @keys: alias,aliases,management
alias guarded-core='echo original'
EOF
    build_alias_group_registry "$root_a"
    before="$(<"$root_a/core/20-alias-management.sh")"
    export BASH_ALIAS_DIR="$root_b"

    if edit_alias_wrapper guarded-core 'echo changed' >/dev/null 2>&1; then
        assert_eq "registry-root core edit refused" "refused" "allowed"
    else
        assert_eq "registry-root core edit refused" "refused" "refused"
    fi
    after="$(<"$root_a/core/20-alias-management.sh")"
    assert_eq "registry-root core file unchanged" "$before" "$after"

    unset BASH_ALIAS_DIR
    rm -rf "$root_a" "$root_b"
}

test_duplicate_group_prefers_custom() {
    echo "test_duplicate_group_prefers_custom"
    local root warning warning_file file
    root=$(mktemp -d)
    mkdir -p "$root/core" "$root/custom"
    cat >"$root/core/20-alias-management.sh" <<'EOF'
# @group: Alias management
# @keys: alias,aliases,management
alias core-management='echo core'
EOF
    cat >"$root/custom/20-alias-management.sh" <<'EOF'
# @group: Alias management
# @keys: custom-management
alias custom-management='echo custom'
EOF
    warning_file=$(mktemp)
    build_alias_group_registry "$root" 2>"$warning_file"
    warning="$(<"$warning_file")"
    rm -f "$warning_file"
    case "$warning" in
        *"Duplicate alias group"*) assert_eq "duplicate group warning" "yes" "yes" ;;
        *) assert_eq "duplicate group warning" "yes" "no:$warning" ;;
    esac
    export BASH_ALIAS_DIR="$root"
    add_alias_wrapper custom-management custom-added 'echo added' >/dev/null 2>&1
    file="$(alias_group_file_for_name custom-added)"
    assert_eq "duplicate group writes custom" "$root/custom/20-alias-management.sh" "$file"

    unalias custom-added 2>/dev/null || true
    unset BASH_ALIAS_DIR
    rm -rf "$root"
}

test_add_alias_requires_existing_root() {
    echo "test_add_alias_requires_existing_root"
    local parent root
    parent=$(mktemp -d)
    root="$parent/missing"
    export BASH_ALIAS_DIR="$root"

    if add_alias_wrapper docker typo-root 'echo no' >/dev/null 2>&1; then
        assert_eq "missing aliases root refused" "refused" "allowed"
    else
        assert_eq "missing aliases root refused" "refused" "refused"
    fi
    if [ -e "$root" ]; then
        assert_eq "missing aliases root not created" "absent" "created"
    else
        assert_eq "missing aliases root not created" "absent" "absent"
    fi

    unset BASH_ALIAS_DIR
    rm -rf "$parent"
}

test_loader_warns_for_flat_or_empty_layout() {
    echo "test_loader_warns_for_flat_or_empty_layout"
    local root output
    root=$(mktemp -d)
    printf '%s\n' "alias legacy-flat='echo legacy'" >"$root/20-legacy.sh"
    output="$(BASH_ALIAS_DIR="$root" bash -c '. "$1/.bash_aliases"' _ "$REPO_ROOT" 2>&1)"
    case "$output" in
        *"layout changed"*"custom/"*) assert_eq "flat layout warning" "yes" "yes" ;;
        *) assert_eq "flat layout warning" "yes" "no:$output" ;;
    esac

    rm -f "$root/20-legacy.sh"
    mkdir -p "$root/core" "$root/custom"
    output="$(BASH_ALIAS_DIR="$root" bash -c '. "$1/.bash_aliases"' _ "$REPO_ROOT" 2>&1)"
    case "$output" in
        *"layout changed"*"custom/"*) assert_eq "empty layout warning" "yes" "yes" ;;
        *) assert_eq "empty layout warning" "yes" "no:$output" ;;
    esac

    printf '%s\n' "alias custom-loaded='echo loaded'" >"$root/custom/20-custom.sh"
    output="$(BASH_ALIAS_DIR="$root" bash -c '. "$1/.bash_aliases"' _ "$REPO_ROOT" 2>&1)"
    assert_eq "populated layout quiet" "" "$output"
    rm -rf "$root"
}
