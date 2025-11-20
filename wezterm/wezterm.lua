local dark_opacity = 0.85
local light_opacity = 0.9

---@type wezterm
local wezterm = require('wezterm')
local act = wezterm.action
local shortcuts = {}

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

config.color_scheme = "Catppuccin Mocha"

function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'Framer'
  else
    return 'Framer'
  end
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

config.adjust_window_size_when_changing_font_size = false
config.debug_key_events = false
config.enable_tab_bar = true --wezterm.target_triple == 'x86_64-pc-windows-msvc'
config.tab_bar_at_bottom = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.use_fancy_tab_bar = false
config.inactive_pane_hsb = {
  saturation = 0,
  brightness = 1,
}
config.text_background_opacity = 1
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
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
map("x", "LEADER", act.CloseCurrentTab({ confirm = true }))
map("P", "CTRL", act.ActivateCommandPalette)
map("r", "LEADER", act.ReloadConfiguration)
map("w", "LEADER", act.ShowTabNavigator)

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
        "Berkeley Mono",
        { family = "Symbols Nerd Font Mono", weight = "Bold" },
    })
    config.font_size = 12

elseif wezterm.target_triple == 'x86_64-pc-windows-msvc' then

    config.default_prog = { 'pwsh', '-nologo' }
    config.window_background_opacity = 0
    config.win32_system_backdrop = 'Mica'
    config.font = wezterm.font_with_fallback({
        "BerkeleyMono Nerd Font",
        { family = "Symbols Nerd Font Mono", weight = "Bold" },
    })
    config.font_size = 10

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
    local mux = wezterm.mux
    wezterm.on("gui-startup", function()
      local tab, pane, window = mux.spawn_window {}
      window:gui_window():maximize()
    end)
    wezterm.on("window-config", function(window, pane)
      window:gui_window():maximize()
    end)

    config.window_background_opacity = .85
    config.win32_system_backdrop = 'Tabbed'

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
