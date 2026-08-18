# Getting started

## Requirements

- Bash (macOS `/bin/bash` 3.2 or newer is fine)
- Optional: Git, for the Git alias group

## Install

Clone this repository (or keep your existing checkout), then point your home
aliases at the repo files. Symlink:

```bash
ln -sfn /path/to/bash-aliases/.bash_aliases ~/.bash_aliases
ln -sfn /path/to/bash-aliases/.bash ~/.bash
```

Or copy `.bash_aliases` and the `.bash/aliases/` tree (`core/` and `custom/`)
into `$HOME`.

If you are upgrading from the earlier flat layout, move personal
`20-*.sh` through `99-*.sh` group files into `.bash/aliases/custom/`.
Platform and alias-management files belong in `core/`; the loader warns when
it finds an old flat or empty layout.

Ensure `~/.bashrc` (or your login shell init) sources the loader:

```bash
# -------------------------------------------------------------------
# Aliases & Git completion
# -------------------------------------------------------------------
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
```

Open a new shell, or run:

```bash
source ~/.bash_aliases
```

## Verify

```bash
list-alias-groups
list-aliases
check-alias-groups
```

You should see groups such as **Alias management**, **Git**, **System**,
**MkDocs**, and **Other**, with portable example aliases (for example `gs`,
`dfh`, `mkdocs-serve`). Helper functions such as `mkcd` live in
`custom/10-functions.sh`. Customise group files under `custom/`; treat `core/`
as platform-owned.

## Try the helpers

```bash
add-alias other hello 'echo hi'
list-aliases other
edit-alias hello 'echo hello'
delete-alias hello --file
```

## Development extras

Docs and Makefile skills (optional):

```bash
make init
python -m pip install -r requirements.txt
make mkdocs-serve
```

Registry unit tests:

```bash
bash tests/run-tests.sh
```
