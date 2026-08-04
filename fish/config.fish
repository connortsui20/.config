# Remove the default fish greeting.
set fish_greeting ""

# Set up all environment variables.
set -gx EDITOR hx
set -gx XDG_CONFIG_HOME "$HOME/.config"

# Keep Claude Code's config under `$XDG_CONFIG_HOME` instead of the default `~/.claude`.
set -gx CLAUDE_CONFIG_DIR "$XDG_CONFIG_HOME/claude"
set -gx CODEX_HOME "$XDG_CONFIG_HOME/codex"

# Relocate state that predates the two variables above. A machine configured before they existed
# keeps its credentials and history under `~/.claude` and `~/.codex`, and both tools would otherwise
# start up looking like fresh installs. The sentinel is a file that only exists once the new
# location has been used, so this runs at most once per machine and is a no-op everywhere else. It 
# has to run here, ahead of anything that might launch either tool.
function __migrate_state_dir --argument-names old new sentinel
    test -d "$old" -a ! -e "$new/$sentinel" || return 0

    if not command -v rsync >/dev/null
        echo "$old needs migrating to $new, but rsync is not installed." >&2
        return 1
    end

    # The excludes protect the tracked files that already live in the destination.
    echo "Migrating $old to $new." >&2
    rsync -a --exclude settings.json --exclude .gitignore "$old/" "$new/"
end

__migrate_state_dir "$HOME/.claude" "$CLAUDE_CONFIG_DIR" projects
__migrate_state_dir "$HOME/.codex" "$CODEX_HOME" auth.json
functions -e __migrate_state_dir

# Abbreviations.
abbr -a pd "z .."
abbr -a c cargo
abbr -a g git
abbr -a gp "git push"
abbr -a gs "git status"
abbr -a gl "git log"
abbr -a gb "git branch"
abbr -a m "make -j (nproc)"
abbr -a mc "make clean"
abbr -a sshome "ssh connor@home.connortsui.com -p 2020"

# Replace `cd` with `z` (`zoxide`). This tests for `zoxide` rather than `z`, because `z` is a
# function that does not exist until `zoxide init fish` runs at the bottom of this file.
if command -v zoxide >/dev/null
    abbr -a cd z
end

# Replace `ls` with `eza`.
if command -v eza >/dev/null
    abbr -a ls eza
    abbr -a la "eza -a"
    abbr -a ll "eza -al"
    abbr -a lst "eza --tree"
else
    abbr -a la "ls -a"
    abbr -a ll "ls -al"
end

# Replace `cat` with `bat`.
if command -v bat >/dev/null
    abbr -a cat bat
end

# Type d to move up to top parent dir which is a repository.
function d
    while test $PWD != $HOME
        if test -d ".git"
            break
        end
        cd ..
    end
end

# `fish_user_paths` used to live in the universal `fish_variables`, which synced through git and so
# leaked each machine's paths into the other. It is untracked now, but an existing universal value
# survives on disk and still seeds the `PATH` ahead of everything below, because `fish_add_path`
# skips directories that are already present. Erase it so this file is the only thing that decides
# the `PATH`. The `-qU` guard keeps this from rewriting `fish_variables` on every shell startup.
if set -qU fish_user_paths
    set -eU fish_user_paths
end

# Machine-specific environment and paths. Everything that legitimately differs between the Linux
# and macOS machines lives in this `switch`, keyed off `uname`, so the rest of this file stays
# byte-identical across both machines.
switch (uname)
    case Darwin
        # Route SSH (and therefore 1Password commit signing) through the 1Password SSH agent.
        set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

        # Homebrew and the Homebrew-provided LLVM and OpenJDK toolchains.
        fish_add_path -gm /opt/homebrew/bin /opt/homebrew/opt/llvm/bin /opt/homebrew/opt/openjdk/bin

        # bun.
        set -gx BUN_INSTALL "$HOME/.bun"
        fish_add_path -gm $BUN_INSTALL/bin

        # Wasmer.
        if test -d "$HOME/.wasmer"
            set -gx WASMER_DIR "$HOME/.wasmer"
            fish_add_path -gm $WASMER_DIR/bin
        end
    case Linux
        # Statically-linked `clang-format`.
        fish_add_path -gm /opt/clang-format-static
end

# Initialize `pnpm`. This sets `PATH` directly rather than going through `fish_add_path`, because
# `fish_add_path` skips directories that do not exist yet and `PNPM_HOME` is not created until the
# first global install.
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# Directories that exist on both machines. These come last on purpose: `-m` (`--move`) makes every
# `fish_add_path` prepend unconditionally, so the last call wins and `rustup`'s toolchain shadows
# anything Homebrew or `pnpm` installs under the same name.
fish_add_path -gm $HOME/.cargo/bin $HOME/.local/bin

# Initialize the starship prompt.
if command -v starship >/dev/null
    starship init fish | source
end

# Initialize the zoxide autojumper.
if command -v zoxide >/dev/null
    zoxide init fish | source
end

# Machine-local settings, sourced last so it can override anything above. This is also where
# anything that should not be in a public repository belongs (account identifiers, work hostnames).
# The file is gitignored; see `config.local.fish.example` for the template.
if test -f "$XDG_CONFIG_HOME/fish/config.local.fish"
    source "$XDG_CONFIG_HOME/fish/config.local.fish"
end
