const std = @import("std");
const msgpack = @import("zig_msgpack");
const MsgPackObject = msgpack.MsgPackObject;
const MsgPackMapEntry = msgpack.MsgPackMapEntry;
const nvim_mod = @import("../nvim.zig");
const Nvim = nvim_mod.Nvim;
const nvim_types = @import("../nvim_types.zig");
const types = @import("types.zig");
const object_util = @import("../object_util.zig");

pub const ToolCallResult = struct {
    content: []const types.TextContent,
    isError: bool = false,
};

/// Convert a MsgPackObject to a std.json.Value allocated from arena.
pub fn msgPackToJson(arena: std.mem.Allocator, obj: MsgPackObject) !std.json.Value {
    switch (obj) {
        .nil => return .{ .null = {} },
        .boolean => |b| return .{ .bool = b },
        .integer => |i| return .{ .integer = i },
        .unsigned_integer => |u| {
            if (u <= @as(u64, @intCast(std.math.maxInt(i64)))) {
                return .{ .integer = @intCast(u) };
            } else {
                return .{ .float = @floatFromInt(u) };
            }
        },
        .float32 => |f| return .{ .float = @floatCast(f) },
        .float64 => |f| return .{ .float = f },
        .string => |s| return .{ .string = s },
        .binary => |b| return .{ .string = b },
        .array => |arr| {
            var json_arr = std.json.Array.init(arena);
            for (arr) |item| {
                const val = try msgPackToJson(arena, item);
                try json_arr.append(val);
            }
            return .{ .array = json_arr };
        },
        .map => |entries| {
            var json_map: std.json.ObjectMap = .empty;
            for (entries) |entry| {
                const key_str = switch (entry.key) {
                    .string => |s| s,
                    else => try std.fmt.allocPrint(arena, "{f}", .{std.json.fmt(try msgPackToJson(arena, entry.key), .{})}),
                };
                const val = try msgPackToJson(arena, entry.value);
                try json_map.put(arena, key_str, val);
            }
            return .{ .object = json_map };
        },
        .extension => |ext| {
            var json_map: std.json.ObjectMap = .empty;
            if (nvim_types.decodeHandle(ext.data)) |handle| {
                try json_map.put(arena, "handle", .{ .integer = handle });
            } else |_| {
                try json_map.put(arena, "raw", .{ .string = ext.data });
            }
            try json_map.put(arena, "ext_type", .{ .integer = ext.type });
            return .{ .object = json_map };
        },
    }
}

/// Convert a MsgPackObject to a JSON string representation.
pub fn msgPackToJsonString(arena: std.mem.Allocator, obj: MsgPackObject) ![]const u8 {
    const json_val = try msgPackToJson(arena, obj);
    return try std.fmt.allocPrint(arena, "{f}", .{std.json.fmt(json_val, .{})});
}

/// Convert a std.json.Value to a MsgPackObject allocated from arena.
pub fn jsonToMsgPack(arena: std.mem.Allocator, val: std.json.Value) anyerror!MsgPackObject {
    switch (val) {
        .null => return .nil,
        .bool => |b| return .{ .boolean = b },
        .integer => |i| return .{ .integer = i },
        .float => |f| return .{ .float64 = f },
        .number_string => |s| {
            if (std.fmt.parseInt(i64, s, 10)) |i| {
                return .{ .integer = i };
            } else |_| {}
            if (std.fmt.parseFloat(f64, s)) |f| {
                return .{ .float64 = f };
            } else |_| {}
            return .{ .string = try arena.dupe(u8, s) };
        },
        .string => |s| return .{ .string = try arena.dupe(u8, s) },
        .array => |arr| {
            const items = try arena.alloc(MsgPackObject, arr.items.len);
            for (arr.items, 0..) |item, i| {
                items[i] = try jsonToMsgPack(arena, item);
            }
            return .{ .array = items };
        },
        .object => |obj| {
            const entries = try arena.alloc(MsgPackMapEntry, obj.count());
            var i: usize = 0;
            var iter = obj.iterator();
            while (iter.next()) |entry| : (i += 1) {
                entries[i] = .{
                    .key = .{ .string = try arena.dupe(u8, entry.key_ptr.*) },
                    .value = try jsonToMsgPack(arena, entry.value_ptr.*),
                };
            }
            return .{ .map = entries };
        },
    }
}

