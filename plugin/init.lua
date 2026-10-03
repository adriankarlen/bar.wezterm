local wez = require "wezterm"

---@class bar.wezterm
local M = {}
local options = {}

---looks up an ansi index in a palette. indices 1-8 select the normal colors
---and 9-16 their bright counterparts, so a bright color is its base plus 8.
---returns nil for an index the palette does not define.
---@param index number
---@param palette table
---@return string|nil
local function ansi_color(index, palette)
  if index > 8 then
    return palette.brights and palette.brights[index - 8]
  end
  return palette.ansi and palette.ansi[index]
end

---resolves a color option: a number is an ansi index as ansi_color reads it,
---the keywords "background" and "foreground" take the scheme's own, and
---anything else is treated as a color string. resolve_rule_color below is a
---deliberately stricter sibling used on the rule-drawing path; the two are
---not interchangeable and must not be merged.
---@param value string|number|nil
---@param scheme table
---@param fallback string
---@return string
local function resolve_color(value, scheme, fallback)
  if type(value) == "number" then
    return ansi_color(value, scheme) or fallback
  end
  if value == "background" then
    return scheme.background
  end
  if value == "foreground" then
    return scheme.foreground
  end
  return value or fallback
end

---resolves a rule's color against the palette in force while drawing.
---a number is an ansi index, a string is a literal color, anything else
---or an index the scheme does not define falls back to the base color.
---@param value string|number|nil
---@param palette table
---@param fallback string
---@return string
local function resolve_rule_color(value, palette, fallback)
  if type(value) == "number" then
    return ansi_color(value, palette) or fallback
  end
  if type(value) == "string" then
    return value
  end
  return fallback
end

---how far a derived hover color moves from the color it highlights, and the
---smallest perceptual distance that move has to cover to count as visible at
---all. the threshold is the just-noticeable difference for CIE delta E, so it
---rejects only a move nobody could see rather than a merely subtle one.
local HIGHLIGHT_SHIFT = 0.4
local HIGHLIGHT_MIN_DELTA = 2.3

---moves a color away from the background it sits on, in whichever direction
---gains contrast. a color that cannot be parsed, or that has nothing to move
---because it is fully transparent, is handed back untouched.
---@param color string
---@param background string|nil
---@return string
local function shift_from(color, background)
  local parsed, base = pcall(wez.color.parse, color)
  if not parsed then
    return color
  end

  local _, _, _, alpha = base:hsla()
  if alpha == 0 then
    return color
  end

  local lighter = base:lighten(HIGHLIGHT_SHIFT)
  local darker = base:darken(HIGHLIGHT_SHIFT)

  local known, back = pcall(wez.color.parse, background)
  if not known then
    return tostring(lighter)
  end

  local pick, other = darker, lighter
  if lighter:contrast_ratio(back) >= darker:contrast_ratio(back) then
    pick, other = lighter, darker
  end

  -- a color already pressed against black or white has no room left to move
  -- in the direction that gains contrast, so take the other one rather than
  -- return a shift nobody can see
  if base:delta_e(pick) < HIGHLIGHT_MIN_DELTA then
    pick = other
  end

  return tostring(pick)
end

---derives the color that highlights `value` while the pointer is over it: the
---scheme's bright counterpart when the scheme gives it one that differs, and
---otherwise a shade shifted away from the background. many popular schemes
---(catppuccin, rose-pine, tokyo night, gruvbox) define most of their brights
---identically to the normal colors, which is why the second half is needed.
---@param value string|number|nil
---@param scheme table
---@param fallback string
---@return string
local function highlight(value, scheme, fallback)
  local base = resolve_color(value, scheme, fallback)

  if type(value) == "number" and value >= 1 and value <= 8 then
    local bright = ansi_color(value + 8, scheme)
    if bright and bright ~= base then
      return bright
    end
  end

  return shift_from(base, scheme.background)
end

---resolves a hover color: an explicit setting wins, and without one the color
---is derived from whichever color it covers
---@param value string|number|nil
---@param base string|number|nil
---@param scheme table
---@param fallback string
---@return string
local function resolve_hover_color(value, base, scheme, fallback)
  if value ~= nil then
    return resolve_color(value, scheme, fallback)
  end
  return highlight(base, scheme, fallback)
end

---resolves a hovered tab's color from what the matching rules set, falling
---back to the hover color already resolved into the palette
---@param value string|number|nil
---@param base string|number|nil
---@param palette table
---@param fallback string
---@return string
local function resolve_rule_hover_color(value, base, palette, fallback)
  if value ~= nil then
    return resolve_rule_color(value, palette, fallback)
  end
  if base ~= nil then
    return highlight(base, palette, fallback)
  end
  return fallback
