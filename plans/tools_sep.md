# Neovim MCP Capabilities & Master Tool Inventory (`tools_sep.md`)

## 1. Executive Summary & Purpose

This document provides a comprehensive evaluation of the **Model Context Protocol (MCP)** capability surface for Neovim, synthesizing analysis from:
- **`server.org`** (`/Users/justinhj/iCloud/nvim/server.org`)
- **`plans/nvim-mcp-review.md`** & **`plans/next-steps-based-on-comparison.md`**
- The four primary Neovim MCP server alternatives:
  1. **`bigcodegen/mcp-neovim-server`** (TypeScript / Node.js) — *The Native Vim Workflow Automator* (320★)
  2. **`linw1995/nvim-mcp`** (Rust) — *The Code Intelligence & LSP Proxy* (70★)
  3. **`paulburgess1357/nvim-mcp`** (Python) — *The Interactive Pair-Programming Partner* (62★)
  4. **`cousine/neovim-mcp`** (Go) — *The Modular Neovim RPC Bridge* (18★)
  *(with architectural context from `ravitemer/mcphub.nvim`, 1786★)*

The primary objective is to:
1. Map out all **broad capabilities** an AI agent can exercise within Neovim (e.g. situational awareness, in-memory buffer editing, visual feedback via extmarks, terminal execution, LSP code intelligence).
2. Catalog all discrete **MCP primitives (tools, resources, prompts)** across the alternatives.
3. Build an exhaustive **Master Inventory of Tools and Capabilities** to guide the curation of what **`neovim-boss` (`nb`)** should support.

---

## 2. Broad Capability Taxonomy (What Can an Agent Do in Neovim?)

Before inspecting individual tool signatures, we can group all editor interactions across the ecosystem into **10 Broad Functional Domains**:

```
+----------------------------------------------------------------------------------------------------+
|                                  BROAD CAPABILITY SURFACE                                         |
+----------------------------------------------------------------------------------------------------+
| 1. Situational Awareness & Editor Telemetry   │ "What am I looking at? What is selected?"         |
| 2. Buffer Reading & Document Inspection       │ View full buffer, line slices, line counts        |
| 3. Buffer Mutation & In-Memory Editing        │ Safe substring replace, line editing, undo tree   |
| 4. Navigation & Layout Management             │ Cursor positioning, splits, resize, tabs, jumps  |
| 5. Visual Annotations & Feedback (Extmarks)   │ Non-destructive line highlights & virtual text    |
| 6. Traditional Vim Primitives & Workflow      │ Registers, marks, macros, folds, project vimgrep  |
| 7. Terminal & Interactive Job Control         │ Non-stealing input delivery to terminal channels  |
| 8. Language Server Protocol (LSP)             │ Diagnostics, definitions, hover, symbols, fixes   |
| 9. Scripting & Execution                      │ Lua eval, Vimscript eval, Ex commands, raw keys   |
| 10. Connection Discovery & Session Lifecycle  │ Socket probe, auto-detection, multi-instance hub   |
+----------------------------------------------------------------------------------------------------+
```

### Domain 1: Situational Awareness & Editor Telemetry
- **Core Need**: As highlighted in `server.org`: *"what am I looking at? what have i selected? useful when chatting for the agent to see the current buffer and what you are doing"*.
- **Capabilities**:
  - Fast orientation snapshot on every turn: active mode (`n`, `i`, `v`, `V`), working directory (`cwd`), active buffer, alternate buffer.
  - Active window context: cursor position `(line, col)`, window bounds, and immediate neighborhood context lines (e.g. 5 lines above/below cursor).
  - Visual selection inspection: exact coordinate ranges of the user's current visual highlight.
  - Open terminal buffers list and background processes.
  - Fold awareness: detecting closed fold ranges so the agent doesn't misinterpret collapsed blocks.

### Domain 2: Buffer Reading & Document Inspection
- **Core Need**: Fetching document content reliably and efficiently without file system races.
- **Capabilities**:
  - Full buffer text retrieval with 1-based line numbering.
  - Line slice retrieval (`[start_line, end_line]`).
  - Document identification via Universal Document Identifiers (buffer number, relative path, or absolute path).
  - Continuous buffer telemetry via MCP Resources (`neovim://buffers`, `nvim://session`).

### Domain 3: Buffer Mutation & In-Memory Editing
- **Core Need**: Safe, robust code editing that respects developer workflow and editor state.
- **Capabilities**:
  - **Safe Substring Replacement**: Finding a unique search block and replacing it without line drift; failing safely if 0 or >1 matches occur.
  - **In-Memory Modification**: Modifying buffers directly in Neovim memory rather than saving directly to disk, allowing the developer to review diffs before saving.
  - **Preservation of Undo Tree**: Edits applied cleanly such that pressing `u` in normal mode cleanly reverses the agent's changes.
  - **Line-Indexed Mutation**: Replacing slices of lines (`set_buffer_lines`), inserting lines/text (`insert_text`), or deleting line slices (`delete_lines`).
  - **Whole-Buffer Rewriting**: Replacing complete buffer contents (`write_full_buf`).
  - **Vim Substitution**: Executing `:s/pattern/replacement/flags` with scoping.
  - **File/Buffer Lifecycle**: Opening files into buffers (`open_buffer`, `vim_file_open`), saving buffers (`vim_buffer_save`), and closing buffers (`close_buffer`).

### Domain 4: Navigation & Window/Tab Layout Management
- **Core Need**: Guiding developer attention and organizing the editor workspace.
- **Capabilities**:
  - Moving cursor to coordinates `(line, col)` or jumping to line (`goto_line`, `navigate`).
  - Window splitting: horizontal (`:split`) or vertical (`:vsplit`).
  - Window directional focus: moving between splits via `wincmd h/j/k/l`.
  - Closing windows (`close_window`, `:only`).
  - Programmatic window resizing: setting explicit character width or height (`resize_window`).
  - Tabpage management: opening, closing, switching, and listing tabpages (`vim_tab`).
  - Jump list navigation: stepping backward and forward through jump history (`vim_jump`).

### Domain 5: Visual Feedback & Non-Destructive Annotations
- **Core Need**: Communicating with the developer visually inside the code without altering buffer contents or dirtying git status.
- **Capabilities**:
  - **Extmark Highlights**: Highlighting single or multiple line ranges using theme-aware highlight groups (e.g. `DiagnosticUnderlineError`, `Visual`, `DiffAdd`).
  - **Virtual Text Notes**: Attaching inline text, comments, or explanations at `"eol"`, `"above"`, or `"below"` specific lines using Neovim's `nvim_buf_set_extmark` API.
  - **Visual Mode Selection**: Programmatically creating visual mode selections to emphasize blocks of code for the user.
  - **Clearing Visuals**: Removing all MCP-created highlights or virtual texts in a single command (`clear_highlights`, `clear_virtual_texts`).

