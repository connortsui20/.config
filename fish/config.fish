# Remove the default fish greeting
set fish_greeting ""

# Add git ssh keys
eval (ssh-agent -c) >/dev/null
ssh-add "$HOME/.ssh/git_personal_key"
ssh-add "$HOME/.ssh/git_cmu_key"
clear

echo ""

if status is-interactive
    neofetch
end

# Setup all environment variables
set -gx EDITOR hx
set -gx XDG_CONFIG_HOME "$HOME/.config"

# Abbreviations
abbr -a pd "cd .."
abbr -a c cargo
abbr -a g git
abbr -a m "make -j (nproc)"
abbr -a mc "make clean"
abbr -a configs "cd ~/.config"
abbr -a stuco "cd ~/CMU/rust-stuco"
abbr -a afs "ssh -X cjtsui@linux.andrew.cmu.edu"
abbr -a sshome "ssh connor@home.connortsui.com -p 2020"
abbr -a 445 "cd ~/CMU/CMU-F24/15-445"
abbr -a 363 "cd ~/CMU/CMU-F24/17-363"
abbr -a sasy "java -jar ~/CMU/CMU-F24/17-363/bin/org.sasylf_1.5.1.v20210902.jar"

# Replace ls with exa
if command -v exa >/dev/null
    abbr -a ls exa
    abbr -a la "exa -a"
    abbr -a ll "exa -al"
    abbr -a lst "exa --tree"
else
    abbr -a la "ls -a"
    abbr -a ll "ls -al"
end

# Replace cat with bat
if command -v bat >/dev/null
    abbr -a cat bat
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

function yy
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

starship init fish | source
