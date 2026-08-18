#!/usr/bin/env bash
# shellcheck shell=bash
# Sourced by run-tests.sh after 00-config.sh
# FAIL is read by run-tests.sh after all suites finish.
# shellcheck disable=SC2034

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"
    else
        echo "  FAIL: $desc"
        echo "        expected: [$expected]"
        echo "        actual:   [$actual]"
        FAIL=1
    fi
}

test_default_name_from_filename() {
    echo "test_default_name_from_filename"
    assert_eq "git-aliases → Git" "Git" "$(alias_group_default_name "20-git-aliases.sh")"
    assert_eq "docker → Docker" "Docker" "$(alias_group_default_name "30-docker.sh")"
    assert_eq "alias-management → Alias Management" "Alias Management" "$(alias_group_default_name "25-alias-management.sh")"
    assert_eq "uppercase slug → Git" "Git" "$(alias_group_default_name "20-GIT-aliases.sh")"
}

test_default_keys_from_filename() {
    echo "test_default_keys_from_filename"
    assert_eq "git key lowercased" "git" "$(alias_group_default_keys "20-git-aliases.sh")"
    assert_eq "uppercase slug key lowercased" "git" "$(alias_group_default_keys "20-GIT-aliases.sh")"
    assert_eq "nonnumeric prefix not stripped" "ab-git" "$(alias_group_default_keys "ab-git-aliases.sh")"
}

test_header_overrides() {
    echo "test_header_overrides"
    local f="$TEST_ROOT/fixtures/core/25-alias-management.sh"
    _ag_header_group=""
    _ag_header_keys=""
    alias_group_parse_header "$f"
    assert_eq "header group" "Alias management" "$_ag_header_group"
    assert_eq "header keys" "alias,aliases,management" "$_ag_header_keys"
}

test_indented_directives() {
    echo "test_indented_directives"
    local f
    f="$(mktemp "${TMPDIR:-/tmp}/alias-group-indented.XXXXXX")"
    cat > "$f" <<'EOF'
    # @group: Indented group
	# @keys: indented,spaces
    # @hint <value>
    alias indented-alias='printf "%s\n"'
EOF
    _ag_header_group=""
    _ag_header_keys=""
    alias_group_parse_header "$f"
    assert_eq "indented header group" "Indented group" "$_ag_header_group"
    assert_eq "indented header keys" "indented,spaces" "$_ag_header_keys"
    assert_eq "indented alias member" "indented-alias" "$(alias_group_parse_members "$f")"
    assert_eq "indented hint" "indented-alias	<value>" "$(alias_group_parse_hints "$f")"
    rm -f "$f"
}

test_header_rejects_inline_directives() {
    echo "test_header_rejects_inline_directives"
    local f
    f="$(mktemp "${TMPDIR:-/tmp}/alias-group-header.XXXXXX")"
    cat > "$f" <<'EOF'
# Documentation mentions @group: fake and @keys: bad inline
# Also @hint-like text without being a directive
alias foo='bar'
EOF
    _ag_header_group=""
    _ag_header_keys=""
    alias_group_parse_header "$f"
    assert_eq "no false group from inline @group:" "" "$_ag_header_group"
    assert_eq "no false keys from inline @keys:" "" "$_ag_header_keys"
    rm -f "$f"
}

test_hints_reject_inline_directives() {
    echo "test_hints_reject_inline_directives"
    local f
    f="$(mktemp "${TMPDIR:-/tmp}/alias-group-hints.XXXXXX")"
    cat > "$f" <<'EOF'
# prose with @hint embedded mid-line is not a directive
alias foo='bar'
EOF
    assert_eq "no hint from inline @hint" "" "$(alias_group_parse_hints "$f")"
    rm -f "$f"
}

test_hints_reject_false_prefix_matches() {
    echo "test_hints_reject_false_prefix_matches"
    local f
    f="$(mktemp "${TMPDIR:-/tmp}/alias-group-hints-prefix.XXXXXX")"
    cat > "$f" <<'EOF'
# @hinted text should not be a hint
alias foo='bar'
# @hint-example also not a hint
alias baz='qux'
EOF
    assert_eq "no hint from @hinted" "" "$(alias_group_parse_hints "$f")"
    rm -f "$f"
}

test_parse_members_and_hints() {
    echo "test_parse_members_and_hints"
    local f="$TEST_ROOT/fixtures/custom/20-git-aliases.sh"
    assert_eq "members" "gca gs" "$(alias_group_parse_members "$f")"
    assert_eq "hint for gca" "<message>" "$(alias_group_parse_hints "$f" | awk -F'	' '$1=="gca"{print $2; exit}')"
}

test_build_registry() {
    echo "test_build_registry"
    build_alias_group_registry "$TEST_ROOT/fixtures"
    assert_eq "order count" "3" "${#ALIAS_GROUP_ORDER[@]}"
    assert_eq "first is Alias management" "Alias management" "${ALIAS_GROUP_ORDER[0]}"
    assert_eq "second is Git" "Git" "${ALIAS_GROUP_ORDER[1]}"
    assert_eq "third is Docker" "Docker" "${ALIAS_GROUP_ORDER[2]}"
    assert_eq "resolve git" "Git" "$(resolve_group_name git)"
    assert_eq "resolve alias" "Alias management" "$(resolve_group_name aliases)"
    assert_eq "classify gs" "Git" "$(classify_group gs)"
    assert_eq "classify dps" "Docker" "$(classify_group dps)"
    assert_eq "members docker" "dps" "$(group_members Docker)"
    assert_eq "hint lookup" "<message>" "$(alias_hint_for gca)"
    assert_eq "mgmt file under core" \
        "$TEST_ROOT/fixtures/core/25-alias-management.sh" \
        "$(alias_group_file_for_canonical "Alias management")"
}

test_path_helpers() {
    echo "test_path_helpers"
    export BASH_ALIAS_DIR="/tmp/fake-aliases-root"
    build_alias_group_registry "$BASH_ALIAS_DIR"
    assert_eq "core dir" "/tmp/fake-aliases-root/core" "$(bash_alias_core_dir)"
    assert_eq "custom dir" "/tmp/fake-aliases-root/custom" "$(bash_alias_custom_dir)"
    if alias_path_is_under_core "/tmp/fake-aliases-root/core/20-alias-management.sh"; then
        assert_eq "under core" "yes" "yes"
    else
        assert_eq "under core" "yes" "no"
    fi
    if alias_path_is_under_core "/tmp/fake-aliases-root/custom/20-git-aliases.sh"; then
        assert_eq "custom not core" "no" "yes"
    else
        assert_eq "custom not core" "no" "no"
    fi
    unset BASH_ALIAS_DIR
}
