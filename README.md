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

## Install

Symlink (or copy) into your home directory:

```bash
ln -sfn "$PWD/.bash_aliases" ~/.bash_aliases
ln -sfn "$PWD/.bash" ~/.bash
```

Source from `~/.bashrc`:

```bash
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
```

Then `source ~/.bash_aliases` or open a new shell.

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

## Manage aliases

```bash
add-alias system ducks 'du -sh *'    # existing group (token from list-alias-groups)
add-alias docker dps 'docker ps'     # creates custom/NN-docker.sh if the group is new
edit-alias ducks 'du -sh * | sort -h'
delete-alias ducks --file            # remove from file + this session
delete-alias ducks --session         # this shell only
delete-alias ducks                   # interactive: session vs file
```

Hand-editing group files still works; run `reload-aliases` afterwards.

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

## Development

```bash
make init
python -m pip install -r requirements.txt
bash tests/run-tests.sh
make mkdocs-serve
```

<a href="https://github.com/the-lupaxa-project">
  <img src="https://raw.githubusercontent.com/the-lupaxa-project/brand-assets/master/logos/components/footer-for-child-orgs.svg" alt="The Lupaxa Project Footer" width="100%" />
</a>
