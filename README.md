# neovim-boss (`nb`)

<img width="913" height="763" alt="Neovim's mascot - a monster robot" src="https://github.com/user-attachments/assets/9796a114-6394-419d-a4f7-c7d1c10e4a03" />

```  
  __      __
 <  \____/  >
  | [x][x] |
  \   <>   /
    |    |
  //| .. |\\
 (  |____|  )
    d'  'b
```

Neovim-boss's mascot En-Bee.

A high-performance, robust, and strongly-typed **Neovim API client library, MCP server and CLI** for [Zig](https://ziglang.org) (v0.16.0+), built on [`justinhj/zig-msgpack`](https://github.com/justinhj/zig-msgpack).

`neovim-boss` provides complete programmatic control over running or embedded Neovim instances via MessagePack-RPC. It is designed both as a standalone library for Zig applications and as a native **Neovim Model Context Protocol (MCP) server**, allowing AI agents and LLM tools (such as Claude Desktop, Claude Code, Cursor, and OpenCode) to introspect, query, and interact with your editor in real time.

---

## Features

- **Built-in Model Context Protocol (MCP) Server**:
  - Standards-compliant JSON-RPC 2.0 stdio server implementing the MCP specification.
  - Exposes state awareness, safe in-memory editing, and execution tools (`get_state_brief`, `get_state`, `read_full_buf`, `read_buf_range`, `find_and_replace_buf`, `write_full_buf`, `exec_lua`, `send_command`, `send_keys`) and real-time buffer telemetry resources (`neovim://buffers`).
  - Safe in-memory buffer edits with complete Neovim undo tree preservation (`u`) across active and background buffers.
  - Zero external runtimes: compiles to a fast, standalone native binary (`nb`) with instant startup (<1ms).
- **Fast Single-Round-Trip Buffer Telemetry (`listBufInfo`, `BufferInfo`)**:
  - Bulk query buffer lists enriched with filetype, buftype, flags (`buflisted`, `bufloaded`, `bufmodified`, `hidden`), associated window IDs, line counts, and cursor positions in a single RPC round-trip.
- **Multi-Transport Support**:
  - **Unix Domain Sockets**: Connect to running Neovim instances (`nvim --listen /tmp/nvim.sock`).
  - **TCP Sockets**: Connect across local or remote networks (`nvim --listen 127.0.0.1:6666`).
  - **Child Process Embedding**: Automatically spawn and supervise headless child instances (`nvim --embed --headless`).
  - **Standard I/O (`stdio`)**: Run directly as a coprocess or embedded plugin filter.
- **Smart Connection & Project Socket Auto-Detection**:
  - Automatically discovers running Neovim instances across `$TMPDIR`, `$XDG_RUNTIME_DIR`, `/tmp`, and project folders.
  - Matches Neovim's active working directory and Git repository root to the agent's project workspace with **zero Neovim plugins required**.
  - Dedicated `nb detect [dir]` CLI command to inspect, probe, and troubleshoot running Neovim sessions.
  - Also routes to child embedded Neovims (`child`), standard I/O (`stdio`), TCP (`host:port`), or Unix domain socket paths, and auto-detects active `$NVIM` sockets inside `:terminal`.
- **Strongly-Typed API Code Generation (260+ functions)**:
  - Generates typesafe wrappers for the entire Neovim API directly from Neovim's `api_info` schema.
  - Automatic parameter packing and return value decoding.
- **Ext Type Abstractions (`Buffer`, `Window`, `Tabpage`)**:
  - Zero-heap handle encoding and decoding.
  - Ergonomic object-oriented helper methods (`buf.getLines()`, `buf.setLines()`, `buf.lineCount()`, `win.getCursor()`, `win.setCursor()`, `tab.listWins()`).
- **Bidirectional RPC & Re-Entrant Requests**:
  - Handle reverse RPC requests initiated by Neovim (`rpcrequest(channel_id, ...)`).
  - Handles nested callbacks re-entrantly while waiting for synchronous request responses.
- **Event Loop & Notifications**:
  - Continuous event processing loop (`nvim.runLoop()`) with graceful stop (`nvim.stopLoop()`).
  - Subscriptions for broadcast events (`nvim.subscribe()`) and live buffer events (`buf.attach()`).
- **Arena-Centric Memory Architecture**:
  - Fast, leak-free per-request arena allocations; no manual tree traversal or per-object cleanup required.

---

## Model Context Protocol (MCP) Server

`neovim-boss` provides a native, high-performance [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server built directly into the `nb` binary. It enables AI coding assistants and LLM agents (Claude Desktop, Claude Code, Cursor, OpenCode, etc.) to inspect, query, and interact directly with a running Neovim session over standard I/O (`stdio`).

### Running the MCP Server (`nb mcp`)

`neovim-boss` features **zero-config socket auto-detection**: it automatically discovers running Neovim instances on your machine and connects to the one editing the same workspace or Git repository as your agent—no companion plugins or manual socket arguments required!

```bash
# Build the nb binary
zig build -Doptimize=ReleaseFast

# 1. Zero-config auto-detection (connects to the Neovim editing the current project folder):
./zig-out/bin/nb mcp
# Or explicitly:
./zig-out/bin/nb mcp detect

# 2. Inspect running Neovim instances from the CLI without starting MCP:
./zig-out/bin/nb detect
./zig-out/bin/nb detect /path/to/another/project

# 3. Connect to an explicit Unix domain socket path:
./zig-out/bin/nb mcp /tmp/nvim.sock

# 4. Connect via TCP network socket:
./zig-out/bin/nb mcp 127.0.0.1:6666

# 5. Automatically spawn and supervise a headless child Neovim instance:
./zig-out/bin/nb mcp child
```

> [!TIP]
> **How Auto-Detection Works**:
> When invoked without arguments (or with `detect`), `nb` first checks if `$NVIM` is set (e.g. inside an embedded Neovim `:terminal` session). If not, it probes active sockets in `$TMPDIR`, `$XDG_RUNTIME_DIR`, `/tmp`, and the local project directory. It performs a fast MessagePack-RPC handshake to query each instance's working directory (`getcwd()`), process ID (`getpid()`), and active file, then connects to the instance matching your current workspace or Git repository root.

### Inspecting Running Instances (`nb detect`)

You can run `nb detect` at any time to troubleshoot connections, check active buffers, and see which Neovim instance matches your directory:

```bash
$ nb detect
Detecting Neovim instances for:
  Directory: /Users/justinhj/projects/neovim-boss
  Git Root:  /Users/justinhj/projects/neovim-boss

✓ MATCH FOUND (exact match):
    Socket:       /private/tmp/poopy.sock
    PID:          73288
    CWD:          /Users/justinhj/projects/neovim-boss
    Server Name:  /tmp/poopy.sock

All active Neovim instances (4):
  1.     PID  47138 | CWD: /Users/justinhj/projects/bst-blog
        Socket: /private/var/folders/.../nvim.47138.0
        File:   /Users/justinhj/projects/bst-blog/src/root.zig
  2.     PID  28108 | CWD: /Users/justinhj/projects/leetcode
        Socket: /private/var/folders/.../nvim.28108.0
        File:   /Users/justinhj/projects/leetcode/main.py
  3. [*] PID  73288 | CWD: /Users/justinhj/projects/neovim-boss
        Socket: /private/tmp/poopy.sock
```

### Configuring with MCP Clients

Because `neovim-boss` automatically finds the Neovim session for your project, you **do not** need to hardcode a fixed socket path into your configuration. Simply configure `nb mcp`:

#### Claude Desktop
Add `neovim-boss` to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "neovim": {
      "command": "/path/to/neovim-boss/zig-out/bin/nb",
      "args": ["mcp"]
    }
  }
}
```

*(You can still specify an explicit socket like `["mcp", "/tmp/nvim.sock"]` if you wish to override auto-detection).*

#### Claude Code
Add to your project's `.mcp.json` or register via the CLI:

```bash
claude mcp add neovim -- /path/to/neovim-boss/zig-out/bin/nb mcp
```

#### Cursor / Antigravity / OpenCode
Add to your MCP settings:

```json
{
  "mcpServers": {
    "neovim-boss": {
      "command": "/path/to/neovim-boss/zig-out/bin/nb",
      "args": ["mcp"]
    }
  }
}
```

### Supported MCP Capabilities

- **Tools**:
  - `get_state_brief`: Returns a high-speed, token-efficient orientation snapshot of the editor: mode, cwd, active window with numbered cursor context lines, alternate window, open terminals, modified buffers, and listed buffers. Ideal for turn start.
    - Parameter: `buffer` (string | number, optional) - Target buffer name or number to inspect.
  - `get_state`: Returns a full session snapshot: mode, cwd, listed/modified buffers, all visible windows with cursor context, active marks (`a-z`), folds, visual selection bounds, indent settings, and LSP diagnostic counts.
    - Parameter: `buffer` (string | number, optional) - Target buffer name or number to inspect.
  - `exec_lua`: Executes arbitrary Lua code in Neovim's Lua runtime and returns the JSON-serialized result. Supports multi-line blocks, API access (`vim.api.*`, `vim.fn.*`), and return statements (also accepts `eval_lua` as an alias).
    - Parameters: `code` (string, required) - Lua code snippet to execute; `args` (array, optional) - Arguments passed to the chunk (`...`).
  - `send_command`: Executes a Vim Ex command (e.g. `:w`, `:split`, `:edit`, `:set number`) and captures formatted command output. Leading `:` is optional (also accepts `exec_command` and `vim_command` as aliases).
    - Parameters: `command` (string, required) - Vim command to execute; `output` (boolean, optional, default true) - Whether to capture command output.
  - `send_keys`: Injects keystrokes into Neovim as if typed by the user. Automatically translates Vim key notations (`<Esc>`, `<CR>`, `<Tab>`, `<C-w>v`) into terminal control codes.
    - Parameters: `keys` (string, required) - Keystrokes to send; `escape` (boolean, optional, default true) - Prepend `<Esc>` to guarantee normal-mode entry.
  - `read_full_buf`: Read the entire contents of a buffer, with line numbers.
    - Parameter: `buffer` (string | number, required) - Buffer name, relative/absolute file path, or buffer number.
  - `read_buf_range`: Read a specific line range from a buffer.
    - Parameters: `buffer` (string | number, required) - Buffer name, path, or number; `start_line` (integer, required) - 1-indexed first line; `end_line` (integer, required) - 1-indexed last line.
  - `find_and_replace_buf`: Exact-match find and replace within a buffer. Safe in-memory replacement with full undo tree preservation; fails if string is missing or non-unique.
    - Parameters: `buffer` (string | number, required) - Buffer name, path, or number; `find` (string, required) - Exact text to locate; `replace` (string, required) - Replacement text.
  - `write_full_buf`: Replace the entire contents of a buffer in-memory with full undo support.
    - Parameters: `buffer` (string | number, required) - Target buffer name, path, or number; `content` (string, required) - Full replacement text.
- **Resources**:
  - `neovim://buffers`: Returns a JSON array of all open buffers with comprehensive status metadata in a single RPC round-trip:
    - `id`: Buffer number (`bufnr`)
    - `name`: Buffer file path or name
    - `listed`: Visible in buffer list (`buflisted`)
    - `loaded`: Loaded in memory
    - `modified`: Unsaved changes flag
    - `hidden`: Hidden / unmapped buffer
    - `line_count`: Total lines in the buffer
    - `cursor_line`: Last known cursor line number
    - `windows`: Array of window IDs displaying this buffer
    - `last_used`: Last access timestamp
    - `filetype`: Detected filetype (e.g. `zig`, `markdown`, `lua`)
    - `buftype`: Neovim buffer type (`""`, `help`, `nofile`, `terminal`, etc.)

