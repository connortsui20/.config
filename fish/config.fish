# Add git ssh keys
eval (ssh-agent -c) > /dev/null
ssh-add "$HOME/.ssh/desktop_personal_key"
ssh-add "$HOME/.ssh/desktop_cmu_key"
echo ""
# clear

if status is-interactive
    neofetch
end

# Setup all environment variables
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx HELIX_RUNTIME "$HOME/.config/helix/runtime"
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.local/bin"

abbr -a "pd" "cd .."
abbr -a "c" "cargo"
abbr -a "g" "git"
abbr -a "python" "python3"
abbr -a "configs" "cd ~/.config"

# Replace ls with exa
if command -v exa > /dev/null
    abbr -a "ls" "exa"
    abbr -a "la" "exa -a"
    abbr -a "ll" "exa -al"
    abbr -a "lst" "exa --tree"
else
    abbr -a "la" "ls -a"
    abbr -a "ll" "ls -al"
end

# Type - to move up to top parent dir which is a repository
function d
    while test $PWD != $HOME
        if test -d .git
            break
        end
        cd ..
    end
end



