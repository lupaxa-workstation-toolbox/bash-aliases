#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

TEST_ROOT="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$TEST_ROOT/.." && pwd)"
# Mutated by assert_eq in sourced test helpers.
export FAIL=0

# shellcheck source=/dev/null
. "$REPO_ROOT/.bash/aliases/core/00-config.sh"
# shellcheck source=/dev/null
. "$TEST_ROOT/test_registry.sh"
# shellcheck source=/dev/null
. "$TEST_ROOT/test_alias_mgmt.sh"

test_default_name_from_filename
test_default_keys_from_filename
test_header_overrides
test_indented_directives
test_header_rejects_inline_directives
test_hints_reject_inline_directives
test_hints_reject_false_prefix_matches
test_parse_members_and_hints
test_build_registry
test_path_helpers
test_alias_quote_and_format
test_alias_next_group_nn
test_alias_file_roundtrip
test_add_alias_writes_custom_only
test_edit_delete_refuse_core_file
test_core_guard_uses_registry_root
test_duplicate_group_prefers_custom
test_add_alias_requires_existing_root
test_loader_warns_for_flat_or_empty_layout

if [ "$FAIL" -ne 0 ]; then
    echo "FAILED"
    exit 1
fi
echo "ALL PASSED"
