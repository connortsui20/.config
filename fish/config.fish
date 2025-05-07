# Remove the default fish greeting.
set fish_greeting ""

if status is-interactive
    fastfetch
end

# Set up all environment variables.
set -gx EDITOR hx
set -gx XDG_CONFIG_HOME "$HOME/.config"

# Abbreviations.
abbr -a cd z
abbr -a pd "z .."
abbr -a c cargo
abbr -a g git
abbr -a gp git push
abbr -a m "make -j (nproc)"
abbr -a mc "make clean"
abbr -a sshome "ssh connor@home.connortsui.com -p 2020"

# Replace `cd` with `z` (`zoxide`).
if command -v z >/dev/null
    abbr -a cd z
end

# Replace `ls` with `exa`.
if command -v exa >/dev/null
    abbr -a ls exa
    abbr -a la "exa -a"
    abbr -a ll "exa -al"
    abbr -a lst "exa --tree"
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

# Initialize starship prompter.
starship init fish | source

# Initialize zoxide autojumper.
zoxide init fish | source