### Agent Skills & Integration Tests

- **Agent Skill Guide**: An official agent skill is available in [`skills/neovim-boss/SKILL.md`](skills/neovim-boss/SKILL.md). It provides AI coding agents (such as Claude Code, Antigravity, Cursor, etc.) with operational guidelines, tool selection recipes, and safety rules for editing running Neovim sessions.
- **Autonomous Agent Integration Tests**: Test prompts are provided in [`agent_tests/edit_tools.md`](agent_tests/edit_tools.md) and [`agent_tests/TEST_PROMPT.md`](agent_tests/TEST_PROMPT.md) for end-to-end verification of reading, safe editing, undo behavior, and multi-window navigation.

---

## Roadmap

Following the comparative architecture review in [`plans/nvim-mcp-review.md`](plans/nvim-mcp-review.md) and [`plans/tools_sep.md`](plans/tools_sep.md), the capabilities of `neovim-boss` are structured across foundational milestones and upcoming releases:

### Completed Milestones

- **Phase 1: Core Client Library & Engine**:
  - High-performance multi-transport connectivity: Unix domain sockets, TCP network sockets, embedded headless child instances (`nvim --embed --headless`), and `stdio`.
  - Smart connection auto-detection with `$NVIM` socket affinity.
  - 260+ strongly-typed API wrappers generated directly from bundled `api_info.msgpack`.
  - Zero-heap extension handles (`Buffer`, `Window`, `Tabpage`).
  - Bidirectional MessagePack-RPC session with re-entrant reverse RPC handling (`rpcrequest`) and continuous event loop (`runLoop`).
