# bar.wezterm

A tab bar configuration for wezterm, this configuration is heavily inspired by [rose-pine/tmux](https://github.com/rose-pine/tmux)

## 📷

### 🌷 Rosé Pine

![image](https://raw.githubusercontent.com/adriankarlen/bar.wezterm/main/misc/rose-pine.png)

### 😸 Catppuccin Mocha

![image](https://raw.githubusercontent.com/adriankarlen/bar.wezterm/main/misc/catppuccin-mocha.png)
&nbsp;

## 🚀 Installation

This is a wezterm [plugin](https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd). It can be installed by importing the repo and calling the apply_to_config-function. It is important that the `apply_to_config`-function is called after `color_scheme` has been set.

```lua
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
bar.apply_to_config(config)
```

> NOTE: This assumes that you have imported the wezterm module and initialized the config-object.

&nbsp;

## 🛠️ Configuration

The `apply_to_config`-function takes a second param `opts`. To override any options simply pass a table of the desired changes.

```lua
bar.apply_to_config(
  config,
  {
    enabled_modules = {
      username = false,
      clock = false
    }
  }
)
```

### 🏭 Default configuration

> NOTE: The default config requires that you are using a Nerd Font or has "Symbols Nerd Font" installed on your system so wezterm can default to it.

```lua
{
  position = "bottom",
  max_width = 32,
  left_separator = " -> ",
  right_separator = " <- ",
  field_separator = "  |  ",
  workspace_icon = "",
  pane_icon = "",
  user_icon = "",
  hostname_icon = "󰒋",
  clock_icon = "󰃰",
  cwd_icon = "",
  enabled_modules = {
    username = true,
    hostname = true,
    clock = true,
    cwd = true,
  },
}
```

### 🎨 Colors

At the moment is not possible to pass in colors as option to the plugin. However since the plugin uses your themes colors you can configure the theme to get a different result. For instance, if I want to change the active tab background color I can do so like this:

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

| Color option                    | Default             |
| ------------------------------- | ------------------- |
| `tab_bar.background`            | `scheme.background` |
| `tab_bar.active_tab`.bg_color   | `scheme.background` |
| `tab_bar.active_tab`.fg_color   | `scheme.ansi`[4]    |
| `tab_bar.inactive_tab`.bg_color | `scheme.background` |
| `tab_bar.inactive_tab`.fg_color | `scheme.ansi`[6]    |

## 📜 License

This project is licensed under the MIT License - see the
[LICENSE](https://github.com/adriankarlen/bar.wezterm/blob/main/LICENSE) file
