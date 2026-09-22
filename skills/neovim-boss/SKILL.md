---
name: neovim-boss
description: Use this skill when you have the neovim-boss MCP server loaded and the user indicates any nvim edit command. Provides a complete user guide, tool workflows, best practices, and safety rules for controlling Neovim via neovim-boss.
---

# Neovim Boss (`neovim-boss`) MCP User Guide

`neovim-boss` is a high-performance native MessagePack-RPC and Model Context Protocol (MCP) server for Neovim. It gives AI agents direct, real-time control to inspect, navigate, and edit files inside the user's running Neovim instance.

---

## 1. Quick Reference: The Toolset

| Tool | Purpose | Key Parameters | When to Use |
| :--- | :--- | :--- | :--- |
| **`get_state_brief`** | **Orientation snapshot** | `buffer` *(opt)* | Call at the start of **every turn** to see mode, active file, cursor line, and nearby context. |
| **`get_state`** | **Full session snapshot** | `buffer` *(opt)* | Use when you need multi-window layout, marks (`a-z`), folds, visual selection bounds, or LSP diagnostic counts. |
| **`send_command`** | **Ex commands** | `command` *(req)*, `output` *(opt)* | Open splits, tabs, switch buffers, save files, open terminals (`:w`, `:vsplit`, `:tabnew`, `:b`). |
| **`send_keys`** | **Keystrokes & macros** | `keys` *(req)*, `escape` *(opt, default true)* | Drive interactive editor actions: undo (`u`), motions (`gg`, `G`), tab navigation (`gt`), visual mode. |
| **`exec_lua`** | **Neovim API & Lua runtime** | `code` *(req)*, `args` *(opt)* | Inspect runtime data, query plugins, run multi-line scripts, find runtime files, or evaluate expressions. |
| **`read_full_buf`** | **Read full buffer** | `buffer` *(req)* | Read the entire contents of a buffer, formatted with 1-based line numbers. |
| **`read_buf_range`** | **Read buffer range** | `buffer`, `start_line`, `end_line` *(req)* | Read a specific line range from a buffer, formatted with line numbers. Auto-swaps and clamps bounds. |
| **`find_and_replace_buf`** | **Safe exact-match edit** | `buffer`, `find`, `replace` *(req)* | Exact-match find and replace within a buffer. Fails if missing or non-unique. Preserves undo tree (`u`). Zero disk writes. |
| **`write_full_buf`** | **Rewrite full buffer** | `buffer`, `content` *(req)* | Replace the entire contents of a buffer in-memory with full undo support. |

### MCP Resource
- **`neovim://buffers`**: Returns rich JSON telemetry for all open buffers (`id`, `name`, `line_count`, `cursor_line`, `modified`, `loaded`, `windows`, `filetype`, `buftype`).

---

## 2. Core Agent Workflows

### 2.1 The Orientation Loop (Start of Turn)
Never assume the user's cursor or active file hasn't changed. Always start by checking state:

```json
// 1. Check current editor state
call_mcp_tool("neovim-boss", "get_state_brief", {})
```

**Evaluate the response:**
- **`active_window.buffer`**: Is it the file the user is asking about?
- **`active_window.line` & `context`**: Where is the cursor, and what lines surround it?
- **`mode`**: Is Neovim in `"normal"`, `"insert"`, `"visual"`, or `"terminal"` mode?
- **`modified_buffers`**: Are there unsaved changes in any buffer?

---

### 2.2 Navigation, Splits & Tabs

Do not create specialized tools for what Neovim's Ex commands already do best:

| Goal | MCP Action |
| :--- | :--- |
| Open a file | `send_command({"command": "edit src/main.zig"})` |
| Switch active buffer | `send_command({"command": "buffer notes.md"})` |
| Vertical split | `send_command({"command": "vsplit tests/test.py"})` |
| Horizontal split | `send_command({"command": "split README.md"})` |
| Jump between splits | `send_command({"command": "wincmd l"})` *(or `h`, `j`, `k`)* |
| Close extra splits | `send_command({"command": "only"})` |
| Open new tab | `send_command({"command": "tabnew"})` *(or `send_command({"command": "tabnew path/to/file"})`)* |
| Switch tabs | `send_keys({"keys": "gt"})` *(next)* or `send_keys({"keys": "gT"})` *(prev)* |
| Jump to Tab N | `send_keys({"keys": "2gt"})` *(jump to tab 2)* |
| Open terminal buffer | `send_command({"command": "terminal"})` |

