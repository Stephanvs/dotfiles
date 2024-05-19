local dark_opacity = 0.85
local light_opacity = 0.9

local wezterm = require('wezterm')
local act = wezterm.action

local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"

if wezterm.target_triple ~= 'x86_64-pc-windows-msvc' then
    config.font = wezterm.font_with_fallback({
        "Berkeley Mono",
        { family = "Symbols Nerd Font Mono", weight = "Bold" },
    })
    config.font_size = 12
else
    config.font = wezterm.font_with_fallback({
        "BerkeleyMono Nerd Font",
        { family = "Symbols Nerd Font Mono", weight = "Bold" },
    })
    config.font_size = 14
end

config.adjust_window_size_when_changing_font_size = false
config.debug_key_events = false
config.enable_tab_bar = wezterm.target_triple == 'x86_64-pc-windows-msvc'
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    config.default_prog = { 'pwsh', '-nologo' }
end

if wezterm.target_triple ~= 'x86_64-pc-windows-msvc' then
    config.keys = {
        {
            mods = "CTRL",
            key = "Tab",
            action = act.Multiple({
                act.SendKey({ mods = "CTRL", key = "b" }),
                act.SendKey({ key = "n" }),
            }),
        },
        {
            mods = "CTRL|SHIFT",
            key = "Tab",
            action = act.Multiple({
                act.SendKey({ mods = "CTRL", key = "b" }),
                act.SendKey({ key = "n" }),
            }),
        },
        {
            mods = "CMD",
            key = "k",
            action = act.Multiple({
                act.SendKey({ mods = "CTRL", key = "b" }),
                act.SendKey({ mods = "SHIFT", key = "k" }),
            }),
        },
        -- {
        -- Turn off the default CMD-m Hide action, allowing CMD-m to
        -- be potentially recognized and handled by the tab
        {
            mods = 'CMD',
            key = 'm',
            action = wezterm.action.DisableDefaultAssignment,
        },
        {
            mods = 'CMD',
            key = 'h',
            action = wezterm.action.DisableDefaultAssignment,
        },
        -- {
        --     mods = "CMD",
        --     key = "~",
        --     action = act.Multiple({
        --         act.SendKey({ mods = "CTRL", key = "b" }),
        --         act.SendKey({ key = "p" }),
        --     }),
        -- },
    }
end

return config
