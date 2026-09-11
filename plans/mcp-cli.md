# MCP Server Implementation Plan (`mcp-cli.md`)

## Goal Description
Implement a bare-bones Model Context Protocol (MCP) server for `neovim-boss` (`nb`).
The server will run over **stdio transport** and maintain a **persistent connection to a live Neovim instance**.
It will be launchable via the CLI command `nb mcp [listener]`, supporting all Neovim listener connection types currently supported by the repository (Unix domain socket, TCP `host:port`, embedded headless `child`, or `stdio`).

In this initial implementation, the MCP server will expose:
1. **Tool**: `eval_vimscript` — evaluates an expression via `Nvim.eval(arena, expr)` and returns the JSON-serialized result.
2. **Resource**: `neovim://buffers` — returns a list of currently open Neovim buffers formatted as JSON (`[{"id": 1, "name": "..."}]`) with MIME type `application/json`.

The implementation will be encapsulated in a new `mcp` module (`src/mcp/` or `src/mcp.zig`), cleanly structured for future expansion (tools, prompts, and resources).

---

## Confirmed User Decisions

> [!NOTE]
> **CLI Argument Defaults**:
> When running `nb mcp`:
> - If an argument is provided, use it directly (e.g. `nb mcp /tmp/nvim.sock`, `nb mcp localhost:6666`, or `nb mcp child`).
> - Else, check the `$NVIM` environment variable (set automatically inside Neovim `:terminal` buffers).
> - If `$NVIM` is unset or empty, print usage instructions and exit:
>   `Usage: nb mcp [listener]`
>   `Supported listeners: <socket-path>, <host:port>, child, stdio`

> [!NOTE]
> **Payload Serialization**:
> - **`neovim://buffers`**: Returns JSON array with MIME type `application/json` containing buffer IDs and buffer file names.
> - **`eval_vimscript`**: Serializes the evaluated `MsgPackObject` to valid JSON string in the tool call text content.

> [!IMPORTANT]
> **Stdio Isolation**:
> Because MCP communicates using JSON-RPC over `stdin`/`stdout`, all informational messages, logs, or debugging prints from `neovim-boss` must strictly go to `stderr`. `stdout` is reserved exclusively for valid newline-delimited JSON-RPC messages.

---

## Architecture & Design

### 1. Connection & Server Lifetime
```
+---------------------+                      +----------------------+
|     MCP Client      |                      |     Neovim Host      |
| (Claude Code, etc.) |                      |   (Socket / TCP /    |
+----------+----------+                      |      Child)          |
           |                                 +----------+-----------+
    stdin / stdout (JSON-RPC)                           | MsgPack-RPC
           |                                            | (Persistent)
           v                                            v
+-------------------------------------------------------------------+
|                        neovim-boss (`nb mcp`)                     |
|                                                                   |
|   +-----------------------------------------------------------+   |
|   |                       MCP Server                          |   |
|   |  - JSON-RPC 2.0 Dispatcher (initialize, ping, etc.)       |   |
|   |  - Tools Registry (eval_vimscript)                        |   |
|   |  - Resources Registry (neovim://buffers)                  |   |
|   |  - Per-request Arena Allocator                            |   |
|   +-----------------------------+-----------------------------+   |
|                                 |                                 |
|                                 v                                 |
|   +-----------------------------------------------------------+   |
|   |               Persistent Neovim Client (Nvim)             |   |
|   +-----------------------------------------------------------+   |
+-------------------------------------------------------------------+
```

- `nb mcp [listener]` connects to Neovim via `neovim_boss.attachAddress(allocator, io, target)`.
- A persistent `*Nvim` instance is held by `mcp.Server`.
- The server runs an event loop reading `\n`-delimited JSON-RPC messages from `stdin`.
- Each request is processed with a request-scoped `std.heap.ArenaAllocator` that is cleared/freed after responding, preventing memory leaks.
- When `stdin` reaches EOF or Neovim disconnects, the server shuts down cleanly.

### 2. Supported MCP Protocol Capabilities (v2024-11-05)

- **`initialize`**:
  Returns protocol version, server capabilities (`tools: {}`, `resources: {}`), and server info (`neovim-boss`, version).
- **`notifications/initialized`**:
  Acknowledges initialization completion (no response needed).
- **`ping`**:
  Returns empty result `{}`.
- **`tools/list`**:
  Returns the list of available tools:
  ```json
  {
    "tools": [
      {
        "name": "eval_vimscript",
        "description": "Evaluate a Vimscript expression in the connected Neovim instance",
        "inputSchema": {
          "type": "object",
          "properties": {
            "expr": {
              "type": "string",
              "description": "Vimscript expression to evaluate"
            }
          },
          "required": ["expr"]
        }
      }
    ]
  }
  ```
- **`tools/call`**:
  Calls `eval_vimscript`:
  1. Validates argument `expr` is a string.
  2. Executes `nvim.eval(arena, expr)`.
  3. Serializes the resulting `MsgPackObject` into JSON.
  4. Returns `{ "content": [{ "type": "text", "text": "<json-result>" }], "isError": false }`.
  5. If Neovim returns an error, returns `{ "content": [{ "type": "text", "text": "<error-message>" }], "isError": true }`.