### Domain 6: Traditional Vim Primitives & Workflow Automation
- **Core Need**: Leveraging Neovim's rich native editing vocabulary and facilities.
- **Capabilities**:
  - **Registers**: Getting and setting contents of registers (`"`, `a-z`, `0-9`, `*`, `+`).
  - **Marks**: Setting and querying cursor marks `a-z`.
  - **Macros**: Recording, stopping, and replaying keystroke macros to automate repetitive edits.
  - **Code Folding**: Programmatically creating, toggling, opening, closing, or deleting code folds.
  - **Buffer Search**: In-buffer regex search with occurrence count via `searchcount()`.
  - **Project Grep**: Executing `:vimgrep` across the workspace and populating results to Neovim's quickfix list.

### Domain 7: Terminal & Interactive Job Control
- **Core Need**: Running builds, linters, tests, and CLI tools within Neovim.
- **Capabilities**:
  - **Non-Stealing Terminal Input**: Writing commands directly into a terminal's underlying job channel (`nvim_chan_send`) without stealing focus from the active window or disrupting the user's cursor.
  - **Review vs Execution**: Staging text at the terminal prompt for user review (`submit=false`) or immediately submitting with `<CR>` (`submit=true`).
  - **Shell Command Execution**: Running external shell commands via Vim Ex mode (`:!cmd`).

### Domain 8: Language Server Protocol (LSP) Code Intelligence
- **Core Need**: Utilizing the semantic understanding of running language servers (types, ASTs, references) for agent reasoning.
- **Capabilities**:
  - Diagnostics: Fetching compiler/linter errors, warnings, and hints across all buffers or for a specific file.
  - Navigation: Jump to definition, declaration, type definition, and implementation.
  - Cross-references: Finding symbol references across the entire workspace.
  - Hover: Fetching type signatures and documentation markdown.
  - Symbols: Listing document outline symbols and querying workspace symbols.
  - Refactoring: Fetching code actions, resolving code actions, applying workspace edits, and renaming symbols.
  - Formatting: Formatting full documents or specific ranges, and organizing imports.
  - Hierarchies: Querying incoming/outgoing call hierarchies and type hierarchies (supertypes/subtypes).
  - Readiness: Polling LSP client status (`wait_for_lsp_ready`, `lsp_clients`).

### Domain 9: Scripting, Function Calling & Command Dispatch
- **Core Need**: Providing ultimate escape hatches and extensibility.
- **Capabilities**:
  - Vimscript expression evaluation (`eval_vimscript`, `eval`).
  - Arbitrary Lua code evaluation (`exec_lua`).
  - Ex command execution (`vim_command`, `send_command`, `exec_command`).
  - Raw keystroke injection (`send_keys` via `nvim_input`).
  - Direct function calling with structured argument arrays (`call_function`).

### Domain 10: Connection Discovery & Session Lifecycle
- **Core Need**: Making connections seamless and effortless across various environments.
- **Capabilities**:
  - Zero-config auto-discovery: inspecting `$NVIM`, walking filesystem sockets in `/tmp` and `$XDG_RUNTIME_DIR`.
  - Project socket affinity: matching socket cwd to current workspace.
  - Multi-instance session multiplexing: managing multiple Neovim instances over a single MCP connection via `connection_id`.
  - Connection health checks: validating active socket connectivity.

---

## 3. Alternative Server Deep Dives: MCP Primitives Breakdown

### 3.1 `bigcodegen/mcp-neovim-server` (TypeScript / Node.js)
- **Stars**: ~320★
- **Stack**: TypeScript, `@modelcontextprotocol/sdk`, `neovim` npm package (Node.js runtime, ~50MB RAM, 12 threads).
- **Distribution**: npm, `npx`, Claude Desktop `.dxt` bundle.
- **Neovim Requirements**: Zero plugins required. Listens on Unix socket `$NVIM_SOCKET_PATH` (default `/tmp/nvim`).
- **MCP Primitives**: 19 Tools, 2 Resources, 1 Prompt.

#### Tools (19)
| Tool Name | Parameters | Types / Constraints | Description |
| :--- | :--- | :--- | :--- |
| `vim_buffer` | `filename` *(opt)* | `string` | Get buffer contents with 1-based line numbers. |
| `vim_command` | `command` *(req)* | `string` | Execute Vim commands (supports `!` for shell commands if `ALLOW_SHELL_COMMANDS=true`). |
| `vim_status` | *(none)* | — | Comprehensive status: cursor position, mode, filename, visual selection, layout, marks, registers, cwd, plugins, LSP. |
| `vim_edit` | `startLine` *(req)*<br>`mode` *(req)*<br>`lines` *(req)* | `number` (1-indexed)<br>`"insert" \| "replace" \| "replaceAll"`<br>`string` | Edit lines in buffer using insertion, replacement, or complete rewrite. |
| `vim_window` | `command` *(req)* | `"split" \| "vsplit" \| "only" \| "close" \| "wincmd h" \| "wincmd j" \| "wincmd k" \| "wincmd l"` | Window layout manipulation and split navigation. |
| `vim_mark` | `mark` *(req)*<br>`line` *(req)*<br>`column` *(req)* | `string` (`[a-z]`)<br>`number` (1-indexed)<br>`number` (0-indexed) | Set named mark at line and column. |
| `vim_register` | `register` *(req)*<br>`content` *(req)* | `string` (`[a-z"]`)<br>`string` | Set content of a specified Vim register. |
| `vim_visual` | `startLine` *(req)*<br>`startColumn` *(req)*<br>`endLine` *(req)*<br>`endColumn` *(req)* | `number`<br>`number`<br>`number`<br>`number` | Programmatically create a visual mode selection between coordinates. |
| `vim_buffer_switch` | `identifier` *(req)* | `string \| number` | Switch active buffer by buffer number or filename/path. |
| `vim_buffer_save` | `filename` *(opt)* | `string` | Save current buffer, or save out to a new file path. |
| `vim_file_open` | `filename` *(req)* | `string` | Open a file into a new buffer. |
| `vim_search` | `pattern` *(req)*<br>`ignoreCase` *(opt)*<br>`wholeWord` *(opt)* | `string`<br>`boolean`<br>`boolean` | Search inside current buffer with regex and report match count. |
| `vim_search_replace` | `pattern` *(req)*<br>`replacement` *(req)*<br>`global` *(opt)*<br>`ignoreCase` *(opt)*<br>`confirm` *(opt)* | `string`<br>`string`<br>`boolean`<br>`boolean`<br>`boolean` | Find and replace using Vim regex substitution (`%s/...`). |
| `vim_grep` | `pattern` *(req)*<br>`filePattern` *(opt)* | `string`<br>`string` (default `**/*`) | Project-wide `:vimgrep` populated to the quickfix list. |
| `vim_health` | *(none)* | — | Check Neovim socket connection health. |
| `vim_macro` | `action` *(req)*<br>`register` *(opt)*<br>`count` *(opt)* | `"record" \| "stop" \| "play"`<br>`string` (`[a-z]`)<br>`number` | Record, stop recording, or play back a macro register. |
| `vim_tab` | `action` *(req)*<br>`filename` *(opt)* | `"new" \| "close" \| "next" \| "prev" \| "first" \| "last" \| "list"`<br>`string` | Tab page management and navigation. |
| `vim_fold` | `action` *(req)*<br>`startLine` *(opt)*<br>`endLine` *(opt)* | `"create" \| "open" \| "close" \| "toggle" \| "openall" \| "closeall" \| "delete"`<br>`number`<br>`number` | Code folding operations over line ranges. |
| `vim_jump` | `direction` *(req)* | `"back" \| "forward" \| "list"` | Jump list navigation (`<C-o>`, `<C-i>`) and list inspection. |

