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
   ```

   The skills repository owns installation for both agents, including skill links and the
   Simple English output style. It works independently of this dotfiles repository.
   `bin/setup-agents` remains a convenience wrapper for that command and forwards its arguments.

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
`~/.claude`. Skill setup respects these variables and existing directory aliases. Consolidating
other agent directories needs a separate comparison of their config and saved state.

The skills repository owns setup on Linux and macOS. Run `~/projects/skills/bin/setup` after
pulling it. The command restores pinned submodules and installs individual skill links into each
agent's skill directory. It also installs Claude's Simple English output style. Use `--dry-run`
to preview link changes, or `--check` to verify the checkout without changing files.

This machine retains its directory aliases:

```text
~/.agents                -> .config/agents
~/.config/claude/skills   -> ../agents/skills
~/.config/agents/skills/  # Local directory, ignored by Git
```

The installer follows these aliases without requiring them. On a machine without the dotfiles
checkout, it uses the agents' standard directories. This repository tracks the Claude directory
alias, but the generated skill links and local installations stay ignored.

Install machine-specific skills through their own installers. Rex's skill stays outside the shared
skills repository and its web bundle. The shared Claude startup hook uses Rex when it is installed
and exits silently when it is absent. MCP server configuration and credentials remain local.

The skills installer preserves local skills and stops on name conflicts. It replaces old
whole-checkout directory links and removes obsolete links to that checkout. If installers left
untracked skills or `synced/` in `~/projects/skills`, move them into the local skills directory after
setup. Old Codex copies of `gh-stack` and `slidev` move to `$CODEX_HOME/skills.before-shared`.

Run `~/projects/skills/bin/update-vendor` to fetch upstream skill updates for review. Commit those
revision changes in the skills repository, then pull and run its setup on the other machine.

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
