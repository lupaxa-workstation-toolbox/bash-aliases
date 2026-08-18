# shellcheck shell=bash
###############################################################################
# 20-git-aliases.sh — Git
# Everyday Git shortcuts plus a few safer wrappers (see 10-functions.sh).
###############################################################################

# @group: Git
# @keys: git

# -----------------------------------------------------------------------------
# Wrappers
# -----------------------------------------------------------------------------

# @hint <message>
alias push-all='push_all_wrapper'

# @hint <tag> [message]
alias tag-push='tag_push_wrapper'

alias undo-last-commit='undo_last_commit_wrapper'

# -----------------------------------------------------------------------------
# Shortcuts
# -----------------------------------------------------------------------------
alias gc='git clone'
alias gs='git status -sb'
# @hint <message>
alias gca='git commit -a -m'
alias gb='git branch'
alias gco='git checkout'
alias ga='git add'
alias gaa='git add -A'
alias gfu='git fetch && git pull'

# ===================================== EOF ====================================