#### Resources (2)
| URI | MIME Type | Description |
| :--- | :--- | :--- |
| `nvim://session` | `text/plain` | Current Neovim editor session (numbered lines of the current active buffer). |
| `nvim://buffers` | `application/json` | List of all open buffers with metadata (number, name, listed, loaded, modified, syntax, window IDs). |

#### Prompts (1)
| Prompt Name | Arguments | Description |
| :--- | :--- | :--- |
| `neovim_workflow` | `task`: `"editing" \| "navigation" \| "search" \| "buffers" \| "windows" \| "macros"` *(req)* | Step-by-step guidance instructing the agent on optimal Vim tool chaining for a given task category. |

---

### 3.2 `linw1995/nvim-mcp` (Rust)
- **Stars**: ~70★
- **Stack**: Rust, `rmcp` protocol crate, `nvim-rs` (Compiled binary ~22.5MB, ~2MB RAM).
- **Distribution**: `cargo install`, Nix flake.
- **Neovim Requirements**: **Requires companion Lua plugin** (`nvim-mcp.lua`). Creates per-project sockets named `nvim-mcp.<git-root>.<pid>.sock`.
- **Transports**: **Both stdio and streamable HTTP / SSE** (`--http-port`).
- **MCP Primitives**: 33 Static Tools (+ dynamic user Lua tools), 5 Resource URI templates, 0 Prompts.

#### Tools (33 Static)
| Tool Name | Category | Parameters & Constraints | Description |
| :--- | :--- | :--- | :--- |
| `get_targets` | Connection | *(none)* | Discover available Neovim sockets on the system (prioritizes local project root). |
| `connect` | Connection | `path` *(req, string)* | Connect to a Neovim instance via Unix domain socket or named pipe. Returns `connection_id`. |
| `connect_tcp` | Connection | `host` *(req, string)*, `port` *(req, number)* | Connect to a remote Neovim instance over TCP. Returns `connection_id`. |
| `disconnect` | Connection | `connection_id` *(req, string)* | Disconnect from a specific active Neovim session. |
| `list_buffers` | Buffer | `connection_id` *(req, string)* | List open buffers with IDs, names, and line counts. |
| `read` | Buffer | `connection_id` *(req, string)*<br>`identifier` *(req, string \| number)*<br>`start_line` *(opt, number)*<br>`end_line` *(opt, number)* | Read document contents by Universal Document Identifier (buffer ID, relative path, or absolute path) with line range. |
| `buffer_diagnostics`| Buffer | `connection_id` *(req, string)*<br>`identifier` *(req, string \| number)* | Fetch LSP diagnostics for a specific buffer. |
| `cursor_position` | State | `connection_id` *(req, string)* | Get current buffer and 0-indexed cursor coordinates. |
| `navigate` | Navigation | `connection_id` *(req, string)*<br>`path` *(req, string)*<br>`line` *(opt, number)*<br>`column` *(opt, number)* | Open file and jump directly to target line/column. |
| `exec_lua` | Scripting | `connection_id` *(req, string)*<br>`code` *(req, string)* | Execute arbitrary Lua code inside Neovim and return result. |
| `wait_for_lsp_ready`| LSP | `connection_id` *(req, string)*<br>`timeout_ms` *(opt, number)* | Block until LSP clients finish initializing and indexing. |
| `lsp_clients` | LSP | `connection_id` *(req, string)* | List active LSP clients attached to the workspace. |
| `lsp_definition` | LSP | `connection_id` *(req, string)*<br>`identifier` *(req)*, `line` *(req)*, `column` *(req)* | Jump to symbol definition. |
| `lsp_declaration` | LSP | `connection_id` *(req)*<br>`identifier` *(req)*, `line` *(req)*, `column` *(req)* | Jump to symbol declaration. |
| `lsp_type_definition`| LSP | `connection_id` *(req)*<br>`identifier` *(req)*, `line` *(req)*, `column` *(req)* | Jump to type definition. |
| `lsp_implementations`| LSP | `connection_id` *(req)*<br>`identifier` *(req)*, `line` *(req)*, `column` *(req)* | Find symbol implementations. |
| `lsp_references` | LSP | `connection_id` *(req)*<br>`identifier` *(req)*, `line` *(req)*, `column` *(req)* | Find all references across project. |
| `lsp_hover` | LSP | `connection_id` *(req)*<br>`identifier` *(req)*, `line` *(req)*, `column` *(req)* | Get hover type signatures and documentation markdown. |
| `lsp_document_symbols`| LSP | `connection_id` *(req)*<br>`identifier` *(req)* | Fetch document symbol tree / outline. |
| `lsp_workspace_symbols`| LSP | `connection_id` *(req)*<br>`query` *(req, string)* | Search workspace-wide symbol table. |
| `lsp_code_actions` | LSP | `connection_id` *(req)*<br>`identifier` *(req)*, `range` *(req)* | Fetch available code actions and quickfixes for a range. |
| `lsp_resolve_code_action`| LSP | `connection_id` *(req)*<br>`action` *(req, object)* | Resolve details for a selected code action. |
| `lsp_apply_edit` | LSP | `connection_id` *(req)*<br>`edit` *(req, object)* | Apply a workspace edit returned from an LSP action. |
| `lsp_rename` | LSP | `connection_id` *(req)*<br>`identifier` *(req)*, `line` *(req)*, `column` *(req)*, `new_name` *(req)* | Perform semantic symbol rename across workspace. |
| `lsp_formatting` | LSP | `connection_id` *(req)*<br>`identifier` *(req)* | Format entire document via attached LSP. |
| `lsp_range_formatting`| LSP | `connection_id` *(req)*<br>`identifier` *(req)*, `range` *(req)* | Format specific line/character range via LSP. |
| `lsp_organize_imports`| LSP | `connection_id` *(req)*<br>`identifier` *(req)* | Run LSP organize imports code action. |
| `lsp_call_hierarchy_prepare` | LSP | `connection_id` *(req)*<br>`identifier` *(req)*, `line` *(req)*, `column` *(req)* | Prepare call hierarchy at cursor position. |
| `lsp_call_hierarchy_incoming_calls`| LSP | `connection_id` *(req)*<br>`item` *(req, object)* | Get all incoming callers for a function. |
| `lsp_call_hierarchy_outgoing_calls`| LSP | `connection_id` *(req)*<br>`item` *(req, object)* | Get all outgoing calls from a function. |
| `lsp_type_hierarchy_prepare` | LSP | `connection_id` *(req)*<br>`identifier` *(req)*, `line` *(req)*, `column` *(req)* | Prepare type hierarchy at cursor position. |
| `lsp_type_hierarchy_supertypes` | LSP | `connection_id` *(req)*<br>`item` *(req, object)* | Query supertypes / base classes of a type. |
| `lsp_type_hierarchy_subtypes` | LSP | `connection_id` *(req)*<br>`item` *(req, object)* | Query subtypes / derived implementations of a type. |

