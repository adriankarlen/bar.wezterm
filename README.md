# 🍺 bar.wezterm

A tab bar configuration for wezterm, this configuration is heavily inspired by [rose-pine/tmux](https://github.com/rose-pine/tmux).

## 📷

![image](https://raw.githubusercontent.com/adriankarlen/bar.wezterm/main/misc/preview.png)

### 🌷 Rosé Pine

![image](https://raw.githubusercontent.com/adriankarlen/bar.wezterm/main/misc/rose-pine.png)

### 😸 Catppuccin Mocha

![image](https://raw.githubusercontent.com/adriankarlen/bar.wezterm/main/misc/catppuccin-mocha.png)
&nbsp;

## 📋 Prerequisites

### 🎵Spotify

In order for the spotify integration to work you need to have [spotify-tui](https://github.com/Rigellute/spotify-tui) installed on you system. Follow their installation instructions on how to set it up.

> [!NOTE]
> bar.wezterm ships with this module disabled, please check example in
> [Configuration](#%EF%B8%8F-configuration) on how to enable it.

&nbsp;

## 🚀 Installation

This is a wezterm [plugin](https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd). It can be installed by importing the repo and calling the apply_to_config-function. It is important that the `apply_to_config`-function is called after `color_scheme` has been set.

```lua
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
bar.apply_to_config(config)
```

> [!NOTE]
> This assumes that you have imported the wezterm module and initialized the config-object.

&nbsp;

## 🛠️ Configuration

The `apply_to_config`-function takes a second param `opts`. To override any options simply pass a table of the desired changes.

```lua
-- example enable spotify module
bar.apply_to_config(
  config,
  {
    modules = {
      spotify = {
        enabled = true,
      },
    },
  }
)
```

### 🏭 Default configuration

> [!IMPORTANT]
> The default config requires that you are using a Nerd Font or has "Symbols Nerd Font" installed on your system so wezterm can default to it.

```lua
local config = {
  position = "bottom",
  max_width = 32,
  padding = {
    left = 1,
    right = 1,
    tabs = {
      left = 0,
      right = 2,
    },
  },
  separator = {
    space = 1,
    left_icon = wez.nerdfonts.fa_long_arrow_right,
    right_icon = wez.nerdfonts.fa_long_arrow_left,
    field_icon = wez.nerdfonts.indent_line,
  },
  modules = {
    tabs = {
      active_tab_fg = 4,
      inactive_tab_fg = 6,
      new_tab_fg = 2,
    },
    mode = {
      enabled = true,
      icon = wez.nerdfonts.cod_server_process, --- TODO: don't forget here as well
      color = 1,
    },
    workspace = {
      enabled = true,
      icon = wez.nerdfonts.cod_window,
      color = 8,
    },
    leader = {
      enabled = true,
      icon = wez.nerdfonts.oct_rocket,
      color = 2,
    },
    zoom = {
      enabled = false,
      icon = wez.nerdfonts.md_fullscreen,
      color = 4,
    },
    pane = {
      enabled = true,
      icon = wez.nerdfonts.cod_multiple_windows,
      color = 7,
    },
    username = {
      enabled = true,
      icon = wez.nerdfonts.fa_user,
      color = 6,
    },
    hostname = {
      enabled = true,
      icon = wez.nerdfonts.cod_server,
      color = 8,
    },
    clock = {
      enabled = true,
      icon = wez.nerdfonts.md_calendar_clock,
      format = "%H:%M",
      color = 5,
    },
    cwd = {
      enabled = true,
      icon = wez.nerdfonts.oct_file_directory,
      color = 7,
    },
    spotify = {
      enabled = false,
      icon = wez.nerdfonts.fa_spotify,
      color = 3,
      max_width = 64,
      throttle = 15,
    },
  },
}
```

### 🎨 Colors

Every ansi color used is configurable, to change a color, pass in the desired
ansi code to use for a specific setting.

If you want to change any other color used, since the plugin uses your themes colors you can configure the theme to get a different result. For instance, if I want to change the active tab background color I can do so like this:

```lua
return {
  -- ... your existing config
  colors = {
    tab_bar = {
      active_tab = {
        bg_color = "#26233a"
      }
    }
  }
}
```

#### 🖌️ Color table

| Color option                    | Default       |
| ------------------------------- | ------------- |
| `tab_bar.background`            | `transparent` |
| `tab_bar.active_tab.bg_color`   | `transparent` |
| `tab_bar.inactive_tab.bg_color` | `transparent` |

## 📜 License

This project is licensed under the MIT License - see the
[LICENSE](https://github.com/adriankarlen/bar.wezterm/blob/main/LICENSE) file
