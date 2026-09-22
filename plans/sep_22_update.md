# Project Status & Roadmap Update (September 22, 2026)

## 1. Executive Summary

This document synthesizes the state of **`neovim-boss` (`nb`)** as of September 22, 2026, based on a comprehensive review of all design documents in [`plans/`](file:///Users/justinhj/projects/neovim-boss/plans), the [`README.md`](file:///Users/justinhj/projects/neovim-boss/README.md), and recent git development milestones.

`neovim-boss` has evolved from a typed Zig Neovim MessagePack-RPC client library into a production-ready, native **Model Context Protocol (MCP) server** and pair-programming coprocess. It compiles to a single standalone binary with zero external runtimes (<1ms startup) and provides AI assistants (such as Claude Code, Cursor, Antigravity, and OpenCode) with high-speed situational awareness, safe in-memory buffer editing with full undo preservation, and lean execution primitives.

---

## 2. Completed Milestones & Current Capabilities

### A. Core Zig Neovim Client Library (`src/`)
- **Multi-Transport Engine ([`src/transport.zig`](file:///Users/justinhj/projects/neovim-boss/src/transport.zig))**:
  - Unix domain sockets (`nvim --listen /path/to/socket`).
  - TCP network sockets (`nvim --listen host:port`).
  - Headless child process supervision (`nvim --embed --headless`).
  - Standard I/O (`stdio`) coprocess mode.
- **Smart Connection Auto-Detection ([`src/root.zig`](file:///Users/justinhj/projects/neovim-boss/src/root.zig))**:
  - `neovim_boss.attachAddress(allocator, io, target)` automatically parses connection addresses and auto-discovers active `$NVIM` sockets when run inside Neovim `:terminal` buffers.
- **Strongly-Typed API Code Generation ([`src/api.zig`](file:///Users/justinhj/projects/neovim-boss/src/api.zig))**:
  - 260+ typesafe API functions generated from bundled [`data/api_info.msgpack`](file:///Users/justinhj/projects/neovim-boss/data/api_info.msgpack) via [`tools/codegen.zig`](file:///Users/justinhj/projects/neovim-boss/tools/codegen.zig).
  - Attached methods on extension handle wrappers: [`Buffer`](file:///Users/justinhj/projects/neovim-boss/src/nvim_types.zig#L10), [`Window`](file:///Users/justinhj/projects/neovim-boss/src/nvim_types.zig#L44), and [`Tabpage`](file:///Users/justinhj/projects/neovim-boss/src/nvim_types.zig#L78).
- **Bidirectional MessagePack-RPC Session ([`src/client.zig`](file:///Users/justinhj/projects/neovim-boss/src/client.zig))**:
  - Blocking synchronous RPC with re-entrant reverse RPC handling (`rpcrequest`).
  - Continuous event processing loop (`nvim.runLoop()`) and subscription handling (`buf.attach()`, `nvim.subscribe()`).
- **Zero-Heap Extension Handles ([`src/nvim_types.zig`](file:///Users/justinhj/projects/neovim-boss/src/nvim_types.zig))**:
  - MessagePack extension handle encoding/decoding using stack buffers.

### B. MCP Server (`nb mcp`) ([`src/mcp/`](file:///Users/justinhj/projects/neovim-boss/src/mcp/))
- **Stdio JSON-RPC 2.0 Server ([`src/mcp/server.zig`](file:///Users/justinhj/projects/neovim-boss/src/mcp/server.zig))**:
  - Full conformance with the MCP protocol specification over standard I/O with per-request arena cleanup.
- **Situational Awareness & Telemetry (Domain 1)**:
  - `get_state_brief`: Fast, token-efficient orientation snapshot: mode, cwd, active window with numbered context lines around the cursor, alternate window, open terminals, and listed/modified buffers.
  - `get_state`: Deep session snapshot: all visible windows, cursor context, marks `a-z`, closed folds, visual selection bounds, indent settings, and LSP diagnostic counts.
- **Safe In-Memory Buffer Editing (Domain 3)**:
  - `find_and_replace_buf`: Exact-match substring find-and-replace. Fails safely if the match is missing or non-unique (preventing accidental corruption). Never writes to disk prematurely.
  - `write_full_buf`: In-memory full buffer replacement.
  - **Undo Tree Preservation**: Buffer mutations preserve Neovim's native undo history across active and background buffers using window-targeted edits and `undojoin`, allowing immediate reversibility via `send_keys("u")`.
- **Buffer Reading & Document Inspection (Domain 2)**:
  - `read_full_buf`: Read full buffer formatted with 1-based line numbers.
  - `read_buf_range`: Read line slices with automatic boundary swapping and clamping.
- **Scripting & Command Execution (Domain 9)**:
  - `exec_lua`: Executes arbitrary Lua blocks in Neovim's runtime and returns JSON-serialized output (alias: `eval_lua`).
  - `send_command`: Executes Vim Ex commands (`:w`, `:split`, `:edit`, `:set`) and captures formatted output.
  - `send_keys`: Keystroke injection via `nvim_input` with automated key notation translation (`<Esc>`, `<CR>`, `<Tab>`, `<C-w>v`) and normal-mode auto-escaping.
- **MCP Telemetry Resources**:
  - `neovim://buffers`: Live JSON array of all open buffers with comprehensive status flags (`buflisted`, `bufloaded`, `bufmodified`, `hidden`, `line_count`, `cursor_line`, `windows`, `filetype`, `buftype`).

### C. Embedded Lua Architecture ([`src/lua/`](file:///Users/justinhj/projects/neovim-boss/src/lua/))
- Modular Lua scripts extracted from inline strings to dedicated files:
  - `get_state.lua`: Unified telemetry collector.
  - `find_and_replace_buf.lua`: Exact-match substring replacement with undo joins.
  - `write_full_buf.lua`: In-memory buffer rewriting.
  - `read_full_buf.lua` & `read_buf_range.lua`: Line formatting and boundary clamping.
  - `helpers.lua`: Buffer resolution and window-targeting helpers.
- Compiled directly into the native Zig binary at build time using `@embedFile`, ensuring clean separation, maintainability, and zero runtime disk reads.

### D. Agent Skills & Integration Testing
- **Agent Skill Definition**: [`skills/neovim-boss/SKILL.md`](file:///Users/justinhj/projects/neovim-boss/skills/neovim-boss/SKILL.md) (and `.agents/skills/neovim-boss/SKILL.md`) guiding AI agents on the orientation loop, safe editing patterns, and Ex command navigation.
- **Autonomous Integration Test Prompts**: [`agent_tests/edit_tools.md`](file:///Users/justinhj/projects/neovim-boss/agent_tests/edit_tools.md) and [`agent_tests/TEST_PROMPT.md`](file:///Users/justinhj/projects/neovim-boss/agent_tests/TEST_PROMPT.md) providing self-contained test scenarios for autonomous LLM evaluation.

---

## 3. Deliberate Design Decisions: What Was Cancelled or Pruned

Following the comprehensive 4-server comparative review in [`plans/nvim-mcp-review.md`](file:///Users/justinhj/projects/neovim-boss/plans/nvim-mcp-review.md), master capability inventory in [`plans/tools_sep.md`](file:///Users/justinhj/projects/neovim-boss/plans/tools_sep.md), and test prompt analysis in [`plans/test_prompt_ideas.md`](file:///Users/justinhj/projects/neovim-boss/plans/test_prompt_ideas.md), several proposed features were deliberately cancelled, pruned, or decided against:

| Direction / Feature | Status | Rationale |
| :--- | :---: | :--- |
| **Companion Neovim Lua Plugin** | **❌ CANCELLED** | Unlike `linw1995/nvim-mcp`, `neovim-boss` strictly operates over native RPC sockets out of the box with zero user installation required. |
| **Redundant Granular Tools** (`open_buffer`, `switch_buffer`, `split_window`, `close_window`, `vim_tab`, `vim_fold`, `vim_mark`, `eval_vimscript`, `call_function`) | **✂️ PRUNED** | Neovim's native Ex commands (`send_command` with `:e`, `:b`, `:split`, `:tabnew`) and keystrokes (`send_keys` with `u`, `ggVG`) already handle over 70% of editor actions. Pruning redundant tools keeps the MCP tool schema lean and prevents agent confusion. `eval_vimscript` and `call_function` were pruned in commit `e1f82bf` in favor of `exec_lua` and `send_command`. |
| **Arbitrary Shell Execution (`:!cmd`)** | **❌ REJECTED** | Running arbitrary shell commands via Ex mode presents major security risks; non-stealing terminal job channels are cleaner, visible to the user, and safe. |
| **Macro Recording / Playback (`vim_macro`)** | **❌ REJECTED** | Macro recording and replay via LLMs is brittle and error-prone compared to direct text manipulation. |
| **Session Connection Tokens (`connection_id`)** | **❌ REJECTED** | Requiring the LLM to pass stateful connection hash tokens on every tool call adds significant friction. Single-instance targeting with automatic `$NVIM` detection is cleaner. |

---

## 4. What Needs Doing: Phased Roadmap

```mermaid
flowchart LR
    Completed["Phases 1 & 2<br/>[COMPLETED]<br/>Core RPC, State & Safe Edits"] --> P3["Phase 3<br/>Visual Feedback & Terminals<br/>(Extmarks & Job Channels)"]
    P3 --> P4["Phase 4<br/>Ambient Context & Primitives<br/>(Resources, Registers, Prompts)"]
    P4 --> P5["Phase 5<br/>Code Intelligence & LSP<br/>(LSP Proxies & HTTP/SSE)"]
```

### Phase 3: Visual Annotations & Terminal Channels
- **Extmarks & Highlights (Domain 5)**:
  - `highlight_range` / `highlight_ranges`: Apply theme-aware line highlights (`DiffAdd`, `Visual`, `DiagnosticUnderlineError`) for visual agent communication without altering files on disk.
  - `clear_highlights`: Remove MCP-created highlights from a buffer.
- **Virtual Text Notes (Domain 5)**:
  - `add_virtual_text` / `add_virtual_texts`: Attach inline, above, or below virtual text annotations without altering file contents.
  - `clear_virtual_texts`: Clear MCP-created virtual text notes.
- **Non-Stealing Terminal Control (Domain 7)**:
  - `send_to_terminal`: Send input directly to a terminal job channel via `nvim_chan_send` without stealing focus from the active window. Supports `submit: false` (leave staged at prompt for user review) and `submit: true` (execute).

### Phase 4: Ambient Context Resources & Vim Primitives
- **Ambient State Resources**:
  - Implement `neovim://state` and `neovim://state/brief` (the "symbiotic" model from `test_prompt_ideas.md`) allowing MCP clients to subscribe to live editor updates.
  - Implement `neovim://current_buffer` providing active buffer text with line numbers.
- **Traditional Vim Primitives (Domain 6)**:
  - `get_register` / `set_register`: Manipulate Vim registers (`"`, `a-z`, `0-9`).
  - `search_buffer`: Regex pattern search with occurrence count via `searchcount()`.
  - `resize_window`: Programmatic window character width/height resizing.
- **Native MCP Prompts**:
  - Expose `neovim_workflow` / `nb_pair_programming` prompts teaching agents optimal tool selection and interaction patterns.

### Phase 5: Code Intelligence & LSP Proxies
- **Zero-Plugin LSP Client Proxy (Domain 8)**:
  - Proxy Neovim's built-in LSP client via `nvim_exec_lua` calling `vim.lsp.buf_request_sync`:
    - `get_diagnostics` (or `get_all_diagnostics`, `get_buf_diagnostics`): Fetch LSP compiler/linter errors and warnings.
    - `lsp_definition`, `lsp_references`, `lsp_hover`, `lsp_document_symbols`.
- **HTTP / SSE Transport**:
  - Expose an optional `--http-port` alongside stdio for remote containers, headless pairing, and web-based AI clients.
- **Thin REST / HTTP API Mode**:
  - Curl-accessible REST endpoints over the core client library (`plans/feature-set.md`).

---

## 5. Architectural Reference & File Inventory

| Path | Description | Status |
| :--- | :--- | :---: |
| [`src/root.zig`](file:///Users/justinhj/projects/neovim-boss/src/root.zig) | Library root, re-exports, convenience methods, integration test suite | Complete |
| [`src/transport.zig`](file:///Users/justinhj/projects/neovim-boss/src/transport.zig) | Layer 1: POSIX fd, Unix socket, TCP, child process, stdio | Complete |
| [`src/client.zig`](file:///Users/justinhj/projects/neovim-boss/src/client.zig) | Layer 3: RPC Session, request tracking, reverse RPC dispatch | Complete |
| [`src/nvim.zig`](file:///Users/justinhj/projects/neovim-boss/src/nvim.zig) | Layer 4: Nvim struct, init handshake, composite queries | Complete |
| [`src/nvim_types.zig`](file:///Users/justinhj/projects/neovim-boss/src/nvim_types.zig) | Layer 4: Buffer, Window, Tabpage ext handles and telemetry structs | Complete |
| [`src/api.zig`](file:///Users/justinhj/projects/neovim-boss/src/api.zig) | Layer 5: 260+ strongly-typed generated Neovim API wrappers | Complete |
| [`src/mcp/`](file:///Users/justinhj/projects/neovim-boss/src/mcp/) | Layer 6: JSON-RPC stdio server, tool dispatch, resource registry | Complete |
| [`src/lua/`](file:///Users/justinhj/projects/neovim-boss/src/lua/) | Compile-time embedded Lua scripts for state & safe edits | Complete |
| [`skills/neovim-boss/SKILL.md`](file:///Users/justinhj/projects/neovim-boss/skills/neovim-boss/SKILL.md) | Official LLM agent skill guide and best practices | Complete |
| [`agent_tests/edit_tools.md`](file:///Users/justinhj/projects/neovim-boss/agent_tests/edit_tools.md) | Autonomous agent verification test scenarios | Complete |
| [`plans/nvim-mcp-review.md`](file:///Users/justinhj/projects/neovim-boss/plans/nvim-mcp-review.md) | 4-way comparative evaluation of existing Neovim MCP servers | Reference |
| [`plans/tools_sep.md`](file:///Users/justinhj/projects/neovim-boss/plans/tools_sep.md) | Master inventory of 85+ MCP tools across 10 functional domains | Reference |
| [`plans/test_prompt_ideas.md`](file:///Users/justinhj/projects/neovim-boss/plans/test_prompt_ideas.md) | Operational insights from agent test prompts & tool vs resource analysis | Reference |