fn makeErrorResult(arena: std.mem.Allocator, message: []const u8) !ToolCallResult {
    const items = try arena.alloc(types.TextContent, 1);
    items[0] = .{ .text = try arena.dupe(u8, message) };
    return .{
        .content = items,
        .isError = true,
    };
}

fn makeSuccessResult(arena: std.mem.Allocator, text: []const u8) !ToolCallResult {
    const items = try arena.alloc(types.TextContent, 1);
    items[0] = .{ .text = try arena.dupe(u8, text) };
    return .{
        .content = items,
        .isError = false,
    };
}

pub fn listTools(arena: std.mem.Allocator) ![]const types.Tool {
    const get_state_brief_schema =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "buffer": {
        \\      "type": ["string", "number"],
        \\      "description": "Optional buffer name or number to inspect instead of active buffer"
        \\    }
        \\  }
        \\}
    ;

    const get_state_schema =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "buffer": {
        \\      "type": ["string", "number"],
        \\      "description": "Optional buffer name or number to inspect instead of active buffer"
        \\    }
        \\  }
        \\}
    ;

    const exec_lua_schema =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "code": {
        \\      "type": "string",
        \\      "description": "Lua code to execute in Neovim's Lua runtime"
        \\    },
        \\    "args": {
        \\      "type": "array",
        \\      "description": "Optional arguments passed to the Lua code chunk, accessible as '...'"
        \\    }
        \\  },
        \\  "required": ["code"]
        \\}
    ;

    const send_command_schema =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "command": {
        \\      "type": "string",
        \\      "description": "The Vim Ex command to execute (leading ':' is optional)"
        \\    },
        \\    "output": {
        \\      "type": "boolean",
        \\      "description": "Whether to capture and return command output. Defaults to true."
        \\    }
        \\  },
        \\  "required": ["command"]
        \\}
    ;

    const send_keys_schema =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "keys": {
        \\      "type": "string",
        \\      "description": "Keystrokes to send to Neovim. Vim key notation is supported (e.g. '<Esc>', '<CR>', '<Tab>', '<C-w>v')"
        \\    },
        \\    "escape": {
        \\      "type": "boolean",
        \\      "description": "Whether to prepend '<Esc>' so execution begins in normal mode. Defaults to true."
        \\    }
        \\  },
        \\  "required": ["keys"]
        \\}
    ;

    const read_full_buf_schema =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "buffer": {
        \\      "type": ["string", "number"],
        \\      "description": "Buffer name, relative/absolute file path, or buffer number"
        \\    }
        \\  },
        \\  "required": ["buffer"]
        \\}
    ;

    const read_buf_range_schema =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "buffer": {
        \\      "type": ["string", "number"],
        \\      "description": "Buffer name, relative/absolute file path, or buffer number"
        \\    },
        \\    "start_line": {
        \\      "type": "integer",
        \\      "description": "First line to read (1-indexed, inclusive)"
        \\    },
        \\    "end_line": {
        \\      "type": "integer",
        \\      "description": "Last line to read (1-indexed, inclusive)"
        \\    }
        \\  },
        \\  "required": ["buffer", "start_line", "end_line"]
        \\}
    ;

    const find_and_replace_buf_schema =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "buffer": {
        \\      "type": ["string", "number"],
        \\      "description": "Buffer name, relative/absolute file path, or buffer number"
        \\    },
        \\    "find": {
        \\      "type": "string",
        \\      "description": "The exact text to find. Must match exactly once in the buffer. Include surrounding context to make unique if necessary."
        \\    },
        \\    "replace": {
        \\      "type": "string",
        \\      "description": "The replacement text"
        \\    }
        \\  },
        \\  "required": ["buffer", "find", "replace"]
        \\}
    ;

    const write_full_buf_schema =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "buffer": {
        \\      "type": ["string", "number"],
        \\      "description": "Buffer name, relative/absolute file path, or buffer number"
        \\    },
        \\    "content": {
        \\      "type": "string",
        \\      "description": "The full replacement text for the buffer"
        \\    }
        \\  },
        \\  "required": ["buffer", "content"]
        \\}
    ;

    const parsed_get_state_brief = try std.json.parseFromSlice(std.json.Value, arena, get_state_brief_schema, .{});
    const parsed_get_state = try std.json.parseFromSlice(std.json.Value, arena, get_state_schema, .{});
    const parsed_exec_lua = try std.json.parseFromSlice(std.json.Value, arena, exec_lua_schema, .{});
    const parsed_send_command = try std.json.parseFromSlice(std.json.Value, arena, send_command_schema, .{});
    const parsed_send_keys = try std.json.parseFromSlice(std.json.Value, arena, send_keys_schema, .{});
    const parsed_read_full_buf = try std.json.parseFromSlice(std.json.Value, arena, read_full_buf_schema, .{});
    const parsed_read_buf_range = try std.json.parseFromSlice(std.json.Value, arena, read_buf_range_schema, .{});
    const parsed_find_and_replace_buf = try std.json.parseFromSlice(std.json.Value, arena, find_and_replace_buf_schema, .{});
    const parsed_write_full_buf = try std.json.parseFromSlice(std.json.Value, arena, write_full_buf_schema, .{});

    const tools = try arena.alloc(types.Tool, 9);
    tools[0] = .{
        .name = "get_state_brief",
        .description = "Get a concise orientation snapshot of Neovim: mode, cwd, active window with cursor context, modified buffers, and listed buffers.",
        .inputSchema = parsed_get_state_brief.value,
    };
    tools[1] = .{
        .name = "get_state",
        .description = "Get a full session snapshot of Neovim: mode, cwd, all visible windows with cursor context, marks, folds, visual selections, diagnostics counts, and buffers.",
        .inputSchema = parsed_get_state.value,
    };
    tools[2] = .{
        .name = "exec_lua",
        .description = "Execute arbitrary Lua code in Neovim's Lua runtime and return the result",
        .inputSchema = parsed_exec_lua.value,
    };
    tools[3] = .{
        .name = "send_command",
        .description = "Execute a Vim Ex command and capture its output",
        .inputSchema = parsed_send_command.value,
    };
    tools[4] = .{
        .name = "send_keys",
        .description = "Send keystrokes to Neovim as if typed by the user",
        .inputSchema = parsed_send_keys.value,
    };
    tools[5] = .{
        .name = "read_full_buf",
        .description = "Read the entire contents of a buffer, with line numbers.",
        .inputSchema = parsed_read_full_buf.value,
    };
    tools[6] = .{
        .name = "read_buf_range",
        .description = "Read a specific line range from a buffer.",
        .inputSchema = parsed_read_buf_range.value,
    };
    tools[7] = .{
        .name = "find_and_replace_buf",
        .description = "Exact-match find and replace within a buffer.",
        .inputSchema = parsed_find_and_replace_buf.value,
    };
    tools[8] = .{
        .name = "write_full_buf",
        .description = "Replace the entire contents of a buffer.",
        .inputSchema = parsed_write_full_buf.value,
    };
    return tools;
}