- **Phase 2: Situational Awareness & Safe In-Memory Editing**:
  - **Sensory Feedback Loop**: High-speed, single-round-trip orientation snapshots (`get_state_brief` and `get_state`) returning active mode, cwd, listed/modified buffers, visible window bounds, numbered context lines around the cursor, marks, folds, and diagnostics counts.
  - **Safe In-Memory Editing**: Exact-match substring replacement (`find_and_replace_buf`) that fails safely on missing or ambiguous matches and preserves Neovim's native undo tree (`u`) across active and background buffers.
  - **Buffer Inspection & Rewriting**: Line-numbered reading (`read_full_buf`, `read_buf_range`) and in-memory full replacement (`write_full_buf`).
  - **Scripting & Command Execution**: Lean execution suite (`exec_lua`, `send_command`, `send_keys`) replacing thousands of tokens of boilerplate.
  - **Telemetry Resources**: Live buffer introspection via `neovim://buffers`.
  - **Embedded Lua Architecture**: Dedicated Lua scripts in `src/lua/` compiled into the binary via `@embedFile`.
  - **Agent Skills & Autonomous Tests**: Comprehensive skill definition and integration test suites.

### Deliberate Design Streamlining & Omissions

Based on the tools analysis in [`plans/tools_sep.md`](plans/tools_sep.md) and [`plans/test_prompt_ideas.md`](plans/test_prompt_ideas.md):
- **Zero Companion Plugins**: Unlike other servers requiring Neovim Lua plugins, `neovim-boss` strictly communicates over native RPC sockets out of the box with zero user configuration.
- **Pruned Redundant Granular Tools**: Rather than exposing dozens of narrow tools (`open_buffer`, `switch_buffer`, `split_window`, `close_window`, `call_function`, `eval_vimscript`, `vim_mark`, `vim_fold`, `vim_tab`), Neovim's existing Ex grammar (`send_command` with `:e`, `:b`, `:split`, `:tabnew`) and keystrokes (`send_keys` with `u`, `ggVG`) already handle over 70% of editor workflows cleanly without schema bloat.
- **No Direct Shell Execution (`:!cmd`)**: Running arbitrary shell commands via Ex mode was rejected due to security risks; non-stealing terminal job channels are preferred.
- **No Macro Recording Tools**: Recording/replaying macros via LLMs was rejected as brittle compared to direct text manipulation.
- **No Connection ID Friction**: Avoided requiring agents to pass session/connection tokens on every tool call in favor of automatic `$NVIM` socket detection.

