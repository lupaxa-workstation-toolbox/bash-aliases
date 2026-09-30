<p align="center">
    <a href="https://github.com/lupaxa-workstation-toolbox">
        <img src="https://raw.githubusercontent.com/the-lupaxa-project/brand-assets/master/logos/organisations/workstation-toolbox/readme-logo.png" alt="Organisation Logo" />
    </a>
</p>

<h1 align="center">Bash Aliases</h1>

A **file-equals-group** Bash alias starter pack you can fork and extend. One
group file under `~/.bash/aliases/custom/` is one user-managed group. Ships
example Git, system, MkDocs, and catch-all aliases, plus helpers: `add-alias`,
`edit-alias`, `delete-alias`, `list-aliases`, and `reload-aliases`.

Groups are derived from files — no central membership list. Platform config and
alias-management helpers live under `core/`; editable groups are `20-*.sh` …
`99-*.sh` under `custom/`.

## Requirements

- Bash (macOS `/bin/bash` 3.2 or newer is fine)
- Optional: Git, for the Git alias group

## Install

Symlink (or copy) into your home directory:

```bash
ln -sfn "$PWD/.bash_aliases" ~/.bash_aliases
ln -sfn "$PWD/.bash" ~/.bash
```

Or copy `.bash_aliases` and the `.bash/aliases/` tree (`core/` and `custom/`)
into `$HOME`.

If you are upgrading from an earlier flat layout, move personal `20-*.sh`
through `99-*.sh` group files into `.bash/aliases/custom/`. The loader warns
when it finds an old flat or empty layout.

Source from `~/.bashrc`:

```bash
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
```

Then `source ~/.bash_aliases` or open a new shell.

Default alias directory: `$HOME/.bash/aliases`. Override with `BASH_ALIAS_DIR`
(useful for tests).

## Quick check

```bash
list-alias-groups
list-aliases
check-alias-groups
```

## Example aliases included

| Group            | Examples                                              |
| ---------------- | ----------------------------------------------------- |
| Alias management | `list-aliases`, `add-alias`, `edit-alias`, …          |
| Git              | `gs`, `gca`, `push-all`, `tag-push`, …                |
| System           | `dfh`, `ll`, `la`, `path`, `rmf`                      |
| MkDocs           | `mkdocs-serve`, `mkdocs-build`, `mkdocs-lan`          |
| Other            | `myip`                                                |
| Helpers          | `mkcd` (in `custom/10-functions.sh`)                  |

Filter tokens for `list-aliases <token>` come from each file’s default key or
`# @keys:` header (for example `git`, `system`, `mkdocs`, `alias`, `other`).

### Git wrappers

Parameterized helpers in `custom/10-functions.sh` / `custom/20-git-aliases.sh`:

| Command                    | Behaviour                                     |
| -------------------------- | --------------------------------------------- |
| `push-all <message>`       | Stage all, commit, optionally push            |
| `tag-push <tag> [message]` | Annotated tag + `git push --tags`             |
| `undo-last-commit`         | Soft reset last commit (keeps changes staged) |

## Manage aliases

```bash
add-alias system ducks 'du -sh *'    # existing group (token from list-alias-groups)
add-alias docker dps 'docker ps'     # creates custom/NN-docker.sh if the group is new
edit-alias ducks 'du -sh * | sort -h'
delete-alias ducks --file            # remove from file + this session
delete-alias ducks --session         # this shell only
delete-alias ducks                   # interactive: session vs file
```

`<group>` is a filter token from `list-alias-groups`, or a new slug. New groups
get the next free `NN` prefix under `custom/` (preferring 20, 30, … 80) and a
`# @group` / `# @keys` header. Add/edit/delete refresh the registry themselves;
after hand-editing group files, run `reload-aliases`.

`edit-alias` and `delete-alias --file` refuse paths under `core/`. `add-alias`
never writes under `core/`.

## Group layout

Alias files live under `core/` (platform) and `custom/` (your edits):

- **`core/`** — platform (do not customise)
- **`custom/`** — edit here; `add-alias` writes here
- **Flat personal trees:** move your `20–99` files (and helpers) into `custom/`

| File                            | Group             |
| ------------------------------- | ----------------- |
| `core/20-alias-management.sh`   | Alias management  |
| `custom/20-git-aliases.sh`      | Git               |
| `custom/30-system.sh`           | System            |
| `custom/40-mkdocs.sh`           | MkDocs            |
| `custom/90-other-aliases.sh`    | Other (catch-all) |

### Headers and hints

Optional overrides at the top of a group file:

```bash
# @group: Alias management
# @keys: alias,aliases,management
```

Parameter hints for `list-aliases` (hand-edit; helpers do not write `@hint`
yet). Put `# @hint …` on the line before the alias, then `reload-aliases`:

```bash
# @hint <message>
alias push-all='push_all_wrapper'
```

## Tests

From a checkout of this repo:

```bash
bash tests/run-tests.sh
```

<a href="https://github.com/the-lupaxa-project">
  <img src="https://raw.githubusercontent.com/the-lupaxa-project/brand-assets/master/logos/components/footer-for-child-orgs.svg" alt="The Lupaxa Project Footer" width="100%" />
</a>