pub fn callTool(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    name: []const u8,
    arguments: ?std.json.Value,
) !ToolCallResult {
    if (std.mem.eql(u8, name, "get_state_brief")) {
        return executeGetState(nvim, arena, true, arguments);
    } else if (std.mem.eql(u8, name, "get_state")) {
        return executeGetState(nvim, arena, false, arguments);
    } else if (std.mem.eql(u8, name, "exec_lua") or std.mem.eql(u8, name, "eval_lua")) {
        return executeExecLua(nvim, arena, name, arguments);
    } else if (std.mem.eql(u8, name, "send_command") or std.mem.eql(u8, name, "exec_command") or std.mem.eql(u8, name, "vim_command")) {
        return executeSendCommand(nvim, arena, arguments);
    } else if (std.mem.eql(u8, name, "send_keys")) {
        return executeSendKeys(nvim, arena, arguments);
    } else if (std.mem.eql(u8, name, "read_full_buf")) {
        return executeReadFullBuf(nvim, arena, arguments);
    } else if (std.mem.eql(u8, name, "read_buf_range")) {
        return executeReadBufRange(nvim, arena, arguments);
    } else if (std.mem.eql(u8, name, "find_and_replace_buf")) {
        return executeFindAndReplaceBuf(nvim, arena, arguments);
    } else if (std.mem.eql(u8, name, "write_full_buf")) {
        return executeWriteFullBuf(nvim, arena, arguments);
    }

    const err_text = try std.fmt.allocPrint(arena, "Unknown tool: {s}", .{name});
    return makeErrorResult(arena, err_text);
}