end

---builds tab_bar colors block from a resolved color scheme
---@param scheme table
---@return table
local function build_tab_bar_colors(scheme)
  local tabs = options.modules.tabs

  -- the new tab button borrows the generic hover color before falling back to
  -- one derived from its own base, so a single tab_hover_fg is enough to light
  -- up everything the pointer can reach
  local new_tab_hover_fg = tabs.new_tab_hover_fg or tabs.tab_hover_fg
  local new_tab_hover_bg = tabs.new_tab_hover_bg or tabs.tab_hover_bg

  return {
    tab_bar = {
      background = "transparent",
      active_tab = {
        bg_color = resolve_color(tabs.active_tab_bg, scheme, "transparent"),
        fg_color = resolve_color(tabs.active_tab_fg, scheme, "white"),
      },
      inactive_tab = {
        bg_color = resolve_color(tabs.inactive_tab_bg, scheme, "transparent"),
        fg_color = resolve_color(tabs.inactive_tab_fg, scheme, "white"),
      },
      -- wezterm's own default for this block carries an italic, which the
      -- blocks above leave off; spelling it out keeps a hovered tab styled
      -- like every other one
      inactive_tab_hover = {
        bg_color = resolve_hover_color(tabs.tab_hover_bg, tabs.inactive_tab_bg, scheme, "transparent"),
        fg_color = resolve_hover_color(tabs.tab_hover_fg, tabs.inactive_tab_fg, scheme, "white"),
      },
      new_tab = {
        bg_color = resolve_color(tabs.new_tab_bg, scheme, "transparent"),
        fg_color = resolve_color(tabs.new_tab_fg, scheme, "white"),
      },
      new_tab_hover = {
        bg_color = resolve_hover_color(new_tab_hover_bg, tabs.new_tab_bg, scheme, "transparent"),
        fg_color = resolve_hover_color(new_tab_hover_fg, tabs.new_tab_fg, scheme, "white"),
      },
    },
  }
end

local separator = package.config:sub(1, 1) == "\\" and "\\" or "/"
local plugin_dir = wez.plugin.list()[1].plugin_dir:gsub(separator .. "[^" .. separator .. "]*$", "")

---checks if the plugin directory exists
---@param path string
---@return boolean
local function directory_exists(path)
  local success = pcall(wez.read_dir, plugin_dir .. path)
  return success
end

---returns the name of the package, used when requiring modules
---@return string
local function get_require_path()
  local path = "httpssCssZssZsgithubsDscomsZsadriankarlensZsbarsDswezterm"
  local path_trailing_slash = "httpssCssZssZsgithubsDscomsZsadriankarlensZsbarsDsweztermsZs"
  return directory_exists(path_trailing_slash) and path_trailing_slash or path
end

package.path = package.path
  .. ";"
  .. plugin_dir
  .. separator
  .. get_require_path()
  .. separator
  .. "plugin"
  .. separator
  .. "?.lua"

local utilities = require "bar.utilities"
local config = require "bar.config"
local rules = require "bar.rules"
local tabs = require "bar.tabs"
local user = require "bar.user"
local spotify = require "bar.spotify"
local paths = require "bar.paths"

---finds the palette to read tab colors from. a config may name a builtin
---scheme, name one it defines itself, name none at all, or set colors without
---naming anything; every one of those has to end up with a palette, because a
---config left without colors.tab_bar leaves the handlers below with no colors
---to draw from at all.
---@param c table: wezterm config object
---@return table
local function resolve_scheme(c)
  local named = c.color_scheme
  local scheme = named and wez.color.get_builtin_schemes()[named]
    or named and type(c.color_schemes) == "table" and c.color_schemes[named]
    or wez.color.get_default_colors()

  -- colors set alongside a scheme win over it, the same way wezterm resolves them
  if type(c.colors) == "table" then
    return utilities._merge(utilities._merge({}, scheme), c.colors)
  end

  return scheme
end

---the palette the event handlers draw from. wezterm fills resolved_palette only
---with colors the config actually sets, so a config that names no scheme and
---sets no colors arrives here with no ansi, no brights and no foreground at
---all; the gaps are filled from the same scheme apply_to_config resolved.
---@param conf table: the window's effective config
---@return table
local function effective_palette(conf)
  local palette = type(conf.resolved_palette) == "table" and conf.resolved_palette or {}

  if
    type(palette.ansi) == "table"
    and type(palette.brights) == "table"
    and type(palette.tab_bar) == "table"
    and palette.foreground
    and palette.background
  then
    return palette
  end

  local scheme = resolve_scheme(conf)
  local filled = utilities._merge(utilities._merge({}, scheme), palette)
  if type(filled.tab_bar) ~= "table" then
    filled.tab_bar = build_tab_bar_colors(scheme).tab_bar
  end

  return filled
