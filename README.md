# bar.wezterm

A tab bar configuration for wezterm, this configuration is heavily inspired by [rose-pine/tmux](https://github.com/rose-pine/tmux)

> NOTE: This bar requires that you are using a Nerd Font or has "Symbols Nerd Font" installed on your system so wezterm can default to it

## 📷

![image](https://raw.githubusercontent.com/adriankarlen/bar.wezterm/main/misc/preview.png)

&nbsp;

## 🚀 Installation

This is a wezterm [plugin](https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd). It can be installed by importing the repo and calling the apply_to_config-function.

```lua
local bar = wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm")
bar.apply_to_config(config)
```

> NOTE: This assumes that you have imported the wezterm module and initialized the config-object.

&nbsp;

## 📜 License

This project is licensed under the MIT License - see the
[LICENSE](https://github.com/adriankarlen/bar.wezterm/blob/main/LICENSE) file