fn executeGetState(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    brief: bool,
    arguments: ?std.json.Value,
) !ToolCallResult {
    var target_buf: ?std.json.Value = null;
    if (arguments) |args| {
        if (args == .object) {
            target_buf = args.object.get("buffer");
        }
    }

    const state_res = nvim.getState(arena, brief, target_buf) catch |err| {
        const err_text = try std.fmt.allocPrint(arena, "Failed to get editor state: {s}", .{@errorName(err)});
        return makeErrorResult(arena, err_text);
    };

    const json_str = try msgPackToJsonString(arena, state_res);
    return makeSuccessResult(arena, json_str);
}

fn executeExecLua(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    tool_name: []const u8,
    arguments: ?std.json.Value,
) !ToolCallResult {
    const args = arguments orelse {
        return makeErrorResult(arena, "Missing arguments: expected an object containing 'code'");
    };

    if (args != .object) {
        return makeErrorResult(arena, "Invalid arguments: expected a JSON object");
    }

    const code_val = args.object.get("code") orelse {
        return makeErrorResult(arena, "Missing required argument 'code'");
    };

    if (code_val != .string) {
        return makeErrorResult(arena, "Argument 'code' must be a string");
    }

    var code = code_val.string;
    // If called via alias eval_lua and code doesn't start with "return ", prepend "return (" ... ")"
    if (std.mem.eql(u8, tool_name, "eval_lua")) {
        const trimmed = std.mem.trim(u8, code, " \r\n\t");
        if (!std.mem.startsWith(u8, trimmed, "return ") and !std.mem.containsAtLeast(u8, trimmed, 1, "\n")) {
            code = try std.fmt.allocPrint(arena, "return ({s})", .{trimmed});
        }
    }

    var lua_args: []const MsgPackObject = &.{};
    if (args.object.get("args")) |passed_args| {
        switch (passed_args) {
            .array => |arr| {
                const converted = try arena.alloc(MsgPackObject, arr.items.len);
                for (arr.items, 0..) |item, i| {
                    converted[i] = try jsonToMsgPack(arena, item);
                }
                lua_args = converted;
            },
            .null => {},
            else => return makeErrorResult(arena, "Argument 'args' must be a JSON array"),
        }
    }

    const res = nvim.execLua(arena, code, lua_args) catch |err| {
        const err_text = try std.fmt.allocPrint(arena, "Failed to execute Lua code: {s}", .{@errorName(err)});
        return makeErrorResult(arena, err_text);
    };

    const json_str = try msgPackToJsonString(arena, res);
    return makeSuccessResult(arena, json_str);
}

fn executeSendCommand(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    arguments: ?std.json.Value,
) !ToolCallResult {
    const args = arguments orelse {
        return makeErrorResult(arena, "Missing arguments: expected an object containing 'command'");
    };

    if (args != .object) {
        return makeErrorResult(arena, "Invalid arguments: expected a JSON object");
    }

    const cmd_val = args.object.get("command") orelse {
        return makeErrorResult(arena, "Missing required argument 'command'");
    };

    if (cmd_val != .string) {
        return makeErrorResult(arena, "Argument 'command' must be a string");
    }

    var cmd = std.mem.trim(u8, cmd_val.string, " \r\n\t");
    if (cmd.len > 0 and cmd[0] == ':') {
        cmd = cmd[1..];
    }

    var capture_output = true;
    if (args.object.get("output")) |out_val| {
        if (out_val == .bool) {
            capture_output = out_val.bool;
        }
    }

    if (capture_output) {
        const out = nvim.commandOutput(arena, cmd) catch |err| {
            const err_text = try std.fmt.allocPrint(arena, "Command execution failed: {s}", .{@errorName(err)});
            return makeErrorResult(arena, err_text);
        };
        const trimmed = std.mem.trim(u8, out, " \r\n\t");
        const final_text = if (trimmed.len > 0) trimmed else "(no output)";
        return makeSuccessResult(arena, final_text);
    } else {
        nvim.command(arena, cmd) catch |err| {
            const err_text = try std.fmt.allocPrint(arena, "Command execution failed: {s}", .{@errorName(err)});
            return makeErrorResult(arena, err_text);
        };
        return makeSuccessResult(arena, "(command executed)");
    }
}

