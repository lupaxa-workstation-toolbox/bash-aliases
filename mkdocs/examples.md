# Examples

## Add an Alias to an Existing Group

```bash
add-alias system ducks 'du -sh *'
list-aliases system
```

Catch-all one-offs:

```bash
add-alias other weather 'curl -fsS wttr.in'
```

## Create a New Group

```bash
add-alias docker dps 'docker ps'
add-alias docker dcu 'docker compose up -d'
list-alias-groups
list-aliases docker
```

The first `add-alias` for an unknown group slug creates `custom/NN-docker.sh` with
`# @group` / `# @keys` headers. You can still create files by hand if you want
extra keys (for example `dk`).

## Edit and Delete

```bash
edit-alias dps 'docker ps -a'
delete-alias dps --file
```

Session-only delete (group file unchanged):

```bash
delete-alias dps --session
```

## Add a Helper Function

Put personal functions in `custom/10-functions.sh` (same place as the shipped
Git wrappers and `mkcd`), then wire aliases in a group file if you want them
listed by `list-aliases`.

## Document a Parameterized Alias

Hand-edit the group file (helpers do not write `@hint` yet):

```bash
# @hint <service>
alias dcl='docker compose logs -f'
```

Then `reload-aliases`. `list-aliases docker` shows `dcl <service>`.

## Run the Registry Tests

From a checkout of this repo:

```bash
bash tests/run-tests.sh
```