### Upcoming Releases

- **Phase 3: Visual Annotations & Terminal Channels**:
  - **Extmarks & Highlights**: Theme-aware line highlights (`highlight_range`, `highlight_ranges`, `clear_highlights`) for visual agent communication without altering files on disk.
  - **Virtual Text Notes**: In-buffer visual comments (`add_virtual_text`, `add_virtual_texts`, `clear_virtual_texts`) positioned inline, above, or below target lines.
  - **Non-Stealing Terminal Control**: Send commands directly to Neovim terminal job channels (`send_to_terminal`) with review (`submit: false`) or immediate execution (`submit: true`).
- **Phase 4: Ambient Context Resources & Vim Primitives**:
  - **Ambient State Resources**: Symbiotic MCP resources (`neovim://state`, `neovim://state/brief`, `neovim://current_buffer`) allowing MCP clients to subscribe to live editor updates.
  - **Vim Primitives**: Register inspection/manipulation (`get_register`, `set_register`), buffer search (`search_buffer`), and explicit window resizing (`resize_window`).
  - **MCP Prompts**: Parameterized workflow prompts (`neovim_workflow` / `nb_pair_programming`) guiding agents on optimal Neovim tool chaining.
- **Phase 5: Code Intelligence & LSP Proxies**:
  - **Native LSP Integration**: Proxy Neovim's built-in LSP client via `nvim_exec_lua` calling `vim.lsp.buf_request_sync` (`get_diagnostics`, `lsp_definition`, `lsp_references`, `lsp_hover`) without external plugins.
  - **HTTP / SSE Transport**: Streamable HTTP and Server-Sent Events transport for remote containers and multi-client pair programming.