fn executeSendKeys(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    arguments: ?std.json.Value,
) !ToolCallResult {
    const args = arguments orelse {
        return makeErrorResult(arena, "Missing arguments: expected an object containing 'keys'");
    };

    if (args != .object) {
        return makeErrorResult(arena, "Invalid arguments: expected a JSON object");
    }

    const keys_val = args.object.get("keys") orelse {
        return makeErrorResult(arena, "Missing required argument 'keys'");
    };

    if (keys_val != .string) {
        return makeErrorResult(arena, "Argument 'keys' must be a string");
    }

    const raw_keys = keys_val.string;

    var escape = true;
    if (args.object.get("escape")) |esc_val| {
        if (esc_val == .bool) {
            escape = esc_val.bool;
        }
    }

    const full_keys = if (escape and !std.mem.startsWith(u8, raw_keys, "<Esc>") and !std.mem.startsWith(u8, raw_keys, "\x1b"))
        try std.fmt.allocPrint(arena, "<Esc>{s}", .{raw_keys})
    else
        raw_keys;

    // Translate key notation (<CR>, <Esc>, <Tab>, <C-w>, etc.)
    const translated_keys = nvim.replaceTermcodes(arena, full_keys, true, false, true) catch |err| {
        const err_text = try std.fmt.allocPrint(arena, "Failed to translate termcodes: {s}", .{@errorName(err)});
        return makeErrorResult(arena, err_text);
    };

    const bytes_written = nvim.input(arena, translated_keys) catch |err| {
        const err_text = try std.fmt.allocPrint(arena, "Failed to send keys: {s}", .{@errorName(err)});
        return makeErrorResult(arena, err_text);
    };

    var confirm_map: std.json.ObjectMap = .empty;
    try confirm_map.put(arena, "sent", .{ .string = full_keys });
    try confirm_map.put(arena, "bytes_written", .{ .integer = bytes_written });

    const json_text = try std.fmt.allocPrint(arena, "{f}", .{std.json.fmt(std.json.Value{ .object = confirm_map }, .{})});
    return makeSuccessResult(arena, json_text);
}

fn parseOptionalInt(val: std.json.Value) ?i64 {
    return switch (val) {
        .integer => |i| i,
        .number_string => |s| std.fmt.parseInt(i64, s, 10) catch null,
        .string => |s| std.fmt.parseInt(i64, s, 10) catch null,
        else => null,
    };
}

fn handleBufferResult(arena: std.mem.Allocator, res: MsgPackObject) !ToolCallResult {
    if (res == .map) {
        for (res.map) |entry| {
            if (entry.key == .string and std.mem.eql(u8, entry.key.string, "error")) {
                if (object_util.asString(entry.value)) |err_str| {
                    return makeErrorResult(arena, err_str);
                }
            }
        }
    }
    const json_str = try msgPackToJsonString(arena, res);
    return makeSuccessResult(arena, json_str);
}

fn executeReadFullBuf(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    arguments: ?std.json.Value,
) !ToolCallResult {
    const args = arguments orelse {
        return makeErrorResult(arena, "Missing arguments: expected an object containing 'buffer'");
    };

    if (args != .object) {
        return makeErrorResult(arena, "Invalid arguments: expected a JSON object");
    }

    const buf_val = args.object.get("buffer") orelse args.object.get("file") orelse {
        return makeErrorResult(arena, "Missing required argument 'buffer'");
    };

    const target_obj = try jsonToMsgPack(arena, buf_val);
    const res = nvim.readFullBuf(arena, target_obj) catch |err| {
        const msg = nvim.client.lastError() orelse @errorName(err);
        const err_text = try std.fmt.allocPrint(arena, "Failed to read buffer: {s}", .{msg});
        return makeErrorResult(arena, err_text);
    };

    return handleBufferResult(arena, res);
}

