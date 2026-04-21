local dark_opacity = 0.9
local light_opacity = 0.9

---@type wezterm
local wezterm = require('wezterm')
local act = wezterm.action
local shortcuts = {}
local zoomed_tab_icon = utf8.char(0x26F6)

local config = wezterm.config_builder()

local map = function(key, mods, action)
  if type(mods) == "string" then
    table.insert(shortcuts, { key = key, mods = mods, action = action })
  elseif type(mods) == "table" then
    for _, mod in pairs(mods) do
      table.insert(shortcuts, { key = key, mods = mod, action = action })
    end
  end
end

-- config.color_scheme = "Catppuccin Mocha"
config.color_scheme = 'Darkmatter'
config.color_schemes = {
  ["Darkmatter"] = {
    foreground = "#ffffff",
    background = "#121113",
    cursor_fg = "#121113",
    cursor_bg = "#ffffff",
    cursor_border = "#ffffff",
    selection_fg = "#000000",
    selection_bg = "#222222",
    ansi = {
      "#121113", "#5f8787", "#fbcb97", "#e78a53",
      "#888888", "#999999", "#aaaaaa", "#c1c1c1"
    },
    brights = {
      "#333333", "#5f8787", "#fbcb97", "#e78a53",
      "#888888", "#999999", "#aaaaaa", "#c1c1c1"
    }
  }
}

function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'Darkmatter'
  else
    return 'Framer'
  end
end

local function tab_title(tab_info)
  local title = tab_info.tab_title
  if title and #title > 0 then
    return title
  end

  return tab_info.active_pane.title
end

wezterm.on('window-config-reloaded', function(window, _pane)
  local overrides = window:get_config_overrides() or {}
  local appearance = window:get_appearance()
  local scheme = scheme_for_appearance(appearance)
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end)

wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, _hover, max_width)
  local prefix = tostring(tab.tab_index + 1) .. ': '

  if tab.active_pane.is_zoomed then
    prefix = prefix .. zoomed_tab_icon .. ' '
  end

  local title_width = math.max(0, max_width - wezterm.column_width(prefix) - 2)
  local title = wezterm.truncate_right(tab_title(tab), title_width)

  return ' ' .. prefix .. title .. ' '
end)

config.adjust_window_size_when_changing_font_size = false
config.debug_key_events = false
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.enable_tab_bar = true --wezterm.target_triple == 'x86_64-pc-windows-msvc'
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.colors = {
  tab_bar = {
    background = '#121113',

    active_tab = {
      bg_color = '#e78a53',
      fg_color = '#121113',
      intensity = 'Normal',
      underline = 'None',
      italic = false,
      strikethrough = false,
    },

    inactive_tab = {
      bg_color = '#121113',
      fg_color = '#FFC9A9',
    },

    inactive_tab_hover = {
      bg_color = '#333333',
      fg_color = '#fbcb97',
    },

    new_tab = {
      bg_color = '#121113',
      fg_color = '#999999',
    },

    new_tab_hover = {
      bg_color = '#333333',
      fg_color = '#fbcb97',
    },

    inactive_tab_edge = '#121113',
  },
}
config.inactive_pane_hsb = {
  saturation = 0,
  brightness = 1,
}
config.text_background_opacity = 1
config.window_padding = {
  left = 10,
  right = 10,
  top = 6,
  bottom = 6
}

config.leader = {
  key = 'b',
  mods = 'CTRL',
  timeout_milliseconds = math.maxinteger
}

-- KEY BINDINGS
-- 'hjkl' to move between panes
map("h", { "CTRL" }, act.ActivatePaneDirection("Left"))
map("j", { "CTRL" }, act.ActivatePaneDirection("Down"))
map("k", { "CTRL" }, act.ActivatePaneDirection("Up"))
map("l", { "CTRL" }, act.ActivatePaneDirection("Right"))

map("|", "LEADER|SHIFT", act.SplitHorizontal({ domain = 'CurrentPaneDomain' }))
map("-", "LEADER", act.SplitVertical({ domain = 'CurrentPaneDomain' }))
map("Tab", "CTRL", act.ActivateWindowRelative(1))
map("Tab", "CTRL|SHIFT", act.ActivateWindowRelative(-1))
map("c", "LEADER", act.SpawnTab('CurrentPaneDomain'))
map("z", "LEADER", act.TogglePaneZoomState)
map("n", "LEADER", act.ActivateTabRelative(1))
map("p", "LEADER", act.ActivateTabRelative(-1))
for i = 1, 9 do
  map(tostring(i), "LEADER", act.ActivateTab(i - 1))
  map(tostring(i), "ALT", act.ActivateTab(i - 1))
