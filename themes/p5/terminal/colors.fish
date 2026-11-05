# Persona terminal colours: fish syntax highlighting + fzf, red / ink / paper with a gold accent.
# Pair with starship/starship.toml (prompt) and kitty/persona.conf (terminal palette).
status is-interactive; or return

# persona fzf: ink / paper / red
set -gx FZF_DEFAULT_OPTS "--height=40% --layout=reverse --border=sharp \
--color=bg+:#5c0007,bg:-1,spinner:#ffcc00,hl:#e60012,fg:#c8c8c8,header:#f4f4f4,\
info:#8a8a8a,pointer:#e60012,marker:#ffcc00,fg+:#ffffff,prompt:#e60012,hl+:#ff3344,border:#e60012"

# persona syntax colours (red commands, paper args, gold strings/errors)
set -g fish_color_command e60012 --bold
set -g fish_color_keyword e60012 --bold
set -g fish_color_param f4f4f4
set -g fish_color_option c8c8c8
set -g fish_color_quote ffcc00
set -g fish_color_redirection ff3344
set -g fish_color_operator ff3344
set -g fish_color_end ff3344
set -g fish_color_escape ff7a90
set -g fish_color_error ffcc00 --underline
set -g fish_color_comment 6a6a6a --italics
set -g fish_color_autosuggestion 5a5a5a
set -g fish_color_valid_path --underline
set -g fish_color_cancel e60012
set -g fish_color_selection --background=5c0007
set -g fish_color_search_match --background=5c0007
set -g fish_pager_color_prefix e60012 --bold
set -g fish_pager_color_completion f4f4f4
set -g fish_pager_color_description 8a8a8a
set -g fish_pager_color_progress ffffff --background=e60012
set -g fish_pager_color_selected_background --background=5c0007
