# Dotfiles

`~/.config` for two machines: a macOS laptop and a CachyOS Linux desktop. One branch, one set of
files, byte-identical on both. Everything that genuinely differs per machine lives in a gitignored
`*.local*` file next to a tracked `.example` template.

## Layout notes

Two things about this repository surprise people (including future me):

- **The root `.gitignore` is `/*`.** Nothing is tracked unless it was force-added, which is what
  keeps Claude Code's transcripts and caches under `claude/` out of a public repository. Adding a
  new file therefore needs `git add -f path/to/file`. Never `git add -f .` — that bypasses every
  ignore rule and would sweep in the whole state directory.
- **The repository is public.** Account identifiers, work hostnames, and anything else that should
  not be indexed belong in `fish/config.local.fish`, not in a tracked file.

## Bootstrapping a new machine

```sh
git clone --recurse-submodules git@github.com:connortsui20/.config.git ~/.config
```

Then, in order:

1. **Git signing.** Copy the template and fill in this machine's values. Commits are signed
   (`commit.gpgsign = true`) and `git/config` includes `config.local`, so **you cannot commit until
   this exists**. A missing include is silently skipped, so the failure shows up as a confusing
   signing error rather than a missing-file error.

   ```sh
   cp ~/.config/git/config.local.example ~/.config/git/config.local
   ```

   Set `user.signingkey` to this machine's 1Password SSH public key, and `gpg.ssh.program` to
   `/Applications/1Password.app/Contents/MacOS/op-ssh-sign` on macOS or `/opt/1Password/op-ssh-sign`
   on Linux.

2. **Alacritty.** Font size is per-display, and the fish and zellij paths differ by OS. A missing
   `alacritty.local.toml` is skipped without a warning, and the symptom is a terminal that opens the
   login shell instead of fish + zellij.

   ```sh
   cp ~/.config/alacritty/alacritty.local.toml.example ~/.config/alacritty/alacritty.local.toml
   ```

3. **Private fish settings**, if this machine needs any.

   ```sh
   cp ~/.config/fish/config.local.fish.example ~/.config/fish/config.local.fish
   ```

4. **Clear the old universal fish variables.** `fish_user_paths` used to be synced through the
   tracked `fish_variables`, so both machines' paths ended up in both machines' `PATH`. It is
   untracked now, but any existing universal value survives locally and takes precedence over
   `config.fish`, because `fish_add_path` skips directories that are already present.
   `config.fish` erases it on next startup, so this is only needed if you want it gone immediately:

   ```sh
   set -eU fish_user_paths
   ```

   Verify with `set -S fish_user_paths` — there should be no universal scope, and no `/home/connor`
   entries on macOS or `/Users/connor` entries on Linux.

5. **Set `origin/HEAD`** if the clone did not. The `git default-branch` alias, and the stacked-branch
   aliases built on it, resolve this automatically now, but doing it up front avoids the round trip:

   ```sh
   git remote set-head origin --auto
   ```

## Migrating a machine that predates the collapse

A machine that was on the old `main` or `macos` branch needs three things beyond the bootstrap
above. Do all of them **before** opening a new shell, because the first two are only surprising if
something has already written to the new location.

1. **Relocate the Claude Code and Codex state.** `config.fish` now sets `CLAUDE_CONFIG_DIR` and
   `CODEX_HOME` under `$XDG_CONFIG_HOME`; neither variable existed before the collapse. Both tools
   otherwise start up looking like fresh installs, logged out and with no history. `claude/` already
   exists here with tracked files in it, so copy into it rather than moving over it:

   ```sh
   rsync -a --exclude settings.json --exclude .gitignore ~/.claude/ ~/.config/claude/
   rsync -a ~/.codex/ ~/.config/codex/
   ```

   This is one-time. Once the state lives in the new location, nothing here recurs.

2. **Recover this machine's signing key.** It used to be committed in `git/config`, and the two
   machines had different keys, so read the value off the branch this machine was on before writing
   `git/config.local`:

   ```sh
   git show origin/main:git/config | grep signingkey   # the Linux desktop's key
   git log --all --oneline -S signingkey -- git/config # every commit that touched one
   ```

3. **Check the universal fish paths before the first new shell erases them.** `config.fish` drops the
   universal `fish_user_paths` on startup, so confirm it holds nothing this file does not already
   reproduce:

   ```sh
   set -S fish_user_paths
   ```

   Every entry should be either a directory the `switch (uname)` block adds back, or the other
   machine's leftovers. Anything else needs a home in `config.fish` first.

## Per-machine files

| File | Template | Holds |
| --- | --- | --- |
| `git/config.local` | `git/config.local.example` | SSH signing key, `op-ssh-sign` path |
| `alacritty/alacritty.local.toml` | `alacritty.local.toml.example` | Font size, fish and zellij paths |
| `fish/config.local.fish` | `fish/config.local.fish.example` | Private and machine-local shell settings |
| `fish/fish_variables` | — | Fish universal variables; deliberately untracked |

Zed has no include mechanism, so `zed/settings.json` is shared wholesale. Anything machine-specific
in there (`lsp.rust-analyzer.initialization_options.numThreads`, for instance) is a compromise value
rather than a per-machine one.