- **`resources/list`**:
  Returns registered resources:
  ```json
  {
    "resources": [
      {
        "uri": "neovim://buffers",
        "name": "Open Buffers",
        "description": "List of currently open Neovim buffers",
        "mimeType": "application/json"
      }
    ]
  }
  ```
- **`resources/read`**:
  When `uri == "neovim://buffers"`:
  1. Calls `nvim.listBufs(arena)`.
  2. For each buffer, retrieves its name via `nvim.api().nvim_buf_get_name(arena, buf)`.
  3. Serializes a JSON array of `[{"id": <handle>, "name": "<path>"}]`.
  4. Returns `{ "contents": [{ "uri": "neovim://buffers", "mimeType": "application/json", "text": "[...]" }] }`.

---

## Proposed Module Structure

Create a new directory `src/mcp/`:
- `src/mcp/types.zig`: MCP JSON-RPC protocol types and schemas.
- `src/mcp/tools.zig`: Tool definitions, schemas, and handlers (`eval_vimscript`).
- `src/mcp/resources.zig`: Resource definitions and read handlers (`neovim://buffers`).
- `src/mcp/server.zig`: `Server` struct with stdio line reader, JSON-RPC router, and response writer.
- `src/mcp.zig`: Module root re-exporting `Server`, `run`, etc.
- Export in `src/root.zig`: `pub const mcp = @import("mcp.zig");`
- CLI Integration in `src/main.zig`: Parse `mcp` sub-command and target listener argument, then invoke `mcp.run(...)`.

---

## Proposed Changes

### 1. New Module: `src/mcp/`
#### [NEW] `src/mcp/types.zig`
- Common JSON-RPC 2.0 structures: Request, Notification, Response, Error.
- MCP initialization structures, tool definitions, and resource definitions.

#### [NEW] `src/mcp/tools.zig`
- Tool metadata generator for `tools/list`.
- Dispatcher for `tools/call`.
- Handler for `eval_vimscript`:
  ```zig
  pub fn handleEvalVimscript(nvim: *Nvim, arena: std.mem.Allocator, args: std.json.Value) !ToolCallResult
  ```
- JSON serialization helper for converting `MsgPackObject` to JSON.

#### [NEW] `src/mcp/resources.zig`
- Resource metadata generator for `resources/list`.
- Dispatcher for `resources/read`.
- Handler for `neovim://buffers`:
  ```zig
  pub fn handleListBuffers(nvim: *Nvim, arena: std.mem.Allocator) !ResourceReadResult
  ```

#### [NEW] `src/mcp/server.zig`
- `Server` struct:
  ```zig
  pub const Server = struct {
      allocator: std.mem.Allocator,
      io: std.Io,
      nvim: *Nvim,

      pub fn init(allocator: std.mem.Allocator, io: std.Io, nvim: *Nvim) Server;
      pub fn run(self: *Server) !void;
      fn handleLine(self: *Server, line: []const u8) !void;
  };
  ```
- Stdio reader buffering lines until `\n`.
- Stdout writer writing newline-delimited JSON-RPC responses and flushing.

#### [NEW] `src/mcp.zig`
- Facade exposing `Server`, `run`, `types`, `tools`, `resources`.

### 2. Core Exports
#### [MODIFY] `src/root.zig`
- Add:
  ```zig
  pub const mcp = @import("mcp.zig");
  ```

### 3. CLI Entry Point
#### [MODIFY] `src/main.zig`
- Parse `args`:
  - If `args[1]` is `"mcp"`:
    - Determine Neovim target from `args[2]` if provided, else check `$NVIM` env var.
    - If neither is provided, print usage to stderr and exit:
      ```
      Usage: nb mcp [listener]

      Supported listeners:
        /path/to/socket    Unix domain socket (e.g. /tmp/nvim.sock)
        host:port          TCP socket (e.g. 127.0.0.1:6666)
        child              Embedded headless Neovim child process
        stdio              Standard I/O Neovim process
      ```
    - Connect with `neovim_boss.attachAddress(arena, io, target)`.
    - Run `neovim_boss.mcp.run(gpa, io, &nvim)`.
  - Otherwise show help / usage info.

---

## Verification Plan

### Automated Tests
1. **MCP Unit Tests (`zig build test`)**:
   - Test JSON-RPC line parsing and serialization.
   - Test `initialize`, `ping`, `tools/list`, and `resources/list` handlers with mock inputs.
   - Test `eval_vimscript` tool call with embedded child Neovim.
   - Test `neovim://buffers` resource read with embedded child Neovim.

### Integration / Manual Verification
1. **CLI Launch & Argument Resolution**:
   - Run `zig build run -- mcp` with `$NVIM` unset -> verify usage instructions are printed to stderr and process exits cleanly.
   - Run `zig build run -- mcp child` -> verify server starts and accepts JSON-RPC over stdin.
2. **Piped JSON-RPC Verification**:
   - Pipe an `initialize` JSON request into `zig-out/bin/nb mcp child` and verify valid JSON-RPC output on stdout.
   - Pipe `tools/call` for `eval_vimscript` with expr `"3 * 7"` -> verify JSON result `"21"` on stdout.
   - Pipe `resources/read` for `neovim://buffers` -> verify JSON array output on stdout.
3. **Live Neovim Socket Verification**:
   - Start Neovim: `nvim --headless --listen /tmp/test-nvim.sock &`
   - Run `zig-out/bin/nb mcp /tmp/test-nvim.sock` and verify tool/resource execution.
