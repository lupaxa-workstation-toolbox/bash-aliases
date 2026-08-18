# Bash Aliases

A **file-equals-group** Bash alias starter pack: drop group files under
`~/.bash/aliases/`, source them from `~/.bash_aliases`, and manage them with
`add-alias`, `edit-alias`, `list-aliases`, and `reload-aliases`.

Groups are derived from files — editable groups are one `20-*.sh` … `99-*.sh`
file under `custom/`. Platform config and alias-management helpers live under
`core/`. No central membership list to keep in sync. The shipped aliases are
portable examples (no machine-specific home paths); replace or extend them for
your own setup.

## What you get

- Lexicographic loader with numeric prefixes for load order
- File-equals-group registry (display name, filter keys, members, hints)
- Management commands: `add-alias`, `edit-alias`, `delete-alias`, `list-aliases`, `list-alias-groups`, `check-alias-groups`, `reload-aliases`
- Example Git, system, MkDocs, and catch-all shortcuts
- Themed groups as separate group files you can fork or delete

## Next steps

- [Getting started](getting-started.md) — install into your shell
- [Usage](usage.md) — everyday commands and example aliases
- [Reference](reference.md) — layout, headers, and public commands
- [Examples](examples.md) — add, edit, delete, and create groups
