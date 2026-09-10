# Plan: neovim-boss — A Zig Neovim Client Library

## Context

Build a Zig equivalent of pynvim — a Neovim client library that communicates via msgpack-RPC. The foundation is `justinhj/zig-msgpack` (Zig 0.16.0+), which already provides msgpack serialization, streaming unpacker, ext type support with registry, and a full msgpack-RPC layer (message parsing, packing, and a Session with auto-incrementing IDs).

The goal is a new Zig library project (not modifications to pynvim). It starts as a client library (sending requests to nvim), with plugin host support deferred to later.

## Architecture

4-layer stack mapping to pynvim:

```
Layer 4: Nvim           — User-facing API, ext type conversion (Buffer/Window/Tabpage)
Layer 3: Client         — Pending request tracking, blocking request/response, notification dispatch
Layer 2: (zig-msgpack)  — rpc.Session, rpc.parseMessage, Unpacker, Packer (already exists)
Layer 1: Transport      — TCP, Unix socket, stdio, child process → reader/writer pair
```

## Project Structure

```
neovim-boss/
  build.zig              — includes codegen build step
  build.zig.zon          — depends on justinhj/zig-msgpack
  data/
    api_info.msgpack     — bundled Neovim API schema from `nvim --api-info`
  tools/
    codegen.zig          — parses api_info.msgpack and generates src/api.zig
  src/
    root.zig             — Public API re-exports
    transport.zig        — Layer 1: connection types → reader/writer pairs
    client.zig           — Layer 3: RPC client with blocking request pattern
    nvim.zig             — Layer 4: Nvim object, init handshake, convenience methods
    nvim_types.zig       — Buffer, Window, Tabpage structs + ext encode/decode
    object_util.zig      — walk() equivalent, MsgPackObject → Zig type helpers
    api.zig              — Generated typed wrappers for all 260+ Neovim API functions
  examples/
    basic.zig            — Connect to running nvim, eval, print result
    embed.zig            — Spawn nvim --embed, run commands
```

## Key Design Decisions

### Concurrency: single-threaded blocking

- `request()` writes the request then loops reading the transport until the matching response arrives
- Notifications arriving mid-wait are dispatched inline to an optional callback
- Same model as pynvim's `_blocking_request` and the existing hellonvim example
- Why: simplest correct approach; Zig 0.16 has no stable async/await; proven pattern

### Memory: arena allocators

Every request method takes an `arena: Allocator`. Responses are allocated from it. Caller uses `ArenaAllocator` and resets after processing. No per-object free tracking needed.

### Ext types & API Code Generation (from `api-info`)

- **Compile-time / Build-time Codegen**: Neovim's `nvim --api-info` outputs msgpack describing all 260+ API functions, parameters, return types, and ext type IDs. A build-time generator tool (`tools/codegen.zig`) parses bundled `data/api_info.msgpack` and generates `src/api.zig` containing strongly-typed wrappers for every API method.
- **Runtime Handshake (`nvim_get_api_info`)**: At connect time (`Nvim.init`), the client sends `nvim_get_api_info` to get the dynamic `channel_id` (required for registering event listeners and `nvim_set_client_info`) and to verify API version compatibility against the compiled schema.
- **Ext type conversion**: Ext types (`Buffer` = 0, `Window` = 1, `Tabpage` = 2) are decoded from MsgPackExtension directly into strongly-typed wrapper structs with attached helper methods (`buf.getLines()`, `win.setCursor()`, etc.).

### Error handling

Zig error unions for RPC errors. When nvim returns an error in the response, `request()` returns `NvimError.RpcError` with the message accessible on the Client struct.

## Implementation Phases

### Phase 1 — Minimal working client

**Files:** `build.zig`, `build.zig.zon`, `src/root.zig`, `src/transport.zig`, `src/client.zig`, `examples/basic.zig`

1. **`transport.zig`** — Unix socket connect only (simplest first). Returns a struct with `reader: std.io.AnyReader` and `writer: std.io.AnyWriter`. `close()` cleans up.

2. **`client.zig`** — Wraps zig-msgpack's `rpc.Session` + `Unpacker`. Core methods:
   - `request(arena, method, params) !MsgPackObject` — blocking: pack request, write to transport, read loop until matching response. Dispatches notifications inline.
   - `notify(method, params) !void` — fire-and-forget.
   - `poll(arena) !?Message` — read and parse one message.

3. **`examples/basic.zig`** — Connect to a running nvim socket, call `nvim_eval("2+2")`, print result. Proves the transport+client stack works.

### Phase 2 — Nvim object and ext types

