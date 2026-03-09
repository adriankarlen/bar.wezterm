# AGENTS.md

Guidelines for agentic coding assistants working in this repository.

## Project Overview

`bar.wezterm` is a pure Lua WezTerm plugin that renders a custom tab bar. It
has no build system, no test suite, and no CI. The only tool is StyLua for
code formatting.

## Repository Structure

```
bar.wezterm/
├── plugin/
│   ├── init.lua          # Entry point; apply_to_config(), event handlers
│   └── bar/
│       ├── config.lua    # Default options, type definitions
│       ├── paths.lua     # CWD resolution
│       ├── spotify.lua   # Spotify now-playing integration
│       ├── tabs.lua      # Tab title logic
│       ├── user.lua      # Username resolution
│       └── utilities.lua # Shared helpers (_space, _merge, _basename, …)
├── stylua.toml
├── .editorconfig
└── README.md
```

## Commands

### Format

```sh
stylua .
```

This is the only automated tool. Run it before committing. There is no
linter, no test runner, and no build step.

### Check formatting without modifying files

```sh
stylua --check .
```

### Running the plugin

Load it in your `wezterm.lua`:

```lua
local bar = wez.plugin.require "https://github.com/adriankarlen/bar.wezterm"
bar.apply_to_config(config, opts)
```

There is no way to run tests in isolation. Manual testing requires a live
WezTerm instance.

## Code Style

### Formatter: StyLua (`stylua.toml`)

```toml
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "None"
```

Key rules enforced by StyLua:
- **2-space indentation** — no tabs, ever.
- **Unix line endings** — LF only.
- **Double quotes preferred** — use single only when the string contains a
  double quote.
- **No parentheses on single-argument calls** — `require "wezterm"` not
  `require("wezterm")`. Same for single-table-arg calls.

### Editor config (`.editorconfig`)

```ini
[*]
insert_final_newline = true
indent_style = space
indent_size = 2
```

All files must end with a newline.

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Module table | Single uppercase letter | `local M = {}` / `local H = {}` |
| Public module functions | `snake_case` assigned to `M` | `M.get_title = function(...)` |
| Private/internal helpers | `_snake_case` assigned to module | `H._basename`, `H._merge` |
| Type/class names | `namespace.classname` | `bar.options`, `option.module` |
| Local variables | `snake_case` | `local tab_info`, `local left_cells` |

Use `M` for the module table in all files except `utilities.lua`, which uses
`H` (for "helpers"). Do not deviate from this — it is established convention.

## Type Annotations

Use LuaLS / EmmyLua-style annotations everywhere. Every function must have
`---@param` and `---@return` annotations. Every class/type must be declared
with `---@class`.

```lua
---@class option.module
---@field enabled boolean
---@field icon string
---@field color number

---get basename for dir/file, removing extension and path
---@param s string
---@return string?
---@return number?
H._basename = function(s)
  ...
end
```

Mark internal modules and classes with `---@private`:

```lua
---@private
---@class bar.tabs
local M = {}
```

## Module Pattern

Every file follows the same pattern:

```lua
local wez = require "wezterm"
local utilities = require "bar.utilities"

---@private
---@class bar.example
local M = {}

M.some_function = function(arg)
  ...
end

return M
```

- Local requires at the top, no parentheses.
- All public API attached to `M` (or `H`).
- `return M` at the bottom, no blank line before it.

## Imports

- No parentheses on `require`: `require "wezterm"`, not `require("wezterm")`.
- Group stdlib/wezterm requires first, then internal `bar.*` requires.
- Do not use `require` inside functions; keep all requires at the top of
  the file.

## Error Handling

- Use `pcall` when calling WezTerm APIs that may fail at runtime.
- On failure, return early and do nothing (silent fail). Log with
  `wez.log_error` only for genuinely unexpected conditions.
- Do not raise errors with `error()` — this crashes WezTerm.

```lua
local present, conf = pcall(window.effective_config, window)
if not present then
  return
end
```

- Guard against nil/wrong-type inputs at the top of helper functions and
  return a safe default (empty string `""`, `nil`, etc.):

```lua
H._space = function(s, space, trailing_space)
  if type(s) ~= "string" or type(space) ~= "number" then
    return ""
  end
  ...
end
```

## Control Flow

Lua has no `continue`. Use the `goto` idiom:

```lua
for _, item in ipairs(list) do
  if not condition then
    goto continue
  end
  -- do work
  ::continue::
end
```

Label names should describe the target (`continue`, `set_left_status`), not
be generic.

## Platform Compatibility

Check for Windows explicitly when dealing with paths or environment variables:

```lua
H.is_windows = package.config:sub(1, 1) == "\\"
H.home = (os.getenv "USERPROFILE" or os.getenv "HOME" or wez.home_dir or ""):gsub("\\", "/")
```

Normalize path separators to `/` in strings for consistency.

## What Not to Do

- Do not add a build system, test framework, or CI unless explicitly asked.
- Do not add dependencies — this is a zero-dependency Lua plugin.
- Do not use `local function foo()` declarations; assign to the module table
  instead: `M.foo = function() ... end`. Exception: truly file-local helpers
  that are never exported can use `local function`.
- Do not call `error()` — see Error Handling above.
- Do not add parentheses to single-argument `require`/function calls;
  StyLua will remove them anyway.
- Do not use tabs; use 2 spaces.
