const std = @import("std");
const msgpack = @import("zig_msgpack");
const MsgPackObject = msgpack.MsgPackObject;
const MsgPackMapEntry = msgpack.MsgPackMapEntry;
const nvim_mod = @import("../nvim.zig");
const Nvim = nvim_mod.Nvim;
const nvim_types = @import("../nvim_types.zig");
const types = @import("types.zig");

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

pub fn listTools(arena: std.mem.Allocator) ![]const types.Tool {
    const schema_json =
        \\{
        \\  "type": "object",
        \\  "properties": {
        \\    "expr": {
        \\      "type": "string",
        \\      "description": "The Vimscript expression to evaluate"
        \\    }
        \\  },
        \\  "required": ["expr"]
        \\}
    ;

    const parsed_schema = try std.json.parseFromSlice(std.json.Value, arena, schema_json, .{});

    const tools = try arena.alloc(types.Tool, 1);
    tools[0] = .{
        .name = "eval_vimscript",
        .description = "Evaluate a Vimscript expression in the connected Neovim instance",
        .inputSchema = parsed_schema.value,
    };
    return tools;
}

pub fn callTool(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    name: []const u8,
    arguments: ?std.json.Value,
) !ToolCallResult {
    if (std.mem.eql(u8, name, "eval_vimscript")) {
        return executeEvalVimscript(nvim, arena, arguments);
    }

    const err_text = try std.fmt.allocPrint(arena, "Unknown tool: {s}", .{name});
    const items = try arena.alloc(types.TextContent, 1);
    items[0] = .{ .text = err_text };
    return .{
        .content = items,
        .isError = true,
    };
}

fn executeEvalVimscript(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    arguments: ?std.json.Value,
) !ToolCallResult {
    const args = arguments orelse {
        const items = try arena.alloc(types.TextContent, 1);
        items[0] = .{ .text = "Missing arguments: expected an object containing 'expr'" };
        return .{ .content = items, .isError = true };
    };

    if (args != .object) {
        const items = try arena.alloc(types.TextContent, 1);
        items[0] = .{ .text = "Invalid arguments: expected a JSON object" };
        return .{ .content = items, .isError = true };
    }

    const expr_val = args.object.get("expr") orelse {
        const items = try arena.alloc(types.TextContent, 1);
        items[0] = .{ .text = "Missing required argument 'expr'" };
        return .{ .content = items, .isError = true };
    };

    if (expr_val != .string) {
        const items = try arena.alloc(types.TextContent, 1);
        items[0] = .{ .text = "Argument 'expr' must be a string" };
        return .{ .content = items, .isError = true };
    }

    const expr = expr_val.string;

    // Call nvim.eval
    const eval_res = nvim.eval(arena, expr) catch |err| {
        const err_text = try std.fmt.allocPrint(arena, "Failed to evaluate Vimscript: {s}", .{@errorName(err)});
        const items = try arena.alloc(types.TextContent, 1);
        items[0] = .{ .text = err_text };
        return .{ .content = items, .isError = true };
    };

    const json_str = try msgPackToJsonString(arena, eval_res);
    const items = try arena.alloc(types.TextContent, 1);
    items[0] = .{ .text = json_str };
    return .{
        .content = items,
        .isError = false,
    };
}