end
map("x", "LEADER", act.CloseCurrentTab({ confirm = true }))
map("P", "CTRL", act.ActivateCommandPalette)
map("r", "LEADER", act.ReloadConfiguration)
map("w", "LEADER", act.ShowTabNavigator)
map("$", "LEADER|SHIFT", act.PromptInputLine({
  description = 'Enter new name for tab:',
  action = wezterm.action_callback(function(window, _, line)
    if line then
      window:active_tab():set_title(line)
    end
  end),
}))

-- send <c-b> to terminal when pressing <c-b> <c-b>
map("b", "LEADER|CTRL", act.SendKey { key = 'b', mods = "CTRL" })

map("r", "LEADER", act.ActivateKeyTable({
  name = "resize_mode",
  one_shot = false,
}))

local key_tables = {
  resize_mode = {
    { key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
    { key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
    { key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
    { key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },
    { key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
    { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
  },
}

-- add a common escape sequence to all key tables
for k, _ in pairs(key_tables) do
  table.insert(key_tables[k], { key = "Escape", action = "PopKeyTable" })
  table.insert(key_tables[k], { key = "Enter", action = "PopKeyTable" })
  table.insert(
    key_tables[k],
    { key = "c", mods = "CTRL", action = "PopKeyTable" }
  )
end


----- PLATFORM SPECIFIC CONFIG
if wezterm.target_triple == 'aarch64-apple-darwin' then
    config.font = wezterm.font_with_fallback({
        "BerkeleyMono Nerd Font",
        { family = "BerkeleyMono", weight = "Bold" },
    })
    config.font_size = 14
    config.window_background_opacity = dark_opacity
    config.macos_window_background_blur = 20

elseif wezterm.target_triple == 'x86_64-pc-windows-msvc' then

    config.default_prog = { 'pwsh', '-nologo' }
    config.font = wezterm.font_with_fallback({
        -- "JetBrainsMono Nerd Font",
        "BerkeleyMono Nerd Font",
        { family = "Symbols Nerd Font Mono", weight = "Bold" },
    })
    config.font_size = 10

    config.window_frame = {
      font = wezterm.font_with_fallback({
          -- "JetBrainsMono Nerd Font",
          "BerkeleyMono Nerd Font",
          { family = "Symbols Nerd Font Mono", weight = "Bold" },
      }),
      font_size = 10.0,
      -- active_titlebar_bg = '#333333',
      -- inactive_titlebar_bg = '#575757',
    }
    local mux = wezterm.mux
    wezterm.on("gui-startup", function()
      local tab, pane, window = mux.spawn_window {}
      window:gui_window():maximize()
    end)
    wezterm.on("window-config", function(window, pane)
      window:gui_window():maximize()
    end)

    config.window_background_opacity = dark_opacity
    config.win32_system_backdrop = 'Disable'
    config.tab_max_width = 50
else
    config.font = wezterm.font_with_fallback({
        "BerkeleyMono Nerd Font",
        { family = "Symbols Nerd Font Mono", weight = "Bold" },
    })
    config.font_size = 10
end

if wezterm.target_triple ~= 'x86_64-pc-windows-msvc' then
  -- map("Tab", "CTRL", act.Multiple({
  --   act.SendKey({ mods = "CTRL", key = "b" }),
  --   act.SendKey({ key = "n" }))
  -- })
  --
  -- map("Tab", "CTRL|SHIFT", act.Multiple({
  --   act.SendKey({ mods = "CTRL", key = "b" }),
  --   act.SendKey({ key = "n" }),
  -- }))
  --
  -- map("k", "CMD", act.Multiple({
  --   act.SendKey({ mods = "CTRL", key = "b" }),
  --   act.SendKey({ mods = "SHIFT", key = "k" }),
  -- }))

  -- Turn off the default CMD-m Hide action, allowing CMD-m to
  -- be potentially recognized and handled by the tab
  map("m", "CMD", act.DisableDefaultAssignment)
  map("h", "CMD", act.DisableDefaultAssignment)
  map("~", "CMD", act.Multiple({
    act.SendKey({ mods = "CTRL", key = "b" }),
    act.SendKey({ key = "p" }),
  }))

end

config.keys = shortcuts
-- config.disable_default_key_bindings = true
config.key_tables = key_tables

return config