**Files:** `src/nvim_types.zig`, `src/object_util.zig`, `src/nvim.zig`

4. **`nvim_types.zig`** — `Buffer`, `Window`, `Tabpage` structs holding `handle: i64`. Methods to decode from MsgPackExtension data (msgpack-encoded integer) and encode back.

5. **`object_util.zig`** — Helper functions: `asString(obj)`, `asInt(obj)`, `asArray(obj)`, `asMap(obj)`. A `walkObject(arena, obj, transformFn)` that recursively applies a transform to MsgPackObject trees.

6. **`nvim.zig`** — `Nvim.init(allocator, transport)`:
   - Creates Client
   - Sends `nvim_set_client_info` notification
   - Sends `nvim_get_api_info` request → `[channel_id, metadata]`
   - Records `channel_id` on Nvim struct (used for events and subscription callbacks)
   - Validates ext type IDs (`Buffer`, `Window`, `Tabpage`) and API version against compiled schema
   - Basic convenience methods: `command()`, `eval()`, `callFunction()`, `execLua()`

### Phase 3 — Full transport support

**Files:** extend `src/transport.zig`

7. Add `connectTcp(address, port)` — `std.net.tcpConnectToHost`
8. Add `connectStdio()` — stdin/stdout reader/writer
9. Add `spawnChild(allocator, argv)` — `std.process.Child` with stdin/stdout pipes, default argv `["nvim", "--embed", "--headless"]`
10. Top-level `attach()` in `root.zig` mirroring pynvim's `attach(transport_type, **kwargs)`

### Phase 4 — API Code Generation from `api-info`

**Files:** `data/api_info.msgpack`, `tools/codegen.zig`, `src/api.zig`, `build.zig`

11. **Bundled API metadata (`data/api_info.msgpack`)** — Frozen Neovim API schema extracted via `nvim --api-info` so compilation does not require `nvim` installed in `$PATH`.
12. **API Codegen Tool (`tools/codegen.zig`)**:
    - Unpacks `data/api_info.msgpack` using `zig-msgpack`
    - Parses `functions`, `types`, and `version` tables
    - Maps Neovim types to Zig types (`Integer` → `i64`, `Boolean` → `bool`, `String` → `[]const u8`, `Buffer`/`Window`/`Tabpage`, `Array`/`Dictionary`)
    - Emits `src/api.zig` containing strongly-typed RPC wrappers for all 260+ Neovim API functions with automatic parameter packing and return value unpacking
    - Attaches methods to `Buffer`, `Window`, and `Tabpage` structs for methods with `method = true` (`nvim_buf_*` → `buf.getLines()`, `nvim_win_*` → `win.getCursor()`, etc.)
13. **Build system integration (`build.zig`)**:
    - `zig build generate-api` — Compiles and executes `tools/codegen.zig` to regenerate `src/api.zig`
    - `zig build update-api-info` — Runs host `nvim --api-info > data/api_info.msgpack` to sync against new Neovim versions

### Phase 5 — Notification handling and event loop (future)

14. `notification_handler` callback on Client
15. `Nvim.runLoop()` for continuous event processing
16. Bidirectional RPC (handling requests from nvim to client)

## Verification

After each phase:
- **Phase 1**: Run `examples/basic.zig` against a running nvim (`nvim --listen /tmp/nvim.sock`). Should print `4` from `nvim_eval("2+2")`.
- **Phase 2**: Run example that spawns embedded nvim, creates a buffer, gets its name. Verify Buffer ext type round-trips correctly.
- **Phase 3**: Test all 4 transport types: unix socket, TCP (`nvim --listen 127.0.0.1:6666`), child process, stdio.
- **Phase 4**: Run `zig build generate-api`. Run an example calling generated typed functions (e.g. `buf.getLines()`, `win.getCursor()`, `nvim_list_bufs()`) and verify type safety and error handling.
- **Tests**: `zig build test` at each phase. Test transport connect/close, client request/response round-trip, ext type encode/decode, object_util helpers, and codegen output.

## References

- `zig-msgpack/src/rpc.zig` — RPC Session, parseMessage, pack functions (the foundation)
- `zig-msgpack/src/unpacker.zig` — Streaming Unpacker with feed()/next()
- `zig-msgpack/examples/hellonvim.zig` — Working proof-of-concept to formalize
- `pynvim/api/nvim.py` — Reference for init flow, `_from_nvim`/`_to_nvim`, API methods
- `pynvim/msgpack_rpc/async_session.py` — Reference for message dispatch and request tracking
- `pynvim/api/common.py` — Reference for walk(), Remote base class, ext type handling
