# Remove the default fish greeting.
set fish_greeting ""

# Add git ssh keys.
eval (ssh-agent -c) >/dev/null
ssh-add "$HOME/.ssh/git"
clear

echo ""

if status is-interactive
    fastfetch
end

# Set up all environment variables.
set -gx EDITOR hx
set -gx XDG_CONFIG_HOME "$HOME/.config"

# Abbreviations.
abbr -a cd z
abbr -a pd "cd .."
abbr -a c cargo
abbr -a g git
abbr -a gp git push
abbr -a m "make -j (nproc)"
abbr -a mc "make clean"
abbr -a configs "cd ~/.config"
abbr -a projects "cd ~/projects"
abbr -a stuco "cd ~/CMU/rust-stuco"
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

starship init fish | source

zoxide init fish | source