#### Dynamic Lua Tools & Change Notifications
- Users can define custom Lua functions in Neovim that automatically register as MCP tools.
- The server emits `notifications/tools/list_changed` to the MCP client dynamically.

#### Resources (5)
| URI Template | Description |
| :--- | :--- |
| `nvim-connections://` | List of all discovered and active Neovim connections. |
| `nvim-tools://` | List of global tools available across connections. |
| `nvim-tools://{conn_id}` | Connection-specific tools available for a target session. |
| `nvim-diagnostics://{conn_id}/workspace` | Workspace-wide LSP diagnostic report. |
| `nvim-diagnostics://{conn_id}/buffer/{buf_id}` | Buffer-specific LSP diagnostic report. |

---

### 3.3 `paulburgess1357/nvim-mcp` (Python)
- **Stars**: ~62★
- **Stack**: Python ≥ 3.10, official `mcp` SDK, custom socket msgpack client (`uvx` / `pip`, ~130MB total RAM when invoked via uvx supervisor).
- **Distribution**: `uvx`, `pip`, Nix flake, Cursor plugin preset.
- **Neovim Requirements**: **Zero plugins required**. Interacts directly over native msgpack-RPC socket. Auto-discovers sockets in `/tmp` and `$XDG_RUNTIME_DIR`.
- **MCP Primitives**: 18 Tools, 0 Resources, 0 Prompts (uses external rule files `AGENTS.md` / `.mdc`).

#### Tools (18)
| Tool Name | Category | Parameters & Constraints | Description |
| :--- | :--- | :--- | :--- |
| `get_state_brief` | State | `buffer` *(opt, number \| string)* | Fast orientation snapshot: mode, cwd, listed/modified buffers, active window with numbered cursor context lines, alternate window, open terminals. Designed for turn start. |
| `get_state` | State | `buffer` *(opt, number \| string)* | Full session snapshot: mode, cwd, listed buffers, all visible windows, visual selection bounds, closed folds, diagnostic summary count, marks `a-z`, active MCP highlights/virtual text, indent settings. |
| `connect` | Connection | `target` *(opt, number \| string)* | Connect to a discovered instance by index, socket path, or PID. |
| `read_full_buf` | Buffer | `buffer` *(req, number \| string)* | Read entire buffer contents with line numbers. |
| `read_buf_range` | Buffer | `buffer` *(req)*<br>`start_line` *(req, number)*<br>`end_line` *(req, number)* | Read specific line range from buffer with line numbers. |
| `find_and_replace_buf`| Editing | `buffer` *(req)*<br>`find` *(req, string)*<br>`replace` *(req, string)* | **Safe in-memory search-and-replace**. Fails if string is missing or ambiguous (not unique). Preserves undo history (`u`). Does not write to disk. |
| `write_full_buf` | Editing | `buffer` *(req)*<br>`content` *(req, string)* | Replace entire buffer contents in-memory with full undo support. |
| `send_command` | Execution | `command` *(req, string)* | Run one or more Vim Ex commands (`:w`, `:split`, `:e path`). |
| `send_keys` | Execution | `keys` *(req, string)* | Send raw keystrokes directly via `nvim_input` (prepends `<Esc>` automatically). Avoids Lua eval overhead. |
| `send_to_terminal` | Terminal | `terminal` *(req, number \| string)*<br>`text` *(req, string)*<br>`submit` *(opt, boolean, default: false)* | Write input directly into a terminal buffer's job channel without stealing focus or shifting cursor. Staged for review if `submit=false`; executed if `submit=true`. |
| `get_all_diagnostics` | Diagnostics | *(none)* | Retrieve all LSP diagnostics across all open buffers (errors, warnings, hints). |
| `get_buf_diagnostics` | Diagnostics | `buffer` *(req, number \| string)* | Retrieve LSP diagnostics for a single buffer. |
| `highlight_range` | Extmarks | `buffer` *(req)*<br>`start_line` *(req)*, `end_line` *(req)*<br>`group` *(opt, string, default: "DiffAdd")* | Annotate a line range with a colored highlight using Neovim extmarks. Non-destructive. |
| `highlight_ranges` | Extmarks | `buffer` *(req)*<br>`ranges` *(req, array of objects)* | Annotate multiple line ranges at once. |
| `clear_highlights` | Extmarks | `buffer` *(req)* | Remove all MCP-applied highlights from a buffer. |
| `add_virtual_text` | Extmarks | `buffer` *(req)*<br>`line` *(req, number)*<br>`text` *(req, string)*<br>`pos` *(opt, "eol" \| "above" \| "below")*<br>`group` *(opt, string)* | Attach a visual text note to a line without modifying buffer contents. |
| `add_virtual_texts` | Extmarks | `buffer` *(req)*<br>`annotations` *(req, array of objects)* | Attach multiple virtual text notes at once. |
| `clear_virtual_texts` | Extmarks | `buffer` *(req)* | Remove all MCP-applied virtual text annotations from a buffer. |

