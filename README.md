# neovim-boss (`nb`)

```  
  __      __
 <  \____/  >
  | [x][x] |
  \   <>   /
    |    |
  //| O  |\\
 (  |____|  )
    d'  'b
```

A high-performance, robust, and strongly-typed **Neovim API client library and CLI** for [Zig](https://ziglang.org) (v0.16.0+), built on [`justinhj/zig-msgpack`](https://github.com/justinhj/zig-msgpack).

`neovim-boss` provides complete programmatic control over running or embedded Neovim instances via MessagePack-RPC. It is designed both as a standalone library for Zig applications and as a native **Neovim Model Context Protocol (MCP) server**, allowing AI agents and LLM tools (such as Claude Desktop, Claude Code, Cursor, and OpenCode) to introspect, query, and interact with your editor in real time.

---

## Features

- **Built-in Model Context Protocol (MCP) Server**:
  - Standards-compliant JSON-RPC 2.0 stdio server implementing the MCP specification.
  - Exposes tools like `eval_vimscript` to evaluate arbitrary Vimscript expressions and receive structured JSON responses.
  - Exposes resources like `neovim://buffers` for real-time buffer telemetry with detailed metadata.
  - Zero external runtimes: compiles to a fast, standalone native binary (`nb`) with instant startup (<1ms).
- **Fast Single-Round-Trip Buffer Telemetry (`listBufInfo`, `BufferInfo`)**:
  - Bulk query buffer lists enriched with filetype, buftype, flags (`buflisted`, `bufloaded`, `bufmodified`, `hidden`), associated window IDs, line counts, and cursor positions in a single RPC round-trip.
- **Multi-Transport Support**:
  - **Unix Domain Sockets**: Connect to running Neovim instances (`nvim --listen /tmp/nvim.sock`).
  - **TCP Sockets**: Connect across local or remote networks (`nvim --listen 127.0.0.1:6666`).
  - **Child Process Embedding**: Automatically spawn and supervise headless child instances (`nvim --embed --headless`).
  - **Standard I/O (`stdio`)**: Run directly as a coprocess or embedded plugin filter.
- **Smart Connection Auto-Detection**:
  - `neovim_boss.attachAddress(allocator, io, target)` and the `nb` CLI automatically route to child, stdio, TCP (`host:port`), or Unix domain socket paths, and auto-detect the active `$NVIM` socket when run inside Neovim.
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

```bash
# Build the nb binary
zig build -Doptimize=ReleaseFast

# 1. Connect to an existing Neovim instance via Unix socket:
./zig-out/bin/nb mcp /tmp/nvim.sock

# 2. Connect via TCP network socket:
./zig-out/bin/nb mcp 127.0.0.1:6666

# 3. Automatically spawn and supervise a headless child Neovim instance:
./zig-out/bin/nb mcp child

# 4. Auto-detect from environment (inside a Neovim :terminal session):
./zig-out/bin/nb mcp
```

> [!TIP]
> When running inside a Neovim `:terminal` buffer, Neovim automatically sets the `$NVIM` environment variable pointing to the active RPC socket. Simply invoking `nb mcp` will attach to your current editor session without any manual socket configuration!

### Configuring with MCP Clients

#### Claude Desktop
Add `neovim-boss` to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "neovim": {
      "command": "/path/to/neovim-boss/zig-out/bin/nb",
      "args": ["mcp", "/tmp/nvim.sock"]
    }
  }
}
```

#### Claude Code
Add to your project's `.mcp.json` or register via the CLI:

```bash
claude mcp add neovim -- /path/to/neovim-boss/zig-out/bin/nb mcp /tmp/nvim.sock
```

### Supported MCP Capabilities

- **Tools**:
  - `eval_vimscript`: Evaluates any Vimscript expression in the running Neovim instance and returns the JSON-serialized result.
    - Parameter: `expr` (string, required) - Vimscript expression to evaluate.
  - `exec_lua`: Executes arbitrary Lua code in Neovim's Lua runtime and returns the JSON-serialized result. Supports multi-line blocks and return statements (also accepts `eval_lua` as an alias).
    - Parameters: `code` (string, required) - Lua code snippet to execute; `args` (array, optional) - Arguments passed to the chunk (`...`).
  - `send_command`: Executes a Vim Ex command (e.g. `:w`, `:split`, `:edit`, `:set number`) and captures formatted command output. Leading `:` is optional (also accepts `exec_command` and `vim_command` as aliases).
    - Parameters: `command` (string, required) - Vim command to execute; `output` (boolean, optional, default true) - Whether to capture command output.
  - `send_keys`: Injects keystrokes into Neovim as if typed by the user. Automatically translates Vim key notations (`<Esc>`, `<CR>`, `<Tab>`, `<C-w>v`) into terminal control codes.
    - Parameters: `keys` (string, required) - Keystrokes to send; `escape` (boolean, optional, default true) - Prepend `<Esc>` to guarantee normal-mode entry.
  - `call_function`: Calls any internal Vimscript or Neovim API function by name with structured JSON argument arrays.
    - Parameters: `function_name` (string, required) - Name of function to invoke (e.g. `abs`, `tolower`, `getbufinfo`); `args` (array, optional) - Arguments to pass.
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

---

## Roadmap

Following the comparative architecture review in `plans/next-steps-based-on-comparison.md`, upcoming releases of `neovim-boss` will expand the MCP toolset and library capabilities across five phases:

- **Phase 1: Core Editing & Window Primitives**:
  - Buffer line manipulation tools (`get_buffer_lines`, `set_buffer_lines`, `open_buffer`, `switch_buffer`).
  - Cursor navigation & layout control (`get_cursor`, `set_cursor`, `split_window`, `resize_window`).
- **Phase 2: Safe In-Memory Editing & Situational Awareness**:
  - Safe search-and-replace (`find_and_replace_buf`) that requires unique substring matches and preserves Neovim's undo history.
  - Editor orientation snapshots (`get_state_brief`) combining active window context, cursor neighborhood lines, editor mode (`n`, `i`, `v`), and listed buffers.
- **Phase 3: Visual Annotations & Terminal Channels**:
  - Extmarks & virtual text (`highlight_range`, `add_virtual_text`, `clear_highlights`) for theme-aware code highlights and inline agent annotations without modifying files on disk.
  - Non-stealing terminal control (`send_to_terminal`) sending input directly to terminal job channels.
- **Phase 4: Traditional Vim Primitives & MCP Prompts**:
  - Register manipulation (`get_register`, `set_register`), marks (`get_marks`, `set_mark`), and Vim regex pattern search (`search_pattern`).
  - Native MCP Prompts guiding agents on optimal Neovim interaction patterns.
- **Phase 5: Code Intelligence & LSP Proxies**:
  - Direct integration with Neovim's built-in LSP client (`get_diagnostics`, `lsp_definition`, `lsp_references`) via `nvim_exec_lua` without requiring separate companion plugins.
  - Optional HTTP/SSE transport for remote container pair programming.

---

## Installation

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
- **Layer 4: Neovim Protocol & Types (`src/nvim.zig`, `src/nvim_types.zig`)**: Manages the Neovim handshake (`nvim_set_client_info`), channel metadata, extension type registration, high-level composite queries (`listBufInfo`), and the event loop.
- **Layer 5: Generated API (`src/api.zig`)**: 260+ strongly-typed wrapper functions and object methods.
- **Layer 6: MCP Server & CLI (`src/mcp/`, `src/main.zig`)**: JSON-RPC 2.0 stdio server providing MCP tools (`eval_vimscript`) and resources (`neovim://buffers`) with request-scoped arena allocation.

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

---

## License

MIT License. See [LICENSE](LICENSE) for details.
