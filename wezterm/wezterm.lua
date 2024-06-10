local dark_opacity = 0.85
local light_opacity = 0.9

local wezterm = require('wezterm')
local act = wezterm.action

local config = wezterm.config_builder()

config.color_scheme = "Framer"

if wezterm.target_triple == 'aarch64-apple-darwin' then
    config.font = wezterm.font_with_fallback({
        "Berkeley Mono",
        { family = "Symbols Nerd Font Mono", weight = "Bold" },
    })
    config.font_size = 12
elseif wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    config.window_background_opacity = 0
    config.win32_system_backdrop = 'Mica'
    config.font = wezterm.font_with_fallback({
        "BerkeleyMono Nerd Font",
        { family = "Symbols Nerd Font Mono", weight = "Bold" },
    })
    config.font_size = 10
else
    config.font = wezterm.font_with_fallback({
        "BerkeleyMono Nerd Font",
        { family = "Symbols Nerd Font Mono", weight = "Bold" },
    })
    config.font_size = 10
end

config.adjust_window_size_when_changing_font_size = false
config.debug_key_events = false
config.enable_tab_bar = true --wezterm.target_triple == 'x86_64-pc-windows-msvc'
config.tab_bar_at_bottom = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.use_fancy_tab_bar = false

-- local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
-- local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider
--
-- config.tab_bar_style = {
--   active_tab_left = wezterm.format {
--     { Background = { Color = '#0b0022' } },
--     { Foreground = { Color = '#2b2042' } },
--     { Text = SOLID_LEFT_ARROW },
--   },
--   active_tab_right = wezterm.format {
--     { Background = { Color = '#0b0022' } },
--     { Foreground = { Color = '#2b2042' } },
--     { Text = SOLID_RIGHT_ARROW },
--   },
--   inactive_tab_left = wezterm.format {
--     { Background = { Color = '#0b0022' } },
--     { Foreground = { Color = '#1b1032' } },
--     { Text = SOLID_LEFT_ARROW },
--   },
--   inactive_tab_right = wezterm.format {
--     { Background = { Color = '#0b0022' } },
--     { Foreground = { Color = '#1b1032' } },
--     { Text = SOLID_RIGHT_ARROW },
--   },
-- }

if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    config.window_frame = {
      font = wezterm.font_with_fallback({
          "BerkeleyMono Nerd Font",
          { family = "Symbols Nerd Font Mono", weight = "Bold" },
      }),
      font_size = 10.0,
      active_titlebar_bg = '#333333',
      inactive_titlebar_bg = '#575757',
    }
    config.colors = {
      tab_bar = {
        inactive_tab_edge = '#575757',
      }
    }
    config.window_background_opacity = 0.5
    config.win32_system_backdrop = 'Tabbed'
    config.default_prog = { 'pwsh', '-nologo' }

    config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 1000 }
    config.keys = {
      {
        key = "|",
        mods = "LEADER|SHIFT",
        action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }
      },
      {
        key = "-",
        mods = "LEADER",
        action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }
      },
      {
        key = "c",
        mods = "LEADER",
        action = wezterm.action.SpawnTab 'CurrentPaneDomain',
      },
      {
        key = "p",
        mods = "LEADER",
        action = wezterm.action.ActivateTabRelative(-1),
      },
      {
        key = "n",
        mods = "LEADER",
        action = wezterm.action.ActivateTabRelative(1),
      },
      {
        key = "x",
        mods = "LEADER",
        action = wezterm.action.CloseCurrentTab { confirm = true },
      },
      {
        key = 'P',
        mods = 'CTRL',
        action = wezterm.action.ActivateCommandPalette,
      },
      {
        key = 'r',
        mods = 'LEADER',
        action = wezterm.action.ReloadConfiguration,
      },
      { key = 'w', mods = 'LEADER', action = wezterm.action.ShowTabNavigator },
      -- send <c-b> to terminal when pressing <c-b> <c-b>
      {
        key = "b",
        mods = "LEADER|CTRL",
        action = wezterm.action.SendKey { key = 'b', mods = "CTRL" },
      },
    }
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
