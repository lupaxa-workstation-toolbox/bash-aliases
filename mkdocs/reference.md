# Reference

## Layout

| Path                                       | Role                                                            |
| ------------------------------------------ | --------------------------------------------------------------- |
| `.bash_aliases`                            | Loader: `core/*.sh` then `custom/*.sh`, then registry           |
| `.bash/aliases/core/00-*.sh`               | Shared config / registry helpers (not a group)                  |
| `.bash/aliases/core/10-functions.sh`       | Alias-management implementations (not a group)                  |
| `.bash/aliases/core/20-*.sh`               | Core groups (e.g. Alias management) — not editable via helpers  |
| `.bash/aliases/custom/10-functions.sh`     | Custom helper functions (not a group)                           |
| `.bash/aliases/custom/20-*.sh` … `99-*.sh` | Editable alias groups                                           |

Files load in lexicographic order within each tree (`core/` first, then
`custom/`). Use numeric prefixes to control order.

`edit-alias` and `delete-alias --file` refuse paths under `core/`.
`add-alias` never writes under `core/` — new groups and aliases go in
`custom/`.

### Shipped example groups

| File                            | Group            | Example keys                     |
| ------------------------------- | ---------------- | -------------------------------- |
| `core/20-alias-management.sh`   | Alias management | `alias`, `aliases`, `management` |
| `custom/20-git-aliases.sh`      | Git              | `git`                            |
| `custom/30-system.sh`           | System           | `system`, `sys`                  |
| `custom/40-mkdocs.sh`           | MkDocs           | `mkdocs`, `docs`                 |
| `custom/90-other-aliases.sh`    | Other            | `other`, `misc`, `miscellaneous` |

Example groups under `custom/` are starter content. Delete or rewrite them for
your own machine; keep personal paths out of the shared repo.

## Group identity

For a group file `NN-name.sh` (or `NN-name-aliases.sh`):

- Default display name — strip `NN-` and trailing `-aliases`, title-case the rest (`custom/20-git-aliases.sh` → **Git**)
- Default filter key — lowercase hyphenated slug (`git`)
- Optional header overrides at the top of the file (see below)

```bash
# @group: Alias management
# @keys: alias,aliases,management
```

## Parameter hints

Place `# @hint …` on the line before an alias (leading whitespace allowed):

```bash
# @hint <message>
alias push-all='push_all_wrapper'
```

`list-aliases` shows `push-all <message>` when a hint is present.

## Public commands

| Alias                | Purpose                                              |
| -------------------- | ---------------------------------------------------- |
| `list-aliases`       | Grouped table of loaded aliases                      |
| `list-alias-groups`  | Group names and filter keys                          |
| `add-alias`          | Append alias to a group file (create group if needed)|
| `edit-alias`         | Change an alias command in its group file            |
| `delete-alias`       | Remove from session and/or group file                |
| `check-alias-groups` | Validate registry vs defined aliases                 |
| `reload-aliases`     | Re-source loader and rebuild registry                |

### `add-alias`

```text
add-alias <group> <name> <command...>
```

### `edit-alias`

```text
edit-alias <name> <new command...>
edit-alias <name>                    # prompts for command
```

### `delete-alias`

```text
delete-alias <name>
delete-alias <name> --session | -s
delete-alias <name> --file | -f
```

## Install path

Default alias directory: `$HOME/.bash/aliases`. Override with
`BASH_ALIAS_DIR` (useful for tests). Point that directory (or a symlink) at
this repository’s `.bash/aliases` tree.
