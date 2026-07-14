# Remove the default fish greeting.
set fish_greeting ""

# Set up all environment variables.
set -gx EDITOR hx
set -gx XDG_CONFIG_HOME "$HOME/.config"

# Abbreviations.
abbr -a cd z
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
abbr -a awsp "aws --profile PowerUserAccess-375504701696"

# Replace `cd` with `z` (`zoxide`).
if command -v z >/dev/null
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

# Set up the `PATH`. These directories exist on both machines and are added with `fish_add_path -g`
# (global, session scope) so the `PATH` is driven by this file rather than the now-untracked
# universal `fish_variables`.
fish_add_path -g $HOME/.cargo/bin $HOME/.local/bin

# Machine-specific environment and paths. Everything that legitimately differs between the Linux
# and macOS machines lives in this `switch`, keyed off `uname`, so the rest of this file stays
# byte-identical across both machines.
switch (uname)
    case Darwin
        # Route SSH (and therefore 1Password commit signing) through the 1Password SSH agent.
        set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

        # Homebrew and the Homebrew-provided LLVM and OpenJDK toolchains.
        fish_add_path -g /opt/homebrew/bin /opt/homebrew/opt/llvm/bin /opt/homebrew/opt/openjdk/bin

        # bun.
        set -gx BUN_INSTALL "$HOME/.bun"
        fish_add_path -g $BUN_INSTALL/bin

        # Wasmer.
        if test -d "$HOME/.wasmer"
            set -gx WASMER_DIR "$HOME/.wasmer"
            fish_add_path -g $WASMER_DIR/bin
        end
    case Linux
        # Statically-linked `clang-format`.
        fish_add_path -g /opt/clang-format-static
end

# Initialize `pnpm`.
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# Initialize the starship prompt.
if command -v starship >/dev/null
    starship init fish | source
end

# Initialize the zoxide autojumper.
if command -v zoxide >/dev/null
    zoxide init fish | source
end