---

### 3.4 `cousine/neovim-mcp` (Go)
- **Stars**: ~18★
- **Stack**: Go (≥ 1.25), `modelcontextprotocol/go-sdk`, `neovim/go-client` (Compiled static binary ~5.7MB, ~6MB RAM).
- **Distribution**: `brew install cousine/tap/neovim-mcp`, GitHub releases.
- **Neovim Requirements**: **Zero plugins required**. Connects to `NVIM_MCP_SOCKET_ADDRESS` (default `/tmp/nvim.sock`).
- **MCP Primitives**: 20 Tools, 1 Resource, 0 Prompts.

#### Tools (20 in 5 Domain Packages)
| Tool Name | Package | Parameters & Constraints | Description |
| :--- | :--- | :--- | :--- |
| `get_buffers` | `buffer` | *(none)* | List all open buffers with metadata (title, loaded, modified, line count). |
| `get_current_buffer` | `buffer` | *(none)* | Retrieve detailed properties for the currently active buffer. |
| `open_buffer` | `buffer` | `path` *(req, string)* | Open a file into a buffer (`:edit`). |
| `close_buffer` | `buffer` | `buffer_title` *(req, string)*<br>`force` *(opt, boolean)* | Close a buffer by title/path (with optional force flag `:bd!`). |
| `switch_buffer` | `buffer` | `buffer_title` *(req, string)* | Switch active window focus to a buffer by title/path (`:buffer`). |
| `get_buffer_lines` | `text` | `buffer_title` *(req, string)*<br>`start_line` *(req, number)*<br>`end_line` *(req, number)* | Read 1-based line slice from buffer. |
| `set_buffer_lines` | `text` | `buffer_title` *(req, string)*<br>`start_line` *(req, number)*<br>`end_line` *(req, number)*<br>`lines` *(req, array of strings)* | Replace a 1-based line range with new lines. |
| `insert_text` | `text` | `text` *(req, string)* | Insert text at the current cursor position. |
| `delete_lines` | `text` | `buffer_title` *(req, string)*<br>`start_line` *(req, number)*<br>`end_line` *(req, number)* | Delete a 1-based range of lines from a buffer. |
| `get_cursor_position`| `cursor` | *(none)* | Get current cursor coordinates: line (1-based) and column (0-based). |
| `set_cursor_position`| `cursor` | `line` *(req, number)*<br>`column` *(req, number)* | Move cursor to target line and column. |
| `goto_line` | `cursor` | `line` *(req, number)* | Jump cursor directly to a line number. |
| `search` | `cursor` | `pattern` *(req, string)*<br>`flags` *(opt, string: 'w', 'b')* | Search for pattern in buffer via Vim regex and return match line/col. |
| `get_windows` | `window` | *(none)* | List all open windows with IDs, buffer IDs, dimensions (`width`, `height`), and positions (`row`, `col`). |
| `split_window` | `window` | `direction` *(req, "horizontal" \| "vertical")* | Split current window horizontally (`:split`) or vertically (`:vsplit`). |
| `close_window` | `window` | `window_id` *(req, number)* | Close a specific window by ID. |
| `resize_window` | `window` | `window_id` *(req, number)*<br>`width` *(opt, number)*<br>`height` *(opt, number)* | **Explicit window resizing**: Set width and/or height in character columns/rows. |
| `exec_command` | `command` | `command` *(req, string)* | Execute arbitrary Vim Ex command (`:set ...`, `:w`). |
| `exec_lua` | `command` | `lua_code` *(req, string)* | Execute arbitrary Lua code inside Neovim. |
| `call_function` | `command` | `function_name` *(req, string)*<br>`args` *(req, array of any)* | **Direct function calling**: Invoke any Vimscript/Neovim API function with typed arguments. |

#### Resources (1)
| URI | MIME Type | Description |
| :--- | :--- | :--- |
| `nvim://buffers` | `application/json` | Provides a live JSON document containing the list of open buffers and their properties. |

---

## 4. Master Consolidated List of All Tools Across All Alternatives

The following master table aggregates every discrete MCP tool across all four alternative servers (over 70 tools total). It serves as the definitive reference catalog for curating `neovim-boss`.

### Legend
- **Nature**:
  - `[R]` = Read-Only (safe, zero mutation)
  - `[M]` = Mutating (modifies buffer or file)
  - `[V]` = Non-Destructive Visual (extmarks / visual selection, zero disk/text mutation)
  - `[X]` = Execution / System (runs commands, scripts, or controls OS)
- **Engine**:
  - `C-API` = Native Neovim C RPC API (`nvim_*`)
  - `Lua` = Chunk evaluated via `nvim_exec_lua`
  - `VimEx` = Vim Ex command executed via `nvim_command`
  - `VimFn` = Vimscript function called via `nvim_call_function`
  - `Input` = Keystrokes sent via `nvim_input`
  - `LSP` = Neovim built-in LSP client APIs (`vim.lsp.*`)

