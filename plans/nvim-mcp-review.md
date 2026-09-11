# Neovim MCP Servers Review & Comparison

This document provides a comprehensive technical evaluation and comparative analysis of four Model Context Protocol (MCP) servers designed for Neovim:

1. **[`linw1995/nvim-mcp`](file:///Users/justinhj/projects/nvim-mcp-linw1995/README.md)** (Rust)
2. **[`paulburgess1357/nvim-mcp`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/README.md)** (Python)
3. **[`bigcodegen/mcp-neovim-server`](file:///Users/justinhj/projects/mcp-neovim-server/README.md)** (TypeScript / Node.js)
4. **[`cousine/neovim-mcp`](file:///Users/justinhj/projects/neovim-mcp/README.md)** (Go)

Each project bridges AI assistants (such as Claude Code, Cursor, Codex, OpenCode, Gemini Code Assist, or Antigravity) to running Neovim sessions. Remarkably, each of the four implements a distinct programming language stack and focuses on a fundamentally different aspect of editor interaction: **LSP Code Intelligence**, **Interactive In-Memory Pair Programming**, **Native Vim Workflow Automation**, and **Modular Type-Safe RPC Operations**.

---

## 1. Executive Summary & Core Philosophies

```
+-----------------------------------------------------------------------------------------------------------------------+
|                                                       AI AGENT                                                        |
|                                    (Claude Code, Cursor, Codex, OpenCode, etc.)                                       |
+-----------------------------------------------------------+-----------------------------------------------------------+
                                                            |
         +-----------------------------+--------------------+--------------------+-----------------------------+
         |                             |                                         |                             |
         v                             v                                         v                             v
+-----------------------+  +-----------------------+           +-----------------------+  +-----------------------+
| linw1995/nvim-mcp     |  |paulburgess1357/nvim-mcp|           |  mcp-neovim-server    |  |  neovim-mcp           |
|      (Rust)           |  |       (Python)        |           |  (TypeScript / Node)  |  |        (Go)           |
| "The Code Intelligence|  | "The Interactive Pair |           |   "The Native Vim     |  | "The Modular Neovim   |
|         Hub"          |  |       Partner"        |           |      Automator"       |  |      RPC Bridge"      |
+-----------------------+  +-----------------------+           +-----------------------+  +-----------------------+
| • LSP Client Proxy    |  | • Deep Session State  |           | • Traditional Vim     |  | • Clean Package       |
|   (22 tools: def, ref,|    (mode, context lines, |             Primitives (registers,|    Architecture (buffer, |
|    hover, symbols,    |     visual bounds, folds)|             marks, macros, jumps, |    text, cursor, window,|
|    hierarchies, fixes)|  | • In-Memory Safe Edits|             folds, tabs, splits)  |    commands)            |
| • Formal MCP Resources|    (substring match, undo|           | • Native Regex Sub    |  | • Window Resizing     |
| • Dynamic Lua Tools   | • Visual Extmarks        |             & Project Vimgrep     |  | • Direct Function     |
| • Stdio + HTTP / SSE  |    (line highlights &    |           | • MCP Resources &     |    Calling (RPC args)   |
| • Multi-Session Hub   |     virtual text)        |             MCP Prompts           |  | • Formal MCP Resource |
| • Requires Companion  | • Terminal Job Channels  |           | • Fixed Socket Target |  | • Compiled Go Binary  |
|   Lua Plugin          | • Zero-Plugin Arch       |           | • Zero-Plugin Arch    |  | • Zero-Plugin Arch    |
+-----------------------+  +-----------------------+           +-----------------------+  +-----------------------+
         |                             |                                         |                             |
         +-----------------------------+--------------------+--------------------+-----------------------------+
                                                            |
                                                            v
                                                   +-----------------+
                                                   |  Neovim Session |
                                                   +-----------------+
```

### 1. `linw1995/nvim-mcp`: The Code Intelligence & LSP Proxy (Rust)
- **Philosophy**: Neovim already runs mature Language Servers (LSPs) that understand project structure, types, and ASTs. The MCP server acts as an intelligent proxy exposing Neovim's semantic LSP capabilities to AI agents, turning Neovim into a high-powered code intelligence engine.
- **Key Characteristics**: 33 static tools (22 for LSP operations), formal MCP Resources (`nvim-connections://`, `nvim-tools://`, `nvim-diagnostics://`), dynamic custom Lua tool registration via `notifications/tools/list_changed`, and support for both stdio and streamable HTTP (SSE) transports.

### 2. `paulburgess1357/nvim-mcp`: The Interactive Pair-Programming Partner (Python)
- **Philosophy**: The AI is a live pair programmer sitting beside the developer. It needs to "see what you see" (active window, cursor context lines, visual selections, folds, marks), perform safe in-memory edits that never touch disk until saved, leave visual notes via extmarks (highlights and virtual text), and interact with terminal splits without stealing focus.
- **Key Characteristics**: 18 tools focused on editor awareness (`get_state_brief`, `get_state`), safe in-memory editing with full undo support (`find_and_replace_buf`, `write_full_buf`), non-destructive visual annotations (`highlight_ranges`, `add_virtual_texts`), and terminal job channel control (`send_to_terminal`). Zero plugins required.

### 3. `bigcodegen/mcp-neovim-server`: The Native Vim Workflow Automator (TypeScript / Node.js)
- **Philosophy**: Neovim already possesses an unmatched editing vocabulary. An AI agent should wield native Vim primitives: registers, marks, macros, jump lists, folds, tabs, regex substitution, and project-wide vimgrep with quickfix integration.
- **Key Characteristics**: 19 tools dedicated to traditional Vim workflows (`vim_macro`, `vim_register`, `vim_mark`, `vim_jump`, `vim_fold`, `vim_tab`, `vim_search_replace`, `vim_grep`). Exposes formal MCP Resources (`nvim://session`, `nvim://buffers`) and is the only candidate implementing an **MCP Prompt** (`neovim_workflow`). Ships as a Claude Desktop `.dxt` bundle.

### 4. `cousine/neovim-mcp`: The Modular Neovim RPC Bridge (Go)
- **Philosophy**: Neovim integration should be fast, type-safe, lightweight, and cleanly modularized. By compiling down to a single static binary with no runtime dependencies, it provides rock-solid, well-tested RPC primitives for buffer management, line-level editing, cursor positioning, window manipulation, and arbitrary function invocation.
- **Key Characteristics**: 20 tools cleanly partitioned into 5 packages (`buffer`, `text`, `cursor`, `window`, `command`). Unique capabilities include dedicated window resizing (`resize_window`), direct function execution with arguments (`call_function`), and line deletion (`delete_lines`). Exposes an MCP Resource (`nvim://buffers`). Zero plugins required.

---

## 2. Four-Way High-Level Comparison Matrix

| Feature / Dimension | [`linw1995/nvim-mcp`](file:///Users/justinhj/projects/nvim-mcp-linw1995/README.md) | [`paulburgess1357/nvim-mcp`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/README.md) | [`mcp-neovim-server`](file:///Users/justinhj/projects/mcp-neovim-server/README.md) | [`neovim-mcp`](file:///Users/justinhj/projects/neovim-mcp/README.md) |
| :--- | :--- | :--- | :--- | :--- |
| **Language & Runtime** | Rust (compiled binary, `rmcp`) | Python ≥ 3.10 (official `mcp` SDK) | TypeScript / Node.js (`@modelcontextprotocol/sdk`) | Go (compiled static binary, `go-sdk`) |
| **Distribution** | `cargo install`, Nix flake | `uvx`, `pip`, Nix flake, Cursor plugin | `npx`, npm, `.dxt` bundle | `brew install cousine/tap/neovim-mcp`, binary |
| **Neovim Requirements** | Any Neovim + companion Lua plugin | Neovim ≥ 0.11 (native socket) or `--listen` | Any Neovim with `--listen /tmp/nvim` | Any Neovim with `--listen /tmp/nvim.sock` |
| **Neovim Plugin Needed?**| **Yes** ([`nvim-mcp.lua`](file:///Users/justinhj/projects/nvim-mcp-linw1995/lua/nvim-mcp/init.lua)) | **No** (native socket auto-discovery) | **No** (native socket connection) | **No** (native socket connection) |
| **Transports** | **stdio & HTTP / SSE** | **stdio only** | **stdio only** | **stdio only** |
| **Total Tools** | **33 tools** (+ dynamic tools) | **18 tools** | **19 tools** | **20 tools** |
| **LSP Operations** | **Extensive (22 tools)**: def, ref, hover, symbols, hierarchies, rename | **Diagnostics only** (error/warning list & summary) | **Status summary only** (active client names in status) | None built-in |
| **Buffer Editing Model** | Indirect via LSP edits, formatting, or `exec_lua` | **Safe in-memory substring replacement**: `find_and_replace_buf` (undoable) | **Line-indexed**: `vim_edit` (`insert`, `replace`, `replaceAll`), regex `:s` | **Line-indexed & cursor**: `set_buffer_lines`, `insert_text`, `delete_lines` |
| **Editor Awareness** | Basic: `cursor_position`, `list_buffers` | **Deepest**: `get_state_brief`, `get_state` (context lines, selection, folds, marks) | **Rich**: `vim_status` (cursor, mode, marks, registers, visual selection, layout) | Moderate: `get_cursor_position`, `get_current_buffer`, `get_windows` |
| **Visual Annotations** | None | **First-class**: theme-aware line highlights & virtual text | Can trigger visual mode (`vim_visual`) | None |
| **Vim Primitives** | Minimal | Basic Ex commands & raw keys (`send_command`, `send_keys`) | **Extensive**: registers, marks, macros, jump list, folds, tabs, vimgrep | Marks via `call_function`, search, split, resize window |
| **Terminal Integration** | None | **First-class**: `send_to_terminal` via job channel (non-stealing focus) | Shell execution via `:!` (`vim_command("!cmd")`) | None |
| **MCP Resources** | **Yes** (5 URI schemes) | None (tools only) | **Yes** (`nvim://session`, `nvim://buffers`) | **Yes** (`nvim://buffers`) |
| **MCP Prompts** | None | None (provides rules files `.mdc`, `CLAUDE.md`) | **Yes** (`neovim_workflow`) | None |
| **Dynamic Tool Registry**| **Yes** (register Lua tools in Neovim) | None | None | None |
| **Tool Change Events** | **Yes** (`list_changed`) | None | None | None |
| **Connection Model** | Multi-instance hub with `connection_id`s | Single active session; auto-discovery or menu | Single session to fixed socket path | Single session to fixed socket path |

---

## 3. Deep Dive: `linw1995/nvim-mcp` (Rust)

### Architecture & Connection
- Written in Rust using [`rmcp`](https://crates.io/crates/rmcp) and [`nvim-rs`](https://crates.io/crates/nvim-rs).
- Uses companion Lua plugin ([`lua/nvim-mcp/init.lua`](file:///Users/justinhj/projects/nvim-mcp-linw1995/lua/nvim-mcp/init.lua)) to create project sockets named `nvim-mcp.<git-root>.<pid>.sock`.
- Server implementation: [`NeovimMcpServer`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/core.rs#L29-L34) in [`src/server/core.rs`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/core.rs).
- Router: [`HybridToolRouter`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/hybrid_router.rs#L62) in [`src/server/hybrid_router.rs`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/hybrid_router.rs).
- Supports concurrent multi-instance sessions via deterministic 7-character BLAKE3 `connection_id`s.
- Supports both **stdio** and **streamable HTTP (SSE)** transports (`--http-port`).

### Capabilities (33 Tools)
- **Connection (4)**: [`get_targets`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L494), [`connect`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L508), [`connect_tcp`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L535), [`disconnect`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L562).
- **Navigation & Buffers (5)**: [`list_buffers`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L596), [`read`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L649) (supports Universal Document Identifiers: `buffer_id`, `project_relative_path`, or `absolute_path`), [`buffer_diagnostics`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L665), [`cursor_position`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L1108), [`navigate`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L1131).
- **LSP Code Intelligence (22)**:
  - Definition & Navigation: [`lsp_definition`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L789), [`lsp_type_definition`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L807), [`lsp_declaration`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L847), [`lsp_implementations`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L827), [`lsp_references`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L770), [`lsp_hover`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L735).
  - Symbols: [`lsp_document_symbols`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L753), [`lsp_workspace_symbols`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L687).
  - Call Hierarchy: [`lsp_call_hierarchy_prepare`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L1148), [`lsp_call_hierarchy_incoming_calls`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L1166), [`lsp_call_hierarchy_outgoing_calls`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L1183).
  - Type Hierarchy: [`lsp_type_hierarchy_prepare`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L1200), [`lsp_type_hierarchy_supertypes`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L1218), [`lsp_type_hierarchy_subtypes`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L1235).
  - Code Actions & Refactoring: [`lsp_code_actions`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L704), [`lsp_resolve_code_action`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L865), [`lsp_apply_edit`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L884), [`lsp_rename`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L901).
  - Formatting & Imports: [`lsp_formatting`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L973), [`lsp_range_formatting`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L1004), [`lsp_organize_imports`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L1051).
  - Environment: [`lsp_clients`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L676).
- **Execution & Sync (2)**: [`exec_lua`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L607), [`wait_for_lsp_ready`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs#L626).

### MCP Protocol Features
- **Resources**: `nvim-connections://`, `nvim-tools://`, `nvim-tools://{conn_id}`, `nvim-diagnostics://{conn_id}/workspace`, `nvim-diagnostics://{conn_id}/buffer/{buf_id}`.
- **Dynamic Lua Tools**: Exposes user tools configured in Neovim Lua to the agent with auto-generated schemas and fires `notifications/tools/list_changed`.

---

## 4. Deep Dive: `paulburgess1357/nvim-mcp` (Python)

### Architecture & Connection
- Written in Python ≥ 3.10 using official `mcp` SDK and a lightweight socket msgpack-RPC client ([`NvimClient`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/client.py#L26)).
- Zero Neovim plugins required: discovers Neovim 0.11's default socket in `/tmp`, `/run/user/<uid>`, or `$XDG_RUNTIME_DIR`. Matches terminal PIDs via `pgrep -P`.
- Orchestrator: [`NeovimManager`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/manager.py#L59) in [`src/nvim_mcp/manager.py`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/manager.py).
- Lua scripts: [`src/nvim_mcp/lua.py`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/lua.py).
- Transport: stdio only.

### Capabilities (18 Tools)
- **Situational Awareness (2)**:
  - [`get_state_brief`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L298): Fast orientation snapshot (mode, cwd, listed/modified buffers, active window with numbered cursor context lines, alternate window, open terminals).
  - [`get_state`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L263): Comprehensive snapshot (all visible windows, visual selection bounds, closed fold ranges, diagnostic count summary, marks `a-z`, active MCP highlights/virtual text, indent settings).
- **In-Memory Buffer Editing (4)**:
  - [`read_full_buf`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L217): Read full buffer with line numbers.
  - [`read_buf_range`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L235): Read line range with line numbers.
  - [`find_and_replace_buf`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L168): Safe in-memory find and replace (fails if ambiguous/non-unique; preserves undo tree).
  - [`write_full_buf`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L196): Overwrite buffer in-memory with full undo support (`send_keys("u")`).
- **Commands & Terminals (3)**:
  - [`send_command`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L46): Run Vim Ex commands (`:w`, `:split`, etc.).
  - [`send_keys`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L68): Send keystrokes (auto-prepends `<Esc>`).
  - [`send_to_terminal`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L91): Write directly to terminal job channel without moving cursor or stealing focus. Defaults to `submit=False`.
- **Visual Extmarks (6)**:
  - [`highlight_range`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L320) & [`highlight_ranges`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L358): Colored line highlights (theme-aware highlight groups).
  - [`clear_highlights`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L408): Remove MCP highlights.
  - [`add_virtual_text`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L425) & [`add_virtual_texts`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L462): In-buffer visual text notes (`"eol"`, `"above"`, `"below"`). Zero file edits.
  - [`clear_virtual_texts`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L517): Remove MCP virtual text.
- **Diagnostics & Connection (3)**:
  - [`get_all_diagnostics`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L135), [`get_buf_diagnostics`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L151), [`connect`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py#L15).

---

## 5. Deep Dive: `mcp-neovim-server` (TypeScript / Node.js)

### Architecture & Connection
- Written in TypeScript using `@modelcontextprotocol/sdk` and `neovim` npm package.
- Server entry: [`src/index.ts`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts).
- Manager: [`NeovimManager`](file:///Users/justinhj/projects/mcp-neovim-server/src/neovim.ts) in [`src/neovim.ts`](file:///Users/justinhj/projects/mcp-neovim-server/src/neovim.ts).
- Zero plugins required. Connects to fixed socket (`process.env.NVIM_SOCKET_PATH || '/tmp/nvim'`).
- Transport: stdio only.

### Capabilities (19 Tools)
- **Buffer & File Operations (4)**: [`vim_buffer`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L73), [`vim_buffer_switch`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L300), [`vim_buffer_save`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L326), [`vim_file_open`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L352).
- **Line Editing (1)**: [`vim_edit`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L161) with modes: `"insert"`, `"replace"` (starting at line), `"replaceAll"` (clear and insert).
- **Vim Primitives & Automation (7)**:
  - Registers: [`vim_register`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L244) (get/set registers `a-z`, `"`, `0-9`).
  - Marks: [`vim_mark`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L215) (set marks `a-z`).
  - Macros: [`vim_macro`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L481) (`"record"`, `"stop"`, `"play"` with count).
  - Jump List: [`vim_jump`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L567) (`"back"`, `"forward"`, `"list"`).
  - Folds: [`vim_fold`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L538) (`"create"`, `"open"`, `"close"`, `"toggle"`, `"openall"`, `"closeall"`, `"delete"`).
  - Tabs: [`vim_tab`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L510) (`"new"`, `"close"`, `"next"`, `"prev"`, `"first"`, `"last"`, `"list"`).
  - Visual: [`vim_visual`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L270) (creates visual selection between coordinates).
- **Search & Pattern Matching (3)**:
  - [`vim_search`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L380): Buffer search with match count via `searchcount()`.
  - [`vim_search_replace`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L408): Vim substitution (`%s/{pattern}/{replacement}/{flags}`).
  - [`vim_grep`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L438): Project-wide `:vimgrep` with quickfix list integration.
- **Windows, Execution & Status (4)**:
  - [`vim_window`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L188): `"split"`, `"vsplit"`, `"only"`, `"close"`, `"wincmd h/j/k/l"`.
  - [`vim_command`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L99): Run Vim commands. Supports shell commands (`!cmd`) if `ALLOW_SHELL_COMMANDS=true`.
  - [`vim_status`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L136): Status snapshot (cursor, mode, marks, registers, visual selection, layout, current tab, active LSP clients, loaded plugins).
  - [`vim_health`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts#L465): Socket connection check.

### MCP Protocol Features
- **Resources**: `nvim://session` (active buffer contents with line numbers), `nvim://buffers` (JSON array of open buffers with loaded/modified flags and window IDs).
- **Prompts**: `neovim_workflow` (interactive workflow guidance for editing, navigation, search, buffers, windows, macros).

---

## 6. Deep Dive: `cousine/neovim-mcp` (Go)

### Architecture & Connection
- Written in Go (≥ 1.25) using official [`mcp`](https://github.com/modelcontextprotocol/go-sdk) and [`neovim/go-client`](https://github.com/neovim/go-client).
- Compiles to a single, lightning-fast native binary with zero runtime dependencies.
- Main entry: [`cmd/neovim-mcp/main.go`](file:///Users/justinhj/projects/neovim-mcp/cmd/neovim-mcp/main.go).
- Server setup: [`internal/mcp/server.go`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/server.go).
- Client bridge: [`internal/nvim/client.go`](file:///Users/justinhj/projects/neovim-mcp/internal/nvim/client.go).
- Tool registration: [`internal/mcp/tools/register.go`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/register.go).
- Zero plugins required. Connects to `NVIM_MCP_LISTEN_ADDRESS` or `NVIM_MCP_SOCKET_ADDRESS` (default: `/tmp/nvim.sock`).
- Transport: stdio only.

### Capabilities (20 Tools)
The tools are cleanly partitioned into five domain packages:

#### 1. Buffer Tools (5)
- [`get_buffers`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/buffer/get_buffers.go): Lists all open buffers with metadata (title, loaded, modified, line count).
- [`get_current_buffer`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/buffer/get_current_buffer.go): Retrieves details for the active buffer.
- [`open_buffer`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/buffer/open_buffer.go): Opens a file into a buffer (`:edit`).
- [`close_buffer`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/buffer/close_buffer.go): Closes a buffer by title/name (with optional force flag).
- [`switch_buffer`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/buffer/switch_buffer.go): Switches active buffer by title/name (`:buffer`).

#### 2. Text Tools (4)
- [`get_buffer_lines`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/text/get_buffer_lines.go): Read a 1-based line slice (`buffer_title`, `start_line`, `end_line`).
- [`set_buffer_lines`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/text/set_buffer_lines.go): Replace a 1-based line range with new lines (`buffer_title`, `start_line`, `end_line`, `lines`).
- [`insert_text`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/text/insert_text.go): Insert text at the current cursor position.
- [`delete_lines`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/text/delete_lines.go): Delete lines between `start_line` and `end_line`.

#### 3. Cursor & Navigation Tools (4)
- [`get_cursor_position`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/cursor/get_cursor_position.go): Get current line (1-based) and column (0-based).
- [`set_cursor_position`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/cursor/set_cursor_position.go): Move cursor to a specific line and column.
- [`goto_line`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/cursor/goto_line.go): Jump directly to a line number.
- [`search`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/cursor/search.go): Search for a pattern in the current buffer using Vim regex (returns array of match lines and columns, supporting flags `'w'` for wrap and `'b'` for backward).

#### 4. Window Tools (4)
- [`get_windows`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/window/windows.go): List all open windows with IDs, buffer IDs, dimensions (`width`, `height`), and positions (`row`, `col`).
- [`split_window`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/window/split_window.go): Split window (`direction`: `"horizontal"` | `"vertical"`).
- [`close_window`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/window/close_window.go): Close a window by ID.
- [`resize_window`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/window/resize_window.go): **Unique tool** allowing direct pixel/character dimension resizing (`window_id`, `width`, `height`).

#### 5. Command Tools (3)
- [`exec_command`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/command/exec_command.go): Execute an arbitrary Vim Ex command (`command: string`).
- [`exec_lua`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/command/exec_lua.go): Execute arbitrary Lua code in Neovim.
- [`call_function`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/command/call_function.go): **Unique tool** calling any internal Vim/Neovim function by name with structured arguments array (`function_name`, `args`).

### MCP Protocol Features
- **Resources**: `nvim://buffers` (returns JSON array of all open buffers).

---

## 7. Granular Cross-Cutting Feature Comparison

### 7.1 Language Server Protocol (LSP) & Code Intelligence
| Feature | `linw1995` (Rust) | `paulburgess1357` (Python) | `mcp-neovim-server` (TS) | `neovim-mcp` (Go) | Winner & Notes |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Go to Definition** | **Yes** (`lsp_definition`) | No | No | No | **`linw1995` only** |
| **Find References** | **Yes** (`lsp_references`) | No | No | No | **`linw1995` only** |
| **Hover / Type Docs** | **Yes** (`lsp_hover`) | No | No | No | **`linw1995` only** |
| **Document/Workspace Symbols**| **Yes** (2 tools) | No | No | No | **`linw1995` only** |
| **Call Hierarchy** | **Yes** (3 tools) | No | No | No | **`linw1995` only** |
| **Type Hierarchy** | **Yes** (3 tools) | No | No | No | **`linw1995` only** |
| **Code Actions & Fixes** | **Yes** (2 tools) | No | No | No | **`linw1995` only** |
| **LSP Rename** | **Yes** (`lsp_rename`) | No | No | No | **`linw1995` only** |
| **LSP Formatting** | **Yes** (document & range)| No | No | No | **`linw1995` only** |
| **Diagnostics Query** | **Yes** (per buffer & ws) | **Yes** (all & buffer) | Partial (client names) | No | **`linw1995` & `paulburgess1357`** |

### 7.2 Editor State & Situational Awareness
| Feature | `linw1995` (Rust) | `paulburgess1357` (Python) | `mcp-neovim-server` (TS) | `neovim-mcp` (Go) | Winner & Notes |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Editor Mode** | No | **Yes** (normal, visual, etc.) | **Yes** (`mode.mode`) | No | `paulburgess` & `mcp-neovim-server` |
| **Cursor Position** | Yes (`cursor_position`) | Yes (`get_state_brief`) | Yes (`vim_status`) | Yes (`get_cursor_position`)| All four |
| **Numbered Context Lines**| No | **Yes** (in state snapshots) | No | No | **`paulburgess1357` exclusive** |
| **Visual Selection Bounds**| No | **Yes** (`selection` object) | **Yes** (`visualInfo` object) | No | `paulburgess` & `mcp-neovim-server` |
| **Closed Folds Scan** | No | **Yes** (scans closed folds) | No | No | **`paulburgess1357` exclusive** |
| **Marks Inspection** | No | Yes (marks `a-z`) | **Yes** (all set marks `a-z`) | No | `paulburgess` & `mcp-neovim-server` |
| **Registers Inspection** | No | No | **Yes** (non-empty registers) | No | **`mcp-neovim-server` exclusive** |
| **Indent Settings** | No | **Yes** (expandtab, shiftwidth) | No | No | **`paulburgess1357` exclusive** |

### 7.3 Buffer Editing & Modification
| Feature | `linw1995` (Rust) | `paulburgess1357` (Python) | `mcp-neovim-server` (TS) | `neovim-mcp` (Go) | Winner & Notes |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Exact Substring Replace**| No | **Yes** (`find_and_replace_buf`) | No | No | **`paulburgess1357`** (safest: errors if match ≠ 1) |
| **Line-Indexed Edit** | No | No | Yes (`vim_edit`) | **Yes** (`set_buffer_lines`) | `mcp-neovim-server` & `neovim-mcp` |
| **Insert at Cursor** | No | No | No | **Yes** (`insert_text`) | **`neovim-mcp`** |
| **Delete Line Slice** | No | No | No | **Yes** (`delete_lines`) | **`neovim-mcp`** |
| **Vim Regex Substitution** | No | No | **Yes** (`vim_search_replace` via `:s`)| No | **`mcp-neovim-server`** |
| **Full In-Memory Undo** | Custom Lua | **Yes** (`u` restores clean state)| Basic (`u` reverts `vim_edit`)| Basic (`u` reverts edit) | **`paulburgess1357`** designed around undo safety |
| **Universal Doc Identifiers**| **Yes** (buf id, rel, abs) | Relative & buffer name | Buffer name / number | Buffer title / name | **`linw1995`** handles unopened files seamlessly |

### 7.4 Traditional Vim Primitives & Workflow Automation
| Feature | `linw1995` (Rust) | `paulburgess1357` (Python) | `mcp-neovim-server` (TS) | `neovim-mcp` (Go) | Winner & Notes |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Macros (Record / Play)** | No | No | **Yes** (`vim_macro`) | No | **`mcp-neovim-server` exclusive** |
| **Jump List (<C-o>/<C-i>)** | No | No | **Yes** (`vim_jump`) | No | **`mcp-neovim-server` exclusive** |
| **Folds (Create / Toggle)** | No | No | **Yes** (`vim_fold`) | No | **`mcp-neovim-server` exclusive** |
| **Registers (Set & Get)** | No | No | **Yes** (`vim_register`) | No | **`mcp-neovim-server` exclusive** |
| **Marks Management** | No | Via `send_command` | **Yes** (`vim_mark`) | Via `call_function` | **`mcp-neovim-server`** |
| **Tabs Management** | No | Via `send_command` | **Yes** (`vim_tab`) | No | **`mcp-neovim-server`** |
| **Project Grep (Quickfix)**| No | No | **Yes** (`vim_grep`) | No | **`mcp-neovim-server`** |
| **Window Resizing** | No | No | No | **Yes** (`resize_window`) | **`neovim-mcp` exclusive** |
| **Direct RPC Function Call**| No | No | No | **Yes** (`call_function`) | **`neovim-mcp` exclusive** |

### 7.5 Visual Feedback & Extmarks
| Feature | `linw1995` (Rust) | `paulburgess1357` (Python) | `mcp-neovim-server` (TS) | `neovim-mcp` (Go) | Winner & Notes |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Line Highlights** | No | **Yes** (`highlight_ranges`)| No | No | **`paulburgess1357` exclusive** (theme-aware) |
| **Virtual Text Notes** | No | **Yes** (`add_virtual_texts`)| No | No | **`paulburgess1357` exclusive** (inline/above/below) |
| **Set Visual Selection** | No | No | **Yes** (`vim_visual`) | No | **`mcp-neovim-server`** |

### 7.6 Terminals & System Execution
| Feature | `linw1995` (Rust) | `paulburgess1357` (Python) | `mcp-neovim-server` (TS) | `neovim-mcp` (Go) | Winner & Notes |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Terminal Job Channels** | No | **Yes** (`send_to_terminal`)| No | No | **`paulburgess1357` exclusive** (types into shell without stealing focus) |
| **Shell Commands (`:!`)** | No | Possible via `send_command`| **Yes** (via `ALLOW_SHELL_COMMANDS` flag) | Possible via `exec_command`| `mcp-neovim-server` guards with env var |

### 7.7 MCP Protocol Conformance
| Feature | `linw1995` (Rust) | `paulburgess1357` (Python) | `mcp-neovim-server` (TS) | `neovim-mcp` (Go) | Winner & Notes |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **MCP Tools** | 33 tools (+ dynamic) | 18 tools | 19 tools | 20 tools | All four |
| **MCP Resources** | **Yes** (5 URI schemes) | None | **Yes** (2 URI schemes) | **Yes** (1 URI scheme) | `linw1995` has deepest URI schemes |
| **MCP Prompts** | None | None (provides rules) | **Yes** (`neovim_workflow`)| None | **`mcp-neovim-server` exclusive** |
| **Dynamic Tool Registry**| **Yes** (custom Lua tools) | None | None | None | **`linw1995` exclusive** |
| **Tool Change Events** | **Yes** (`list_changed`) | None | None | None | **`linw1995` exclusive** |
| **Transports** | **stdio & HTTP / SSE** | stdio only | stdio only | stdio only | **`linw1995` exclusive** |

---

## 8. Comparative Assessment & Recommendations

### Summary Profile of Each Server

| Server | Superpower | Blind Spot | Ideal Use Case |
| :--- | :--- | :--- | :--- |
| **[`linw1995/nvim-mcp`](file:///Users/justinhj/projects/nvim-mcp-linw1995/)** (Rust) | **Semantic Code Intelligence**: Complete LSP suite (definitions, references, call/type hierarchies, symbols, renames) + custom Lua dynamic tools + HTTP/SSE. | Lacks interactive editing ergonomics (no substring search-and-replace, visual highlights, or terminal channel tools). | Code navigation, architectural analysis, refactoring, and multi-session development hubs. |
| **[`paulburgess1357/nvim-mcp`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/)** (Python) | **Interactive Collaboration & Visual Feedback**: Deep editor awareness, safe in-memory editing with full undo, theme-aware extmark highlights, virtual text notes, and terminal job channels. | Zero LSP intelligence beyond raw diagnostics; no MCP resources/prompts. | Live pair-programming, interactive code reviews, inline bug highlighting, and safe autonomous editing. |
| **[`mcp-neovim-server`](file:///Users/justinhj/projects/mcp-neovim-server/)** (TypeScript) | **Vim Primitives & Workflow Automation**: Complete control over macros, registers, marks, jump lists, folds, tabs, splits, and regex substitution. Only server with MCP Prompts. | Requires manual socket setup (`--listen /tmp/nvim`); editing is line-index-based; no LSP query tools. | Automating complex Vim workflows, macro playback, quickfix-based project searches, and Claude Desktop `.dxt` users. |
| **[`cousine/neovim-mcp`](file:///Users/justinhj/projects/neovim-mcp/)** (Go) | **Lightweight Modular RPC & Window Control**: Compiled static binary, dedicated window resizing, cursor-based text insertion, line deletion, and direct RPC function calls with arguments. | No LSP intelligence, no visual extmark annotations, requires fixed socket path. | Environments requiring a tiny, lightning-fast compiled binary with zero runtime dependencies and precise window/line manipulation. |

### Decision Guide: When to Pick Which Server

1. **Pick [`linw1995/nvim-mcp`](file:///Users/justinhj/projects/nvim-mcp-linw1995/)** if:
   - You need the agent to perform **deep codebase research**: finding definitions, all callers/callees via call hierarchy, interface implementations, and workspace symbol lookups.
   - You want to **extend the MCP server with custom Lua logic** tailored to your personal Neovim plugins.
   - You want **HTTP/SSE transport** for remote containers, SSH forwarding, or browser-based AI clients.
   - You run **multiple concurrent Neovim instances** and want a unified multi-instance routing hub.

2. **Pick [`paulburgess1357/nvim-mcp`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/)** if:
   - You want **zero-friction, zero-config pair programming**: launch via `uvx nvim-mcp` and it attaches to Neovim 0.11 immediately.
   - You want the agent to **visually annotate your buffer**: coloring error lines and writing virtual text notes above/below your code without modifying disk files.
   - You want **safe in-memory edits**: the agent edits buffers in memory, respects undo history (`u`), and lets you review changes before saving.
   - You use **embedded terminal splits** and want the agent to type commands into your shell without stealing your focus.

3. **Pick [`mcp-neovim-server`](file:///Users/justinhj/projects/mcp-neovim-server/)** if:
   - You want the agent to interact with **traditional Vim workflows**: recording or replaying macros, inspecting and manipulating registers, setting marks, folding code blocks, or navigating the jump list.
   - You want native **Vim regex substitution** (`:s`) and **project grep** via quickfix lists.
   - You are using **Claude Desktop** and want a drag-and-drop `.dxt` package or standard npm/npx setup.
   - You want **MCP Prompts** (`neovim_workflow`) directly exposed in your MCP client UI.

4. **Pick [`cousine/neovim-mcp`](file:///Users/justinhj/projects/neovim-mcp/)** if:
   - You prefer a **compiled, zero-dependency static binary** (installable via Homebrew or single executable) that launches instantly with minimal memory overhead.
   - You need **precise window layout management**, including programmatic window resizing (`resize_window`).
   - You need to invoke arbitrary internal Neovim functions with typed arguments (`call_function`).
   - You prefer clean, modular tool categories (`buffer`, `text`, `cursor`, `window`, `command`).

---

## 9. Directory & File Reference Links

### [`linw1995/nvim-mcp`](file:///Users/justinhj/projects/nvim-mcp-linw1995/) (Rust)
- Server core & routing: [`core.rs`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/core.rs), [`tools.rs`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/tools.rs), [`resources.rs`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/resources.rs)
- Hybrid & dynamic tool registry: [`hybrid_router.rs`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/hybrid_router.rs), [`lua_tools.rs`](file:///Users/justinhj/projects/nvim-mcp-linw1995/src/server/lua_tools.rs)
- Neovim companion plugin: [`init.lua`](file:///Users/justinhj/projects/nvim-mcp-linw1995/lua/nvim-mcp/init.lua)
- Reference documentation: [`tools.md`](file:///Users/justinhj/projects/nvim-mcp-linw1995/docs/tools.md), [`resources.md`](file:///Users/justinhj/projects/nvim-mcp-linw1995/docs/resources.md)

### [`paulburgess1357/nvim-mcp`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/) (Python)
- Server & tool definitions: [`server.py`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/server.py)
- Manager & retry engine: [`manager.py`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/manager.py)
- Discovery & process tracing: [`discovery.py`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/discovery.py)
- Neovim Lua operations: [`lua.py`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/src/nvim_mcp/lua.py)
- Agent rules & config generators: [`AGENTS-EXAMPLE.md`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/config/AGENTS-EXAMPLE.md), [`generate-configs.sh`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/config/generate-configs.sh)
- Reference documentation: [`TOOLS.md`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/docs/TOOLS.md), [`MULTIPLE_INSTANCES.md`](file:///Users/justinhj/projects/nvim-mcp-paulburgess1357/docs/MULTIPLE_INSTANCES.md)

### [`mcp-neovim-server`](file:///Users/justinhj/projects/mcp-neovim-server/) (TypeScript / Node.js)
- MCP Server entry point: [`index.ts`](file:///Users/justinhj/projects/mcp-neovim-server/src/index.ts)
- Neovim Manager & client bridge: [`neovim.ts`](file:///Users/justinhj/projects/mcp-neovim-server/src/neovim.ts)
- Configuration & scripts: [`package.json`](file:///Users/justinhj/projects/mcp-neovim-server/package.json), [`tsconfig.json`](file:///Users/justinhj/projects/mcp-neovim-server/tsconfig.json)
- Documentation: [`README.md`](file:///Users/justinhj/projects/mcp-neovim-server/README.md)

### [`neovim-mcp`](file:///Users/justinhj/projects/neovim-mcp/) (Go)
- Main binary entry point: [`main.go`](file:///Users/justinhj/projects/neovim-mcp/cmd/neovim-mcp/main.go)
- Server constructor: [`server.go`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/server.go)
- Tool registration: [`register.go`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/tools/register.go)
- Resource registration: [`register.go`](file:///Users/justinhj/projects/neovim-mcp/internal/mcp/resources/register.go)
- Neovim RPC client: [`client.go`](file:///Users/justinhj/projects/neovim-mcp/internal/nvim/client.go)
- Configuration: [`config.go`](file:///Users/justinhj/projects/neovim-mcp/internal/config/config.go)
- Documentation & developer guidelines: [`README.md`](file:///Users/justinhj/projects/neovim-mcp/README.md), [`AGENTS.md`](file:///Users/justinhj/projects/neovim-mcp/AGENTS.md)
