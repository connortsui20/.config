# Remove the default fish greeting
set fish_greeting ""

# Add git ssh keys
eval (ssh-agent -c) > "/dev/null"
ssh-add "$HOME/.ssh/git_personal_key"
ssh-add "$HOME/.ssh/git_cmu_key"
clear

echo ""

if status is-interactive
    neofetch
end

# Setup all environment variables
set -gx EDITOR "hx"
set -gx XDG_CONFIG_HOME "$HOME/.config"

# Abbreviations
abbr -a "pd" "cd .."
abbr -a "c" "cargo"
abbr -a "g" "git"
abbr -a "configs" "cd ~/.config"
abbr -a "bustub" "cd ~/CMU/CMU-F23/15-445/mybustub"

# Replace ls with exa
if command -v "exa" > "/dev/null"
    abbr -a "ls" "exa"
    abbr -a "la" "exa -a"
    abbr -a "ll" "exa -al"
    abbr -a "lst" "exa --tree"
else
    abbr -a "la" "ls -a"
    abbr -a "ll" "ls -al"
end

# Type d to move up to top parent dir which is a repository
function d
    while test $PWD != $HOME
        if test -d ".git"
            break
        end
        cd ..
    end
end
