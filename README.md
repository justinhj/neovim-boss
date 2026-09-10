# neovim-boss (`nb`)

A high-performance, robust, and strongly-typed **Neovim API client library and CLI** for [Zig](https://ziglang.org) (v0.16.0+), built on [`justinhj/zig-msgpack`](https://github.com/justinhj/zig-msgpack).

`neovim-boss` provides complete programmatic control over running or embedded Neovim instances via MessagePack-RPC. It is designed both as a standalone library for Zig applications and as the underlying engine for an upcoming **Neovim Model Context Protocol (MCP) server**, allowing AI agents and LLM tools to introspect, query, edit buffers, and interact with your editor in real time.

---

## Features

- **Multi-Transport Support**:
  - **Unix Domain Sockets**: Connect to running Neovim instances (`nvim --listen /tmp/nvim.sock`).
  - **TCP Sockets**: Connect across local or remote networks (`nvim --listen 127.0.0.1:6666`).
  - **Child Process Embedding**: Automatically spawn and supervise headless child instances (`nvim --embed --headless`).
  - **Standard I/O (`stdio`)**: Run directly as a coprocess or embedded plugin filter.
- **Smart Connection Auto-Detection**:
  - `neovim_boss.attachAddress(allocator, io, target)` automatically routes to child, stdio, TCP (`host:port`), or Unix domain socket paths.
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

## Roadmap: Neovim MCP Server

`neovim-boss` is engineered to power an MCP (Model Context Protocol) server for Neovim. The roadmap includes:

- **Editor Context Provider**: Expose buffer lists, active window layout, cursor positions, file trees, and LSP diagnostics to AI agents.
- **Tool Dispatch**: Provide MCP tools for semantic file editing, buffer modifications (`nvim_buf_set_lines`, `nvim_buf_set_text`), executing Lua commands, and running tests.
- **Agent Coordination**: Enable pair-programming agents to interact directly with the user's active editor session without relying on file system polling.

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

---

## Examples

Run any of the included examples with `zig build`:

| Command | Description |
| :--- | :--- |
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
- **Layer 4: Neovim Protocol (`src/nvim.zig`)**: Manages the Neovim handshake (`nvim_set_client_info`, `nvim_get_api_info`), channel metadata, extension type registration, and the event loop.
- **Layer 5: Generated API (`src/api.zig`)**: 260+ strongly-typed wrapper functions and object methods.

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
