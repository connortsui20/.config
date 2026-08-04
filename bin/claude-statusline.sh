#!/usr/bin/env bash
# Claude Code statusLine command.
# Reads the Claude Code session JSON from stdin and renders the user's Starship
# prompt rooted at the session's working directory, so the status line mirrors
# the interactive shell prompt.  Claude-specific details that Starship cannot
# know (model name, context usage) are appended afterward.

input=$(cat)

# Extract the fields we need from the session JSON.
cwd=$(printf '%s' "$input" | jq -r '.cwd // .workspace.current_dir // empty')
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
used_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')

starship_out=""
if command -v starship >/dev/null 2>&1 && [ -n "$cwd" ]; then
    # STARSHIP_SHELL must be the empty "unknown" shell so Starship emits raw
    # ANSI escape codes.  The "bash" and "zsh" shells wrap colors in "\[ \]" or
    # "%{ %}" markers, and "fish" prepends an "ESC[J" erase-screen sequence,
    # none of which Claude Code's status line renderer understands.
    #
    # The session directory has to be passed as "--path", not through "$PWD".
    # Setting "$PWD" only changes the directory Starship *displays*; every
    # directory-sensitive module (git_branch, rust, and so on) still resolves
    # against this script's own working directory.  "--logical-path" keeps the
    # displayed path in agreement with the modules.
    raw=$(STARSHIP_SHELL="" starship prompt --path "$cwd" --logical-path "$cwd" 2>/dev/null)

    # Collapse Starship's multi-line prompt into a single status line: drop the
    # blank padding lines, drop the trailing prompt-character line (e.g. "❯"),
    # and join any remaining module lines with a single space.
    starship_out=$(printf '%s\n' "$raw" | awk '
        { lines[NR] = $0 }
        END {
            esc = sprintf("%c", 27)
            # Find the last non-blank line; it holds the prompt character.
            last = NR
            while (last > 0 && lines[last] ~ /^[ \t]*$/) last--
            # Strip ANSI codes and whitespace to test whether it is just a glyph.
            tail = lines[last]
            gsub(esc "\\[[0-9;?]*[a-zA-Z]", "", tail)
            gsub(/[ \t]/, "", tail)
            is_char = (tail == "❯" || tail == "➜" || tail == "$" \
                       || tail == "%" || tail == "❮" || tail == "#")
            out = ""
            for (i = 1; i <= NR; i++) {
                if (lines[i] ~ /^[ \t]*$/) continue
                if (is_char && i == last) continue
                out = (out == "" ? lines[i] : out " " lines[i])
            }
            printf "%s", out
        }
    ')
fi

# Build the Claude-specific suffix: model name and context usage when present.
claude_info=""
[ -n "$model" ] && claude_info="$model"
if [ -n "$used_pct" ]; then
    claude_info="$claude_info ctx:$(printf '%.0f' "$used_pct")%"
fi

# Emit the Starship output (already colored) followed by the dimmed Claude info.
if [ -n "$starship_out" ] && [ -n "$claude_info" ]; then
    printf '%s \033[2m[%s]\033[0m' "$starship_out" "$claude_info"
elif [ -n "$starship_out" ]; then
    printf '%s' "$starship_out"
elif [ -n "$claude_info" ]; then
    printf '\033[2m[%s]\033[0m' "$claude_info"
fi