---

## Installation

These instructions are for when using as a library in your own applications.

Add `neovim-boss` to your project's `build.zig.zon`:

```zig
.{
    .name = .my_project,
    .version = "0.1.0",
    .dependencies = .{
        .neovim_boss = .{
            .url = "https://github.com/justinhj/neovim-boss/archive/main.tar.gz",
            .hash = "...", // Run `zig build` to obtain the package hash
        },
    },
}
```

In your `build.zig`:

```zig
const neovim_boss = b.dependency("neovim_boss", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("neovim_boss", neovim_boss.module("neovim_boss"));
```

---

## Quick Start

### 1. Spawning an Embedded Instance

```zig
const std = @import("std");
const neovim_boss = @import("neovim_boss");
const api = neovim_boss.api;

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    // Spawns `nvim --embed --headless` automatically
    var nvim = try neovim_boss.attach(gpa, io, .{ .child = null });
    defer nvim.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Call API methods
    const buf = try api.nvim_get_current_buf(&nvim, alloc);

    var line1 = "Hello from neovim-boss!".*;
    try buf.setLines(&nvim, alloc, 0, -1, false, &.{
        .{ .string = &line1 },
    });

    const lines = try buf.getLines(&nvim, alloc, 0, -1, false);
    for (lines) |line| {
        if (neovim_boss.asString(line)) |text| {
            std.debug.print("Buffer line: {s}\n", .{text});
        }
    }
}
```

### 2. Connecting to an Existing Neovim Instance

Start Neovim listening on a socket or TCP port:

```bash
# Unix domain socket
nvim --listen /tmp/nvim.sock

# Or TCP
nvim --listen 127.0.0.1:6666
```

Connect using `attachAddress`:

```zig
// Automatically recognizes Unix sockets, TCP "host:port", "child", or "stdio"
var nvim = try neovim_boss.attachAddress(gpa, io, "/tmp/nvim.sock");
defer nvim.deinit();
```

### 3. Querying Buffer Telemetry in One Round-Trip

```zig
// Fetch detailed metadata for listed buffers in 1 RPC round trip
const buffers = try nvim.listBufInfo(alloc, .{ .buflisted = true });
for (buffers) |b| {
    std.debug.print("Buffer #{d}: {s} [ft={s}, modified={}, lines={d}]\n", .{
        b.id,
        b.name,
        b.filetype,
        b.modified,
        b.line_count,
    });
}
```

---

## Examples

Run any of the included examples or the MCP server with `zig build`:

| Command | Description |
| :--- | :--- |
| `zig build run -- mcp [listener]` | Runs the Model Context Protocol (MCP) server over stdio. |
| `zig build run-basic -- <socket>` | Connects via Unix domain socket and calls `nvim_eval("2 + 2")`. |
| `zig build run-phase2 -- <address>` | Tests connection handshake, client version registration, convenience methods (`eval`, `command`), and `Buffer` ext type decoding. |
| `zig build run-embed` | Spawns an embedded headless child process (`nvim --embed --headless`), verifies handshake, evaluates expressions, and updates buffer lines. |
| `zig build run-phase4` | Demonstrates the generated strongly-typed API wrappers and attached methods on `Buffer`, `Window`, and `Tabpage`. |
| `zig build run-phase5` | Demonstrates bidirectional RPC (reverse requests from Neovim to Zig client), buffer event subscriptions (`buf.attach()`), and the event loop (`runLoop`). |

---