| # | Tool Name | Broad Domain | Source Server(s) | Nature | Engine | Description & Parameters Summary |
| :-: | :--- | :--- | :--- | :-: | :-: | :--- |
| **1** | `get_state_brief` | Awareness | `paulburgess` | `[R]` | `Lua` | Fast turn-start snapshot: active mode, cwd, listed buffers, active window with numbered context lines around cursor, alternate window, open terminals. |
| **2** | `get_state` | Awareness | `paulburgess` | `[R]` | `Lua` | Deep session snapshot: all windows, visual selection bounds, closed fold ranges, diagnostic count summary, marks `a-z`, active MCP extmarks, indent settings. |
| **3** | `vim_status` | Awareness | `bigcodegen` | `[R]` | `Lua`/`VimFn` | Editor status: cursor, mode, marks, registers, visual selection, layout, current tab, active LSP clients, loaded plugins. |
| **4** | `cursor_position` | Awareness | `linw1995` | `[R]` | `C-API` | Get current buffer and 0-indexed cursor position. |
| **5** | `get_cursor_position` | Awareness | `cousine` | `[R]` | `C-API` | Get current cursor coordinates: line (1-based) and column (0-based). |
| **6** | `read_full_buf` | Buffer Read | `paulburgess` | `[R]` | `Lua` | Read full buffer contents formatted with 1-based line numbers. `buffer: id \| name`. |
| **7** | `read_buf_range` | Buffer Read | `paulburgess` | `[R]` | `Lua` | Read line range `[start, end]` formatted with line numbers. `buffer`, `start_line`, `end_line`. |
| **8** | `get_buffer_lines` | Buffer Read | `cousine` | `[R]` | `C-API` | Read 1-based line slice `[start_line, end_line]`. `buffer_title`, `start_line`, `end_line`. |
| **9** | `read` | Buffer Read | `linw1995` | `[R]` | `C-API` | Read lines by Universal Document Identifier (buffer ID, relative path, or absolute path). |
| **10**| `vim_buffer` | Buffer Read | `bigcodegen` | `[R]` | `C-API` | Get buffer contents with line numbers. `filename` (optional). |
| **11**| `get_buffers` | Buffer Read | `cousine` | `[R]` | `C-API` | List all open buffers with metadata (title, loaded, modified, line count). |
| **12**| `list_buffers` | Buffer Read | `linw1995` | `[R]` | `C-API` | List open buffers with IDs, names, and line counts. |
| **13**| `get_current_buffer` | Buffer Read | `cousine` | `[R]` | `C-API` | Retrieve properties and details for the currently active buffer. |
| **14**| `find_and_replace_buf` | Buffer Edit | `paulburgess` | `[M]` | `Lua` | **Safe in-memory exact match find and replace**. Fails if string is absent or non-unique. Preserves undo tree (`u`). Never touches disk. |
| **15**| `set_buffer_lines` | Buffer Edit | `cousine` | `[M]` | `C-API` | Replace a 1-based line slice with new lines. `buffer_title`, `start_line`, `end_line`, `lines`. |
| **16**| `vim_edit` | Buffer Edit | `bigcodegen` | `[M]` | `C-API` | Edit lines with mode: `"insert"`, `"replace"`, or `"replaceAll"`. `startLine`, `mode`, `lines`. |
| **17**| `insert_text` | Buffer Edit | `cousine` | `[M]` | `C-API` | Insert text string at current cursor position. `text`. |
| **18**| `delete_lines` | Buffer Edit | `cousine` | `[M]` | `C-API` | Delete a 1-based line range from a buffer. `buffer_title`, `start_line`, `end_line`. |
| **19**| `write_full_buf` | Buffer Edit | `paulburgess` | `[M]` | `Lua` | Replace entire buffer contents in-memory with full undo support. |
| **20**| `vim_search_replace` | Buffer Edit | `bigcodegen` | `[M]` | `VimEx` | Find and replace via Vim regex substitution (`%s/...`). `pattern`, `replacement`, `global`, `ignoreCase`, `confirm`. |
| **21**| `open_buffer` | Buffer Mgmt | `cousine` | `[M]` | `VimEx` | Open a file into a buffer (`:edit <path>`). |
| **22**| `vim_file_open` | Buffer Mgmt | `bigcodegen` | `[M]` | `VimEx` | Open a file into a new buffer. `filename`. |
| **23**| `close_buffer` | Buffer Mgmt | `cousine` | `[M]` | `VimEx` | Close buffer by title/path. `buffer_title`, `force`. |
| **24**| `switch_buffer` | Buffer Mgmt | `cousine` | `[R]` | `VimEx` | Switch active window focus to a buffer. `buffer_title`. |
| **25**| `vim_buffer_switch` | Buffer Mgmt | `bigcodegen` | `[R]` | `VimEx` | Switch active buffer. `identifier` (ID or filename). |
| **26**| `vim_buffer_save` | Buffer Mgmt | `bigcodegen` | `[M]` | `VimEx` | Save current buffer or save out to a new file path. `filename` (optional). |
| **27**| `set_cursor_position`| Navigation | `cousine` | `[R]` | `C-API` | Move cursor to target `line` and `column`. |
| **28**| `goto_line` | Navigation | `cousine` | `[R]` | `C-API` | Jump cursor directly to line number. `line`. |
| **29**| `navigate` | Navigation | `linw1995` | `[R]` | `VimEx` | Open file and jump directly to target line and column. `path`, `line`, `column`. |
| **30**| `get_windows` | Window | `cousine` | `[R]` | `C-API` | List all open windows with IDs, buffer IDs, dimensions (`width`, `height`), and positions (`row`, `col`). |
| **31**| `split_window` | Window | `cousine` | `[R]` | `VimEx` | Split window (`direction`: `"horizontal"` \| `"vertical"`). |
| **32**| `vim_window` | Window | `bigcodegen` | `[R]` | `VimEx` | Split, close, only, or move directional focus (`wincmd h/j/k/l`). |
| **33**| `close_window` | Window | `cousine` | `[R]` | `C-API` | Close a specific window by ID. `window_id`. |
| **34**| `resize_window` | Window | `cousine` | `[R]` | `C-API` | **Explicit window resizing**: Set width and/or height in characters. `window_id`, `width`, `height`. |
| **35**| `vim_tab` | Tabs | `bigcodegen` | `[R]` | `VimEx` | Tabpage management: `"new"`, `"close"`, `"next"`, `"prev"`, `"first"`, `"last"`, `"list"`. |
| **36**| `vim_jump` | Navigation | `bigcodegen` | `[R]` | `Input`/`VimFn` | Jump list navigation (`"back"`, `"forward"`, `"list"`). |
| **37**| `highlight_range` | Visual Extmark| `paulburgess` | `[V]` | `Lua` | Annotate a line range with colored background highlight (theme-aware group). |
| **38**| `highlight_ranges` | Visual Extmark| `paulburgess` | `[V]` | `Lua` | Annotate multiple line ranges with colored highlights in one call. |
| **39**| `clear_highlights` | Visual Extmark| `paulburgess` | `[V]` | `Lua` | Clear all MCP-applied highlights in a buffer. |
| **40**| `add_virtual_text` | Visual Extmark| `paulburgess` | `[V]` | `Lua` | Attach visual text note to a line (`"eol"`, `"above"`, `"below"`) without modifying buffer. |
| **41**| `add_virtual_texts`| Visual Extmark| `paulburgess` | `[V]` | `Lua` | Attach multiple virtual text notes at once. |
| **42**| `clear_virtual_texts`| Visual Extmark| `paulburgess` | `[V]` | `Lua` | Clear all MCP-applied virtual text notes in a buffer. |
| **43**| `vim_visual` | Visual Mode | `bigcodegen` | `[V]` | `Lua`/`Input`| Programmatically trigger visual selection between coordinates. |
| **44**| `vim_register` | Vim Primitive | `bigcodegen` | `[M]` | `VimFn` | Set content of a specified Vim register (`a-z`, `"`, `0-9`). |
| **45**| `vim_mark` | Vim Primitive | `bigcodegen` | `[M]` | `VimFn` | Set named mark `a-z` at line and column. |
| **46**| `vim_macro` | Vim Primitive | `bigcodegen` | `[X]` | `Input`/`VimFn` | Record, stop recording, or play back a macro register. `action`, `register`, `count`. |
| **47**| `vim_fold` | Vim Primitive | `bigcodegen` | `[R]` | `VimEx` | Folding operations: `"create"`, `"open"`, `"close"`, `"toggle"`, `"openall"`, `"closeall"`, `"delete"`. |
| **48**| `search` | Search | `cousine` | `[R]` | `VimFn` | Search for pattern in buffer using Vim regex; returns array of match lines/cols. |
| **49**| `vim_search` | Search | `bigcodegen` | `[R]` | `VimFn` | Search buffer with regex and return match count via `searchcount()`. |
| **50**| `vim_grep` | Search | `bigcodegen` | `[R]` | `VimEx` | Project-wide `:vimgrep` populated into the Neovim quickfix list. |
| **51**| `send_to_terminal` | Terminal | `paulburgess` | `[X]` | `C-API`/`Lua`| Write directly to terminal buffer job channel (`nvim_chan_send`) without stealing focus. `submit: bool`. |
| **52**| `get_all_diagnostics`| Diagnostics | `paulburgess` | `[R]` | `Lua` | Retrieve all LSP diagnostics across all open buffers (errors, warnings, hints). |
| **53**| `get_buf_diagnostics`| Diagnostics | `paulburgess` | `[R]` | `Lua` | Retrieve LSP diagnostics for a single buffer. |
| **54**| `buffer_diagnostics` | Diagnostics | `linw1995` | `[R]` | `LSP` | Fetch LSP diagnostics for a specific buffer identifier. |
| **55**| `lsp_clients` | LSP | `linw1995` | `[R]` | `LSP` | List active LSP clients attached to the workspace. |
| **56**| `wait_for_lsp_ready` | LSP | `linw1995` | `[R]` | `LSP` | Block until LSP clients finish initializing and indexing. |
| **57**| `lsp_definition` | LSP | `linw1995` | `[R]` | `LSP` | Jump to definition of symbol at cursor. |
| **58**| `lsp_declaration` | LSP | `linw1995` | `[R]` | `LSP` | Jump to declaration of symbol at cursor. |
| **59**| `lsp_type_definition`| LSP | `linw1995` | `[R]` | `LSP` | Jump to type definition of symbol at cursor. |
| **60**| `lsp_implementations`| LSP | `linw1995` | `[R]` | `LSP` | Find all implementations of symbol at cursor. |
| **61**| `lsp_references` | LSP | `linw1995` | `[R]` | `LSP` | Find all symbol references across the project. |
| **62**| `lsp_hover` | LSP | `linw1995` | `[R]` | `LSP` | Get hover type signatures and documentation markdown. |
| **63**| `lsp_document_symbols`| LSP | `linw1995` | `[R]` | `LSP` | Fetch document symbol tree / outline. |
| **64**| `lsp_workspace_symbols`| LSP | `linw1995` | `[R]` | `LSP` | Search workspace symbol table across all indexed files. |
| **65**| `lsp_code_actions` | LSP | `linw1995` | `[R]` | `LSP` | Query available code actions / quickfixes for a range. |
| **66**| `lsp_resolve_code_action`| LSP | `linw1995` | `[R]` | `LSP` | Resolve detailed changes for a code action. |
| **67**| `lsp_apply_edit` | LSP | `linw1995` | `[M]` | `LSP` | Apply a workspace edit returned from an LSP action. |
| **68**| `lsp_rename` | LSP | `linw1995` | `[M]` | `LSP` | Perform semantic symbol rename across the workspace. |
| **69**| `lsp_formatting` | LSP | `linw1995` | `[M]` | `LSP` | Format entire document via attached LSP. |
| **70**| `lsp_range_formatting`| LSP | `linw1995` | `[M]` | `LSP` | Format specific range via attached LSP. |
| **71**| `lsp_organize_imports`| LSP | `linw1995` | `[M]` | `LSP` | Organize imports code action via LSP. |
| **72**| `lsp_call_hierarchy_prepare`| LSP | `linw1995` | `[R]` | `LSP` | Prepare call hierarchy item at cursor position. |
| **73**| `lsp_call_hierarchy_incoming_calls`| LSP | `linw1995` | `[R]` | `LSP` | Get callers of function item. |
| **74**| `lsp_call_hierarchy_outgoing_calls`| LSP | `linw1995` | `[R]` | `LSP` | Get outgoing calls from function item. |
| **75**| `lsp_type_hierarchy_prepare`| LSP | `linw1995` | `[R]` | `LSP` | Prepare type hierarchy item at cursor position. |
| **76**| `lsp_type_hierarchy_supertypes`| LSP | `linw1995` | `[R]` | `LSP` | Query supertypes / interfaces of type item. |
| **77**| `lsp_type_hierarchy_subtypes`| LSP | `linw1995` | `[R]` | `LSP` | Query subtypes / implementations of type item. |
| **78**| `exec_lua` | Scripting | `linw1995`, `cousine` | `[X]` | `C-API` | Execute arbitrary Lua code inside Neovim. |
| **79**| `send_command` / `vim_command` / `exec_command` | Execution | `paulburgess`, `bigcodegen`, `cousine` | `[X]` | `C-API` | Execute arbitrary Vim Ex commands (`:w`, `:split`, `:set`). |
| **80**| `send_keys` | Execution | `paulburgess` | `[X]` | `Input` | Send raw keystrokes directly via `nvim_input` (prepends `<Esc>`). |
| **81**| `call_function` | Scripting | `cousine` | `[X]` | `C-API` | Call any internal Vimscript or Neovim function by name with structured arguments array. |
| **82**| `get_targets` | Connection | `linw1995` | `[R]` | System | Discover running Neovim instances (prioritizes local directory). |
| **83**| `connect` / `connect_tcp` | Connection | `linw1995`, `paulburgess` | `[X]` | System | Connect to a Neovim instance (socket, named pipe, or TCP). |
| **84**| `disconnect` | Connection | `linw1995` | `[X]` | System | Disconnect from a specific session. |
| **85**| `vim_health` | System | `bigcodegen` | `[R]` | System | Check Neovim socket connection health. |