end

---conforming to https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd
---@param c table: wezterm config object
---@param opts bar.options
M.apply_to_config = function(c, opts)
  -- make the opts arg optional
  if not opts then
    ---@diagnostic disable-next-line: missing-fields
    opts = {}
  end

  -- combine user config with defaults
  options = config.extend_options(config.options, opts)

  local bar_colors = build_tab_bar_colors(resolve_scheme(c))
  c.colors = c.colors or {}
  c.colors.tab_bar = utilities._merge(c.colors.tab_bar or {}, bar_colors.tab_bar)

  -- make the plugin own these settings
  c.tab_bar_at_bottom = options.position == "bottom"
  c.use_fancy_tab_bar = false
  c.tab_max_width = options.max_width
end

wez.on("format-tab-title", function(tab, _, _, conf, hover, _)
  local palette = effective_palette(conf)

  local tab_options = type(options.modules) == "table" and options.modules.tabs or nil
  local tab_rules = type(tab_options) == "table" and tab_options.rules or nil

  local context = { domain = tab.active_pane and tab.active_pane.domain_name }

  -- current_working_dir is one of the two documented cost-bearing fields on
  -- this object, so it is read only when a rule actually tests it
  if rules.uses(tab_rules, "cwd") and tab.active_pane then
    context.cwd = rules.extract_path(tab.active_pane.current_working_dir)
  end

  local overrides = rules.resolve(tab_rules, context)

  -- a rule's icon replaces the separator glyph; the offset must be built
  -- from whichever glyph this tab actually renders, not the configured one
  local icon = overrides.icon or options.separator.left_icon

  local index = tab.tab_index + 1
  local offset = #tostring(index) + #icon + (2 * options.separator.space) + 2
  local title = index .. utilities._space(icon, options.separator.space, nil) .. tabs.get_title(tab)

  local width = conf.tab_max_width - offset
  if #title > conf.tab_max_width then
    title = wez.truncate_right(title, width) .. "…"
  end

  local fg, bg
  if tab.is_active then
    fg = resolve_rule_color(overrides.active_tab_fg, palette, palette.tab_bar.active_tab.fg_color)
    bg = resolve_rule_color(overrides.active_tab_bg, palette, palette.tab_bar.active_tab.bg_color)
  elseif hover then
    -- the palette holds the hover colors, but they reach this tab's own cells
    -- only through the format items returned below
    local base = palette.tab_bar.inactive_tab_hover or palette.tab_bar.inactive_tab
    -- a rule that recolors a tab gets a hover color derived from that color,
    -- the same way an unset global hover color derives one from its own base
    fg = resolve_rule_hover_color(overrides.tab_hover_fg, overrides.inactive_tab_fg, palette, base.fg_color)
    bg = resolve_rule_hover_color(overrides.tab_hover_bg, overrides.inactive_tab_bg, palette, base.bg_color)
  else
    fg = resolve_rule_color(overrides.inactive_tab_fg, palette, palette.tab_bar.inactive_tab.fg_color)
    bg = resolve_rule_color(overrides.inactive_tab_bg, palette, palette.tab_bar.inactive_tab.bg_color)
  end

  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = utilities._space(title, options.padding.tabs.left, options.padding.tabs.right) },
  }
end)

