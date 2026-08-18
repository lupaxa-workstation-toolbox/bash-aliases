# shellcheck shell=bash
###############################################################################
# 20-alias-management.sh — Alias management
# Public commands to list, add, edit, delete, reload, and check aliases.
###############################################################################

# @group: Alias management
# @keys: alias,aliases,management

alias list-aliases='list_aliases_wrapper'
alias list-alias-groups='list_alias_groups_wrapper'

alias reload-aliases='source ~/.bash_aliases && echo "🔁 Aliases reloaded."'

# @hint <group> <name> <command...>
alias add-alias='add_alias_wrapper'

# @hint <name> <new command...>
alias edit-alias='edit_alias_wrapper'

# @hint <name> [--session|--file]
alias delete-alias='delete_alias_wrapper'

alias check-alias-groups='check_alias_groups_wrapper'

# ===================================== EOF ====================================