---

## 5. Master Consolidated List of Resources & Prompts

### 5.1 MCP Resources
| Resource URI | Source Server(s) | MIME Type | Payload Structure & Description |
| :--- | :--- | :--- | :--- |
| `neovim://buffers` | `neovim-boss`, `cousine`, `bigcodegen` | `application/json` | Array of open buffers with rich metadata: buffer handle (`id`/`bufnr`), path/name, `listed`, `loaded`, `modified`, `hidden`, line count, cursor line, window handles, filetype, buftype, last access timestamp. |
| `nvim://session` | `bigcodegen` | `text/plain` | Plain text of the active buffer formatted with 1-based line numbers. |
| `nvim-connections://` | `linw1995` | `application/json` | List of all discovered and actively connected Neovim sessions with connection IDs, PIDs, and socket paths. |
| `nvim-tools://` | `linw1995` | `application/json` | Dynamic registry of tools exposed across sessions. |
| `nvim-tools://{conn_id}` | `linw1995` | `application/json` | Session-specific tools and custom Lua tools. |
| `nvim-diagnostics://{conn_id}/workspace` | `linw1995` | `application/json` | Complete workspace-wide LSP diagnostic report. |
| `nvim-diagnostics://{conn_id}/buffer/{buf_id}` | `linw1995` | `application/json` | Buffer-specific LSP diagnostic report. |