wez.on("update-status", function(window, pane)
  local present, conf = pcall(window.effective_config, window)
  if not present then
    return
  end

  local palette = effective_palette(conf)

  -- left status
  local left_cells = {
    { Background = { Color = palette.tab_bar.background } },
  }

  table.insert(left_cells, { Text = string.rep(" ", options.padding.left) })

  if options.modules.workspace.enabled then
    local stat = options.modules.workspace.icon
      .. utilities._space(window:active_workspace(), options.separator.space, nil)
    local stat_fg = resolve_color(options.modules.workspace.color, palette, palette.foreground)

    if options.modules.leader.enabled and window:leader_is_active() then
      stat_fg = resolve_color(options.modules.leader.color, palette, palette.foreground)
      stat = utilities._constant_width(stat, options.modules.leader.icon)
    end

    table.insert(left_cells, { Foreground = { Color = stat_fg } })
    table.insert(left_cells, { Text = stat })
  end

  if options.modules.zoom.enabled and pane:tab() then
    local panes_with_info = pane:tab():panes_with_info()
    for _, p in ipairs(panes_with_info) do
      if p.is_active and p.is_zoomed then
        table.insert(
          left_cells,
          { Foreground = { Color = resolve_color(options.modules.zoom.color, palette, palette.foreground) } }
        )
        table.insert(
          left_cells,
          { Text = options.modules.zoom.icon .. utilities._space("zoom", options.separator.space) }
        )
      end
    end
  end

  if options.modules.pane.enabled then
    local process = pane:get_foreground_process_name()
    if not process then
      goto set_left_status
    end
    table.insert(
      left_cells,
      { Foreground = { Color = resolve_color(options.modules.pane.color, palette, palette.foreground) } }
    )
    table.insert(left_cells, {
      Text = options.modules.pane.icon .. utilities._space(utilities._basename(process) or "", options.separator.space),
    })
  end

  ::set_left_status::
  window:set_left_status(wez.format(left_cells))

  -- right status
  local right_cells = {
    { Background = { Color = palette.tab_bar.background } },
  }

  local callbacks = {
    {
      name = "spotify",
      func = function()
        return spotify.get_currently_playing(options.modules.spotify.max_width, options.modules.spotify.throttle)
      end,
    },
    {
      name = "username",
      func = function()
        return user.username
      end,
    },
    {
      name = "hostname",
      func = function()
        return wez.hostname()
      end,
    },
    {
      name = "clock",
      func = function()
        return wez.time.now():format(options.modules.clock.format)
      end,
    },
    {
      name = "cwd",
      func = function()
        if options.modules.ssh.enabled then
          local process = pane:get_foreground_process_name()
          if process and (utilities._basename(process) or ""):match "ssh$" then
            return ""
          end
        end
        return paths.get_cwd(pane, true)
      end,
    },
    {
      name = "ssh",
      func = function()
        local process = pane:get_foreground_process_name()
        if not process then
          return ""
        end
        if (utilities._basename(process) or ""):match "ssh$" then
          return "ssh"
        end
        return ""
      end,
    },
  }

  for _, callback in ipairs(callbacks) do
    local name = callback.name
    local func = callback.func
    if not options.modules[name].enabled then
      goto continue
    end
    local text = func()
    if #text > 0 then
      table.insert(
        right_cells,
        { Foreground = { Color = resolve_color(options.modules[name].color, palette, palette.foreground) } }
      )
      table.insert(right_cells, { Text = text })
      table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
      table.insert(right_cells, {
        Text = utilities._space(options.separator.right_icon, options.separator.space, nil)
          .. options.modules[name].icon,
      })
      table.insert(right_cells, { Text = utilities._space(options.separator.field_icon, options.separator.space, nil) })
    end
    ::continue::
  end
  -- remove trailing separator
  table.remove(right_cells, #right_cells)
  table.insert(right_cells, { Text = string.rep(" ", options.padding.right) })

  window:set_right_status(wez.format(right_cells))
end)

wez.on("window-config-reloaded", function(window, _)
  local present, conf = pcall(window.effective_config, window)
  if not present then
    return
  end

  -- the window's own palette is what it actually draws with, so prefer it and
  -- fall back to the same resolution apply_to_config used
  local scheme = conf.resolved_palette
  if type(scheme) ~= "table" or type(scheme.ansi) ~= "table" then
    scheme = resolve_scheme(conf)
  end

  local new_tab_bar = build_tab_bar_colors(scheme)
  local overrides = window:get_config_overrides() or {}
  local current = overrides.colors and overrides.colors.tab_bar

  if
    current
    and current.active_tab
    and current.active_tab.fg_color == new_tab_bar.tab_bar.active_tab.fg_color
    and current.inactive_tab
    and current.inactive_tab.fg_color == new_tab_bar.tab_bar.inactive_tab.fg_color
    and current.inactive_tab_hover
    and current.inactive_tab_hover.fg_color == new_tab_bar.tab_bar.inactive_tab_hover.fg_color
    and current.new_tab
    and current.new_tab.fg_color == new_tab_bar.tab_bar.new_tab.fg_color
    and current.new_tab_hover
    and current.new_tab_hover.fg_color == new_tab_bar.tab_bar.new_tab_hover.fg_color
  then
    return
  end

  -- Preserve full resolved palette (cursor_bg, split, selection_bg, etc.) and only
  -- update tab_bar. Setting overrides.colors = { tab_bar = ... } alone would replace
  -- the entire palette and drop user overrides.
  local full_colors = utilities._merge({}, conf.resolved_palette or {})
  full_colors.tab_bar = new_tab_bar.tab_bar
  overrides.colors = full_colors
  window:set_config_overrides(overrides)
end)

return M