---

### 2.3 Safe Keystrokes & Insert Mode Behavior

> [!IMPORTANT]
> **`send_keys` defaults to `escape: true`**. It automatically prepends `<Esc>` to guarantee execution begins in normal mode.

- **For Normal Mode Commands**: Keep default `escape: true`.
  ```json
  // Undo previous edit
  send_keys({"keys": "u"})

  // Go to line 42, column 5
  send_keys({"keys": "42G5|"})

  // Set mark 'a' at line 10
  send_keys({"keys": "10Gma"})
  ```

- **For Typing in Insert Mode**: You **MUST set `escape: false`** if the user asks you to type text while already in insert mode:
  ```json
  send_keys({"keys": "my_variable_name", "escape": false})
  ```

- **Vim Key Notation Supported**:
  `<Esc>`, `<CR>`, `<Tab>`, `<C-w>v`, `<C-PageDown>`, `<Space>`, etc., are automatically translated to terminal control codes.

---

### 2.4 Monitoring & Resolving LSP Diagnostics

Use `get_state` to observe real-time diagnostics from Neovim's language servers:

```json
call_mcp_tool("neovim-boss", "get_state", {})
```

Look at `active_window.diagnostics_summary`:
```json
{
  "error": 2,
  "warning": 1,
  "info": 0,
  "hint": 0
}
```

#### Workflow to Fix Diagnostics:
1. Identify the file and error line from `context` and `get_state`.
2. Apply the fix or write the correction.
3. Save the buffer: `send_command({"command": "w"})`.
4. Call `get_state` again to verify `error: 0`.

#### Stale Diagnostics?
If diagnostics seem stale after an external edit:
1. Reload buffer: `send_command({"command": "edit!"})`.
2. Or restart the language server: `exec_lua({"code": "vim.cmd('LspRestart')"})`.

---

### 2.5 Querying Runtime, Plugins & Documentation

Leverage `exec_lua` to introspect Neovim's configuration and installed plugins:

#### Find System Paths (`stdpath`)
```json
exec_lua({
  "code": "return { config = vim.fn.stdpath('config'), data = vim.fn.stdpath('data'), state = vim.fn.stdpath('state') }"
})
```

#### Search Installed Plugin Files
Search active runtime paths for plugin code:
```json
exec_lua({
  "code": "return vim.api.nvim_get_runtime_file(..., true)",
  "args": ["lua/**/telescope*"]
})
```

#### Search Help Tags
Autocomplete help topics without opening a help buffer:
```json
exec_lua({
  "code": "return vim.fn.getcompletion(..., 'help')",
  "args": ["MiniDiff"]
})
```

---

### 2.6 Buffer Inspection & Safe In-Memory Editing

Neovim Boss provides dedicated tools for inspecting buffer content and performing safe, undoable edits directly in memory without touching disk:

#### Read Buffer Contents
```json
// Read entire buffer with line numbers
read_full_buf({"buffer": "src/main.zig"})

// Read specific range (lines 10 to 30)
read_buf_range({"buffer": "src/main.zig", "start_line": 10, "end_line": 30})
```

#### Safe Find & Replace
Use `find_and_replace_buf` for surgical edits. It guarantees safety: if `find` does not appear, or appears more than once, the edit is aborted:
```json
find_and_replace_buf({
  "buffer": "src/main.zig",
  "find": "const count: usize = 0;",
  "replace": "const count: usize = 1;"
})
```
All edits preserve Neovim's undo history (`send_keys({"keys": "u"})`).

#### Whole-Buffer Replacement
Use `write_full_buf` when generating or completely replacing a buffer's content in-memory:
```json
write_full_buf({
  "buffer": "scratch.txt",
  "content": "Line 1\nLine 2\nLine 3\n"
})
```

---

## 3. Safety Guidelines

1. **Protect Unsaved Work**:
   - Always check `modified_buffers` in `get_state_brief` before closing buffers (`:bd`) or quitting (`:q`).
   - Never use `:q!`, `:qa!`, or `:bd!` unless the user explicitly commands you to discard unsaved changes.
2. **Preserve the Undo Tree**:
   - Prefer small, targeted edits over wiping and rewriting whole files.
   - Test that edits can be cleanly undone with `send_keys({"keys": "u"})`.
3. **Verify State After Action**:
   - Always verify the layout or buffer with `get_state_brief` after performing split, tab, or buffer switch commands.