## Build System & Code Generation

`neovim-boss` bundles a frozen Neovim API schema in `data/api_info.msgpack`. Compilation does not require `nvim` in `$PATH`.

- **Regenerate API bindings**:
  ```bash
  zig build generate-api
  ```
  Runs `tools/codegen.zig` to unpack `data/api_info.msgpack` and regenerate `src/api.zig`.

- **Update API schema from host Neovim**:
  ```bash
  zig build update-api-info
  ```
  Dumps the active host Neovim schema via `nvim --api-info` into `data/api_info.msgpack`.

- **Run unit and integration tests**:
  ```bash
  zig build test --summary all
  ```

---

## Design Choices

### 1. Layered Architecture
The codebase is structured into clear, decoupled layers:
- **Layer 1: Transport (`src/transport.zig`)**: Abstraction over POSIX file descriptors, Unix domain sockets, TCP network sockets, stdio, and piped child processes.
- **Layer 2: Serialization (`zig-msgpack`)**: High-performance streaming MessagePack unpacker and zero-copy packer.
- **Layer 3: RPC Session & Client (`src/client.zig`)**: MessagePack-RPC session tracking message IDs, request-response matching, notification dispatching, and reverse RPC handling.
- **Layer 4: Neovim Protocol & Types (`src/nvim.zig`, `src/nvim_types.zig`, `src/lua/`)**: Manages the Neovim handshake (`nvim_set_client_info`), channel metadata, extension type registration, high-level composite queries (`listBufInfo`, `getState`), compile-time embedded Lua routines (`src/lua/*.lua`), and the event loop.
- **Layer 5: Generated API (`src/api.zig`)**: 260+ strongly-typed wrapper functions and object methods.
- **Layer 6: MCP Server & CLI (`src/mcp/`, `src/main.zig`)**: JSON-RPC 2.0 stdio server providing MCP tools (`get_state_brief`, `get_state`, `read_full_buf`, `read_buf_range`, `find_and_replace_buf`, `write_full_buf`, `exec_lua`, `send_command`, `send_keys`) and resources (`neovim://buffers`) with request-scoped arena allocation.

### 2. Synchronous RPC with Re-Entrant Reverse Handling
Zig 0.16 currently lacks a finalized language-level async/await story. `neovim-boss` adopts a blocking, synchronous model for outgoing requests while safely handling interleaved notifications and reverse RPC requests (`rpcrequest()`). If Neovim calls back into the client while processing a command, the request handler executes re-entrantly and transmits the response without deadlocking.

### 3. Arena Allocation Strategy
MessagePack objects form arbitrarily nested trees (strings, arrays, maps). Rather than allocating individual nodes on the heap and tracking manual frees:
- Every API request takes an `arena: std.mem.Allocator`.
- All response data and temporary packing slices are allocated from the arena.
- Callers reset or deinitialize the arena when finished, ensuring high performance and eliminating memory leaks.

### 4. Zero-Heap Extension Handles
Neovim represents remote references (`Buffer`, `Window`, `Tabpage`) as MessagePack extension types containing integer handles. `decodeHandle` and `encodeHandleBuf` parse and serialize variable-length MessagePack integer encodings using fixed stack buffers with zero heap allocations.

### 5. Decoupled Build-Time Codegen
Neovim's API schema is extracted via `nvim --api-info` and bundled in `data/api_info.msgpack`. The codegen tool parses this file to produce native Zig types, enabling clean builds in hermetic CI environments without requiring Neovim installed on the build machine.

### 6. Undo-Safe In-Memory Buffer Modifications
All buffer mutation tools (`find_and_replace_buf`, `write_full_buf`) operate directly in memory without touching disk. Modifications preserve Neovim's native undo tree (`u`) across both foreground and background buffers (using window-targeted edits and `undojoin`), allowing the user or agent to immediately revert changes cleanly.

### 7. Compile-Time Embedded Lua Scripts
Complex multi-step editor operations (such as deep state snapshots, boundary-safe line reading, and undo-safe buffer rewriting) are implemented as dedicated Lua scripts in `src/lua/` and embedded directly into the executable using `@embedFile`. This achieves maximum maintainability, modular testing, and zero runtime disk I/O.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

Copyright 2026 Justin Heyes-Jones
