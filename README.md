# Dotfiles

`~/.config` for a macOS laptop and a CachyOS Linux desktop. Shared files use one branch on both
machines. OS-specific paths live in the Fish `switch` or an untracked `*.local*` file with a tracked
`.example` template. Public paths can be hardcoded. Credentials stay untracked.

## Layout notes

Two things about this repository surprise people (including future me):

- **The root `.gitignore` is `/*`.** Nothing is tracked unless it was force-added, which is what
  keeps Claude Code's transcripts and caches under `claude/` out of a public repository. Adding a
  new file therefore needs `git add -f path/to/file`. Never `git add -f .` — that bypasses every
  ignore rule and would sweep in the whole state directory.
- **The repository is public.** Private shell values belong in `fish/config.local.fish`.

## Bootstrapping a new machine

```sh
git clone --recurse-submodules git@github.com:connortsui20/.config.git ~/.config
```

Then, in order:

1. **Agent skills.** Check out `git@github.com:connortsui20/skills.git` at `~/projects/skills`.
   Then run:

   ```sh
   ~/projects/skills/bin/setup
   ~/.config/bin/setup-agents --dry-run
   ~/.config/bin/setup-agents
   ```

   The script links `~/.agents` to `~/.config/agents`. It preserves an existing `~/.agents` at
   `~/.config/agents.before-config`, which stays untracked. Repeated runs keep the existing link.
   If link creation fails, the script restores the original directory from that backup.
   Check the backup for additional skills before removing it.
   The script also backs up old Codex copies of `gh-stack` and `slidev` under
   `~/.config/agents/installed-skills.before-repo`, so Codex uses the shared versions.

2. **Git signing.** Copy the template and fill in this machine's values. Commits are signed
   (`commit.gpgsign = true`) and `git/config` includes `config.local`, so **you cannot commit until
   this exists**. A missing include is silently skipped, so the failure shows up as a confusing
   signing error rather than a missing-file error.

   ```sh
   cp ~/.config/git/config.local.example ~/.config/git/config.local
   ```

   Set `user.signingkey` to this machine's 1Password SSH public key, and `gpg.ssh.program` to
   `/Applications/1Password.app/Contents/MacOS/op-ssh-sign` on macOS or `/opt/1Password/op-ssh-sign`
   on Linux.

3. **Alacritty.** Font size is per-display, and the fish and zellij paths differ by OS. A missing
   `alacritty.local.toml` is skipped without a warning, and the symptom is a terminal that opens the
   login shell instead of fish + zellij.

   ```sh
   cp ~/.config/alacritty/alacritty.local.toml.example ~/.config/alacritty/alacritty.local.toml
   ```

   On KDE, enable the user units that keep Alacritty's colors in sync with Plasma's color scheme:

   ```sh
   systemctl --user enable --now alacritty-theme.service alacritty-theme.path
   ```

4. **Private Fish config**, if this machine needs any.

   ```sh
   cp ~/.config/fish/config.local.fish.example ~/.config/fish/config.local.fish
   ```

5. **Set `origin/HEAD`** if the clone did not. The `git default-branch` alias, and the stacked-branch
   aliases built on it, resolve this automatically now, but doing it up front avoids the round trip:

   ```sh
   git remote set-head origin --auto
   ```

## Agent instructions and skills

Edit `~/.config/AGENTS.md` for instructions shared by Codex and Claude Code. Both global instruction
files are tracked relative symlinks:

```text
~/.config/codex/AGENTS.md  -> ../AGENTS.md
~/.config/claude/CLAUDE.md -> ../AGENTS.md
```

Fish sets `CODEX_HOME=~/.config/codex` and `CLAUDE_CONFIG_DIR=~/.config/claude`. These variables apply
to programs that inherit the Fish environment. Apps launched elsewhere can still use `~/.codex` or
`~/.claude`. The setup script only redirects `~/.agents`. Consolidating the other directories needs
a separate comparison of their config and saved state.

The shared skills use the same relative links on Linux and macOS:

```text
~/.agents                -> .config/agents
~/.config/agents/skills   -> ../../projects/skills
~/.config/claude/skills   -> ../agents/skills
```

Git tracks the two directory links here. The skills repository tracks their contents. New skills
in that checkout become available to both tools without additional links in this repository.
Both machines need the skills checkout at `~/projects/skills`. Claude's `simple-english` output
style also links into that checkout. Its vendor submodule must be initialized.

The skills repository pins `gh-stack`, `slidev`, and `simple-english` as upstream Git submodules.
Run `~/projects/skills/bin/setup` after pulling that repository to restore its recorded versions.
Run `~/projects/skills/bin/update-vendor` to fetch upstream updates for review. Commit those
revision changes in the skills repository, then pull and run setup on the other machine.

When upgrading from the old per-skill links, preserve an existing `claude/skills` directory before
pulling this repository. Untracked files inside it can prevent Git from replacing it with the
directory symlink. Move that directory to an unused backup path such as `claude/skills.before-repo`.
The old Codex copies are handled by `bin/setup-agents` after the pull.

Codex discovers user skills through `~/.agents/skills`, independently of `CODEX_HOME`. Claude reads
its personal skills from `$CLAUDE_CONFIG_DIR/skills`. Both tools support symlinked skill directories.
See the [Codex skills documentation](https://learn.chatgpt.com/docs/build-skills) and
[Claude skills documentation](https://code.claude.com/docs/en/skills).

`codex/config.toml` remains untracked and needs separate setup on a new machine. Plugin caches,
credentials, session history, and migration backups also stay untracked. Skill submodules contain
instructions, so the `gh stack` executable and Slidev project dependencies need their own installs.

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