fn executeReadBufRange(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    arguments: ?std.json.Value,
) !ToolCallResult {
    const args = arguments orelse {
        return makeErrorResult(arena, "Missing arguments: expected an object containing 'buffer', 'start_line', and 'end_line'");
    };

    if (args != .object) {
        return makeErrorResult(arena, "Invalid arguments: expected a JSON object");
    }

    const buf_val = args.object.get("buffer") orelse args.object.get("file") orelse {
        return makeErrorResult(arena, "Missing required argument 'buffer'");
    };

    const start_line_val = args.object.get("start_line") orelse {
        return makeErrorResult(arena, "Missing required argument 'start_line'");
    };
    const start_line = parseOptionalInt(start_line_val) orelse {
        return makeErrorResult(arena, "Argument 'start_line' must be an integer");
    };

    const end_line_val = args.object.get("end_line") orelse {
        return makeErrorResult(arena, "Missing required argument 'end_line'");
    };
    const end_line = parseOptionalInt(end_line_val) orelse {
        return makeErrorResult(arena, "Argument 'end_line' must be an integer");
    };

    const target_obj = try jsonToMsgPack(arena, buf_val);
    const res = nvim.readBufRange(arena, target_obj, start_line, end_line) catch |err| {
        const msg = nvim.client.lastError() orelse @errorName(err);
        const err_text = try std.fmt.allocPrint(arena, "Failed to read buffer range: {s}", .{msg});
        return makeErrorResult(arena, err_text);
    };

    return handleBufferResult(arena, res);
}

fn executeFindAndReplaceBuf(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    arguments: ?std.json.Value,
) !ToolCallResult {
    const args = arguments orelse {
        return makeErrorResult(arena, "Missing arguments: expected an object containing 'buffer', 'find', and 'replace'");
    };

    if (args != .object) {
        return makeErrorResult(arena, "Invalid arguments: expected a JSON object");
    }

    const buf_val = args.object.get("buffer") orelse args.object.get("file") orelse {
        return makeErrorResult(arena, "Missing required argument 'buffer'");
    };

    const find_val = args.object.get("find") orelse args.object.get("old_string") orelse {
        return makeErrorResult(arena, "Missing required argument 'find'");
    };
    if (find_val != .string) {
        return makeErrorResult(arena, "Argument 'find' must be a string");
    }
    if (find_val.string.len == 0) {
        return makeErrorResult(arena, "Argument 'find' cannot be empty");
    }

    const replace_val = args.object.get("replace") orelse args.object.get("new_string") orelse {
        return makeErrorResult(arena, "Missing required argument 'replace'");
    };
    if (replace_val != .string) {
        return makeErrorResult(arena, "Argument 'replace' must be a string");
    }

    const target_obj = try jsonToMsgPack(arena, buf_val);
    const res = nvim.findAndReplaceBuf(arena, target_obj, find_val.string, replace_val.string) catch |err| {
        const msg = nvim.client.lastError() orelse @errorName(err);
        const err_text = try std.fmt.allocPrint(arena, "Failed to find and replace in buffer: {s}", .{msg});
        return makeErrorResult(arena, err_text);
    };

    return handleBufferResult(arena, res);
}

fn executeWriteFullBuf(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    arguments: ?std.json.Value,
) !ToolCallResult {
    const args = arguments orelse {
        return makeErrorResult(arena, "Missing arguments: expected an object containing 'buffer' and 'content'");
    };

    if (args != .object) {
        return makeErrorResult(arena, "Invalid arguments: expected a JSON object");
    }

    const buf_val = args.object.get("buffer") orelse args.object.get("file") orelse {
        return makeErrorResult(arena, "Missing required argument 'buffer'");
    };

    const content_val = args.object.get("content") orelse args.object.get("text") orelse args.object.get("new_string") orelse {
        return makeErrorResult(arena, "Missing required argument 'content'");
    };
    if (content_val != .string) {
        return makeErrorResult(arena, "Argument 'content' must be a string");
    }

    const target_obj = try jsonToMsgPack(arena, buf_val);
    const res = nvim.writeFullBuf(arena, target_obj, content_val.string) catch |err| {
        const msg = nvim.client.lastError() orelse @errorName(err);
        const err_text = try std.fmt.allocPrint(arena, "Failed to write buffer: {s}", .{msg});
        return makeErrorResult(arena, err_text);
    };

    return handleBufferResult(arena, res);
}