### 5.2 MCP Prompts & Agent Rules
| Prompt / Rule File | Source Server | Mechanism | Description |
| :--- | :--- | :--- | :--- |
| `neovim_workflow` | `bigcodegen` | Native MCP Prompt | Parameterized prompt taking `task: "editing" \| "navigation" \| "search" \| "buffers" \| "windows" \| "macros"`. Returns structured guidance on which tools to call in sequence. |
| `AGENTS.md` / `.mdc` / `CLAUDE.md` | `paulburgess` | Static Rules File (~1,176 tokens) | Teaches the agent **when and how** to use tools: e.g. call `get_state_brief` at start of every turn; use `find_and_replace_buf` instead of rewriting files; use virtual text for comments instead of inserting temporary code; leave terminal input at prompt unless instructed to submit. |

---

## 6. Curation Blueprint for `neovim-boss` (`nb`)

Based on the capabilities inventory, the user's focus notes in `server.org`, and `neovim-boss`'s architectural strengths (compiled native Zig binary, <1ms startup, zero external runtimes, 260+ auto-generated typed API bindings in `src/api.zig`), here is the strategic curation recommendation:

```
+----------------------------------------------------------------------------------------------------+
|                                    CURATION ROADMAP TIERS                                          |
+----------------------------------------------------------------------------------------------------+
| Tier 1: Foundational Essentials        │ Awareness, Safe Substring Edits, Lines, Window Splits     |
| Tier 2: Interactive Pair-Programming   │ Extmark Highlights, Virtual Text, Terminal Job Channels   |
| Tier 3: Vim Native Power               │ Marks, Registers, Grep/Search, Window Resizing, Prompts    |
| Tier 4: Code Intelligence & LSP        │ Diagnostics & LSP Navigation via nvim_exec_lua            |
+----------------------------------------------------------------------------------------------------+
```

### Tier 1: Foundational Essentials (Implement First)
*Goal: Provide complete, rock-solid core editing and situational awareness.*

1. **Situational Awareness**:
   - `get_state_brief`: Answering *"what am I looking at? what have I selected?"* Returns active mode (`n`, `i`, `v`), cwd, listed buffers, active window file/cursor coordinates, and 5 context lines around cursor.
2. **Safe In-Memory Buffer Editing**:
   - `find_and_replace_buf`: Exact-match substring replacement. Fails if string is missing or ambiguous (not unique). Preserves Neovim undo tree (`u`). Zero file writes until saved.
   - `get_buffer_lines`: Read line slice `[start_line, end_line]`.
   - `set_buffer_lines`: Replace line slice `[start_line, end_line]`.
3. **Cursor & Window Layout**:
   - `get_cursor` & `set_cursor`: Query and move cursor coordinates.
   - `split_window` & `close_window`: Horizontal and vertical splitting.
4. **Execution & Scripting**:
   - `eval_lua`: Execute Lua expressions (complements `eval_vimscript`).
   - `send_command`: Run Ex commands (`:w`, `:edit`).
   - `send_keys`: Deliver keystrokes via `nvim_input` (fast path).
5. **Resources**:
   - `neovim://buffers` (*already implemented!*).
   - `neovim://current_buffer`: Text of the active buffer with line numbers (matches `nvim://session`).

### Tier 2: Interactive Pair-Programming & Visual Superpowers
*Goal: Make the agent a true live collaborator that communicates visually and controls terminal jobs.*

1. **Visual Extmark Annotations**:
   - `highlight_range` / `clear_highlights`: Non-destructive colored line highlights using theme-aware groups (`DiffAdd`, `Visual`).
   - `add_virtual_text` / `clear_virtual_texts`: Inline or above/below virtual text notes.
2. **Terminal Job Integration**:
   - `send_to_terminal`: Write input directly to a terminal buffer's job channel without stealing focus. Support `submit: false` (leave at prompt) and `submit: true` (execute).
3. **Diagnostics Summary**:
   - `get_diagnostics`: Fetch active LSP diagnostics via `vim.diagnostic.get()` in a single round-trip.

### Tier 3: Vim Mastery & Automation
*Goal: Leverage Neovim's distinctive primitives.*

1. **Vim Primitives**:
   - `get_mark` / `set_mark`: Named marks `a-z`.
   - `get_register` / `set_register`: Registers `a-z`, `"`, `0-9`.
   - `resize_window`: Programmatic character width/height resizing.
   - `search_buffer` & `grep_project`: Regex buffer search and `:vimgrep` quickfix integration.
2. **MCP Prompt**:
   - `nb_pair_programming` / `neovim_workflow`: System prompt teaching the agent optimal tool usage patterns.

### Tier 4: Code Intelligence & LSP Proxies
*Goal: Bridge Neovim's LSP capabilities without requiring companion plugins.*

1. **LSP Operations via `nvim_exec_lua`**:
   - `lsp_hover`, `lsp_definition`, `lsp_references`, `lsp_code_actions`.
   - Directly invoke Neovim's built-in `vim.lsp.buf_request_sync` over RPC rather than installing a plugin.

### What NOT to Include in `neovim-boss`
- ❌ **Requiring a Companion Neovim Plugin**: Preserving `nb`'s zero-plugin setup is a major competitive advantage over `linw1995`.
- ❌ **Complex Multi-Connection Routing (`connection_id` tokens)**: Requiring the agent to specify `connection_id` on every tool call adds friction. Auto-detecting the socket (via `$NVIM` or cwd affinity) is much cleaner.
- ❌ **Macro Recording/Playback**: Recording and replaying macros via LLMs is brittle and adds little value compared to direct text editing.
- ❌ **Shell Execution via `!cmd`**: Running arbitrary shell commands via Vim Ex mode introduces security risks; terminal job channels (`send_to_terminal`) are cleaner, safer, and visible to the user.
