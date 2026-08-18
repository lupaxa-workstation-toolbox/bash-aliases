# shellcheck shell=bash
###############################################################################
# 10-functions.sh — Custom helper functions
# Ship Git wrappers and mkcd here; add personal helper functions in this file too.
###############################################################################

# -----------------------------------------------------------------------------
# undo_last_commit_wrapper — Undo last commit (keep changes staged)
# -----------------------------------------------------------------------------
undo_last_commit_wrapper()
{
    echo "⚠️  This will undo the last commit but keep changes staged."
    read -rp "Continue? (y/n) " ans
    [[ $ans =~ ^[Yy] ]] || { echo "🚫 Cancelled."; return 1; }

    git reset --soft HEAD~1 && echo "✅ Last commit undone (changes remain staged)."
}

# -----------------------------------------------------------------------------
# push_all_wrapper — Add, commit, and optionally push with confirmation
# -----------------------------------------------------------------------------
push_all_wrapper()
{
    if [ $# -eq 0 ]; then
        echo "❌ Usage: push-all <commit message>"
        return 1
    fi

    local msg="$*"
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    echo "🚀 Preparing to commit on branch: ${branch:-unknown}"
    echo "💬 Commit message: '$msg'"
    echo

    # Stage all changes
    git add -A || return 1

    # If nothing staged, bail out early
    if git diff --cached --quiet; then
        echo "ℹ️  No staged changes; nothing to commit."
        return 0
    fi

    # Commit with message
    if ! git commit -m "$msg"; then
        echo "❌ Commit failed."
        return 1
    fi

    echo
    read -rp "⚠️  Push to remote '${branch:-current branch}'? (y/n) " ans
    echo

    if [[ $ans =~ ^[Yy] ]]; then
        echo "📤 Pushing..."
        if ! git push; then
            echo "❌ Push failed."
            return 1
        fi
    else
        echo "🚫 Push cancelled."
    fi
}

# -----------------------------------------------------------------------------
# tag_push_wrapper — Create an annotated tag and push tags
# -----------------------------------------------------------------------------
tag_push_wrapper()
{
    if [ $# -lt 1 ]; then
        echo "❌ Usage: tag-push <tag> [message]"
        return 1
    fi

    local tag="$1"
    shift
    local msg="${*:-Tag $tag}"

    echo "🏷️  Creating tag: $tag"
    git tag -a "$tag" -m "$msg" || return 1

    echo "📤 Pushing tags..."
    git push --tags || return 1

    echo "✅ Tag '$tag' created and pushed successfully."
}

# -----------------------------------------------------------------------------
# mkcd — Create a directory (including parents) and cd into it
# -----------------------------------------------------------------------------
mkcd()
{
    mkdir -p -- "$1" && cd -- "$1" || return
}

# ===================================== EOF ====================================
