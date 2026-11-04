-- Persona look for Hyprland's Lua config (hl.config). Source this after your own decorations.
local P_RED   = "rgba(e60012ff)"
local P_WHITE = "rgba(f4f4f4ff)"
local P_INK   = "rgba(1a1a1aee)"
local P_GLOW  = "rgba(e6001288)"

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 3,
        col = {
            active_border = { colors = { P_RED, P_RED, P_WHITE }, angle = 135 },
            inactive_border = P_INK,
        },
    },
    decoration = {
        rounding = 0,
        dim_inactive = true,
        dim_strength = 0.12,
        blur = { enabled = true, size = 8, passes = 3, vibrancy = 0.3, noise = 0.02 },
        shadow = { enabled = true, range = 22, render_power = 2, color = P_GLOW, color_inactive = "rgba(00000066)" },
    },
})

hl.on("hyprland.start", function ()
    hl.exec_cmd("caelestia shell -d")
    hl.exec_cmd("qs -c persona-bar -n -d")
end)
