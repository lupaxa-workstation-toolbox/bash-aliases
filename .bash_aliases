# shellcheck shell=bash
###############################################################################
# .bash_aliases — Loader
# Sources core aliases, then custom aliases, and builds the group registry.
###############################################################################

# Override for tests / alternate installs: BASH_ALIAS_DIR=/path/to/aliases
BASH_ALIAS_DIR="${BASH_ALIAS_DIR:-$HOME/.bash/aliases}"
alias_dir="$BASH_ALIAS_DIR"
_alias_sourced_files=0

_source_alias_dir() {
    local dir="$1" f
    [ -d "$dir" ] || return 0
    for f in "$dir"/*.sh; do
        # Dynamic path — cannot be a constant source.
        # shellcheck disable=SC1090
        if [ -r "$f" ]; then
            . "$f"
            _alias_sourced_files=$((_alias_sourced_files + 1))
        fi
    done
}

if [ -d "$alias_dir" ]; then
    _source_alias_dir "$alias_dir/core"
    _source_alias_dir "$alias_dir/custom"
    if declare -F build_alias_group_registry >/dev/null 2>&1; then
        build_alias_group_registry "$alias_dir"
    fi
    if [ "$_alias_sourced_files" -eq 0 ]; then
        echo "⚠️  Alias layout changed: move personal 20–99 group files into $alias_dir/custom/."
    fi
else
    echo "⚠️  Alias directory not found: $alias_dir"
fi

unset -f _source_alias_dir
unset _alias_sourced_files

alias reload-aliases='source ~/.bash_aliases && echo "🔁 Aliases reloaded."'
