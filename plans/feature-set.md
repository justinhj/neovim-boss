# neovim-boss (`nb`)

> Zig-powered Neovim control plane for humans and AI — ships as the `nb` executable

## Core Layer (Zig library)

- Connect to any nvim instance via Unix socket or TCP (`nvim --listen`)
- Full typed Neovim RPC API surface — buffers, windows, tabs, commands, marks, registers
- Event subscription (autocmds via `nvim_subscribe`)
- Async-capable: concurrent requests, notification handling
- Zero-copy where possible, comptime-generated API types from nvim's `api_info`

## MCP Server Mode

- Expose nvim operations as MCP tools: `get_buffer`, `set_buffer`, `run_command`, `get_diagnostics`, `open_file`, `search_in_buffers`
- Lets Claude Code and other AI agents directly manipulate a live nvim session
- Runs as a sidecar process, connects to nvim socket

## HTTP/JSON API Mode

- Thin REST layer over the same core
- Human-accessible without MCP: `curl`-able, scriptable from any language
- Good for shell scripts, CI pipelines, editor-agnostic tooling

## Power Features

- Watch mode: stream nvim events over SSE or WebSocket (cursor moves, saves, diagnostics)
- Batch RPC: coalesce multiple calls into one round trip (nvim supports `nvim_call_atomic`)
- Lua eval passthrough: run arbitrary Lua in nvim from outside
- Buffer diffing / snapshot: useful for AI "before/after" workflows
