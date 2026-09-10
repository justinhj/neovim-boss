const std = @import("std");
const msgpack = @import("zig_msgpack");
const MsgPackObject = msgpack.MsgPackObject;
const MsgPackMapEntry = msgpack.MsgPackMapEntry;

fn asString(obj: MsgPackObject) ?[]const u8 {
    return switch (obj) {
        .string => |s| s,
        else => null,
    };
}

fn asMap(obj: MsgPackObject) ?[]MsgPackMapEntry {
    return switch (obj) {
        .map => |m| m,
        else => null,
    };
}

fn asArray(obj: MsgPackObject) ?[]MsgPackObject {
    return switch (obj) {
        .array => |a| a,
        else => null,
    };
}

fn asBool(obj: MsgPackObject) ?bool {
    return switch (obj) {
        .boolean => |b| b,
        else => null,
    };
}

fn asInt(obj: MsgPackObject) ?i64 {
    return switch (obj) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u),
        else => null,
    };
}

fn mapGet(entries: []const MsgPackMapEntry, key: []const u8) ?MsgPackObject {
    for (entries) |entry| {
        if (asString(entry.key)) |k| {
            if (std.mem.eql(u8, k, key)) return entry.value;
        }
    }
    return null;
}

fn escapeParamName(name: []const u8) []const u8 {
    if (std.mem.eql(u8, name, "fn")) return "@\"fn\"";
    if (std.mem.eql(u8, name, "type")) return "@\"type\"";
    if (std.mem.eql(u8, name, "error")) return "@\"error\"";
    return name;
}

fn mapParamType(neovim_type: []const u8) []const u8 {
    if (std.mem.eql(u8, neovim_type, "Integer")) return "i64";
    if (std.mem.eql(u8, neovim_type, "LuaRef")) return "i64";
    if (std.mem.eql(u8, neovim_type, "Boolean")) return "bool";
    if (std.mem.eql(u8, neovim_type, "Float")) return "f64";
    if (std.mem.eql(u8, neovim_type, "String")) return "[]const u8";
    if (std.mem.eql(u8, neovim_type, "Buffer")) return "Buffer";
    if (std.mem.eql(u8, neovim_type, "Window")) return "Window";
    if (std.mem.eql(u8, neovim_type, "Tabpage")) return "Tabpage";
    if (std.mem.eql(u8, neovim_type, "Array")) return "[]const msgpack.MsgPackObject";
    if (std.mem.eql(u8, neovim_type, "Dict")) return "[]const msgpack.MsgPackMapEntry";
    if (std.mem.eql(u8, neovim_type, "Object")) return "msgpack.MsgPackObject";
    return "msgpack.MsgPackObject";
}

fn mapReturnType(neovim_type: []const u8) []const u8 {
    if (std.mem.eql(u8, neovim_type, "void")) return "void";
    if (std.mem.eql(u8, neovim_type, "Integer")) return "i64";
    if (std.mem.eql(u8, neovim_type, "Boolean")) return "bool";
    if (std.mem.eql(u8, neovim_type, "String")) return "[]u8";
    if (std.mem.eql(u8, neovim_type, "Buffer")) return "Buffer";
    if (std.mem.eql(u8, neovim_type, "Window")) return "Window";
    if (std.mem.eql(u8, neovim_type, "Tabpage")) return "Tabpage";
    if (std.mem.eql(u8, neovim_type, "Array")) return "[]msgpack.MsgPackObject";
    if (std.mem.eql(u8, neovim_type, "Dict")) return "[]msgpack.MsgPackMapEntry";
    if (std.mem.eql(u8, neovim_type, "Object")) return "msgpack.MsgPackObject";
    return "msgpack.MsgPackObject";
}

fn snakeToCamel(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    var result: std.ArrayListUnmanaged(u8) = .empty;
    defer result.deinit(allocator);

    var capitalize_next = false;
    for (s) |c| {
        if (c == '_') {
            capitalize_next = true;
        } else if (capitalize_next) {
            try result.append(allocator, std.ascii.toUpper(c));
            capitalize_next = false;
        } else {
            try result.append(allocator, c);
        }
    }
    return result.toOwnedSlice(allocator);
}

const ParamInfo = struct {
    type_name: []const u8,
    param_name: []const u8,
};

const FunctionInfo = struct {
    name: []const u8,
    return_type: []const u8,
    since: ?i64,
    deprecated_since: ?i64,
    method: bool,
    parameters: []ParamInfo,
};

fn parseParam(obj: MsgPackObject) ?ParamInfo {
    const tuple = asArray(obj) orelse return null;
    if (tuple.len < 2) return null;
    return .{
        .type_name = asString(tuple[0]) orelse "Object",
        .param_name = asString(tuple[1]) orelse "arg",
    };
}

fn parseFunctions(arena: std.mem.Allocator, entries: []const MsgPackMapEntry) ![]FunctionInfo {
    const funcs_obj = mapGet(entries, "functions") orelse return &.{};
    const funcs = asArray(funcs_obj) orelse return &.{};

    var result: std.ArrayListUnmanaged(FunctionInfo) = .empty;
    defer result.deinit(arena);

    for (funcs) |func_obj| {
        const f_entries = asMap(func_obj) orelse continue;
        const name = asString(mapGet(f_entries, "name") orelse continue) orelse continue;
        const ret_type = if (mapGet(f_entries, "return_type")) |rt| asString(rt) orelse "void" else "void";
        const since = if (mapGet(f_entries, "since")) |s| asInt(s) else null;
        const deprecated_since = if (mapGet(f_entries, "deprecated_since")) |d| asInt(d) else null;
        const method = if (mapGet(f_entries, "method")) |m| asBool(m) orelse false else false;

        var params_list: std.ArrayListUnmanaged(ParamInfo) = .empty;
        defer params_list.deinit(arena);

        const params_obj = mapGet(f_entries, "parameters");
        const p_arr = if (params_obj) |po| asArray(po) orelse &[_]MsgPackObject{} else &[_]MsgPackObject{};
        for (p_arr) |p_item| {
            if (parseParam(p_item)) |param| {
                try params_list.append(arena, param);
            }
        }

        try result.append(arena, .{
            .name = name,
            .return_type = ret_type,
            .since = since,
            .deprecated_since = deprecated_since,
            .method = method,
            .parameters = try params_list.toOwnedSlice(arena),
        });
    }

    return result.toOwnedSlice(arena);
}

fn writeExtStruct(
    w: anytype,
    arena: std.mem.Allocator,
    struct_name: []const u8,
    ext_id: i8,
    prefix: []const u8,
    functions: []const FunctionInfo,
) !void {
    try w.print(
        \\/// Remote Neovim {s} handle.
        \\pub const {s} = struct {{
        \\    handle: i64,
        \\
        \\    pub const default_ext_type: i8 = {d};
        \\
        \\    pub fn decode(ext: msgpack.MsgPackExtension) TypeError!{s} {{
        \\        return .{{ .handle = try decodeHandle(ext.data) }};
        \\    }}
        \\
        \\    pub fn encode(self: {s}, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackExtension {{
        \\        return .{{
        \\            .type = ext_type,
        \\            .data = try encodeHandleAlloc(arena, self.handle),
        \\        }};
        \\    }}
        \\
        \\    pub fn toObject(self: {s}, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackObject {{
        \\        return .{{ .extension = try self.encode(arena, ext_type) }};
        \\    }}
        \\
        \\    pub fn format(
        \\        self: {s},
        \\        comptime fmt: []const u8,
        \\        options: std.fmt.FormatOptions,
        \\        writer: anytype,
        \\    ) !void {{
        \\        _ = fmt;
        \\        _ = options;
        \\        try writer.print("{s}({{d}})", .{{self.handle}});
        \\    }}
        \\
    , .{ struct_name, struct_name, ext_id, struct_name, struct_name, struct_name, struct_name, struct_name });

    // Generate attached methods where method == true and name starts with prefix
    for (functions) |f| {
        if (!f.method) continue;
        if (!std.mem.startsWith(u8, f.name, prefix)) continue;
        if (f.parameters.len == 0) continue;
        if (!std.mem.eql(u8, f.parameters[0].type_name, struct_name)) continue;

        const sub_name = f.name[prefix.len..];
        const camel_name = try snakeToCamel(arena, sub_name);

        if (f.deprecated_since) |dep| {
            try w.print("    /// Deprecated since API level {d}.\n", .{dep});
        } else if (f.since) |since| {
            try w.print("    /// Since API level {d}.\n", .{since});
        }

        try w.print("    pub fn {s}(self: {s}, nvim: *Nvim, arena: std.mem.Allocator", .{ camel_name, struct_name });
        for (f.parameters[1..]) |p| {
            const zig_type = mapParamType(p.type_name);
            const escaped = escapeParamName(p.param_name);
            try w.print(", {s}: {s}", .{ escaped, zig_type });
        }
        const ret_zig_type = mapReturnType(f.return_type);
        try w.print(") !{s} {{\n", .{ret_zig_type});

        try w.print("        return {s}(nvim, arena, self", .{f.name});
        for (f.parameters[1..]) |p| {
            const var_name = escapeParamName(p.param_name);
            try w.print(", {s}", .{var_name});
        }
        try w.print(");\n    }}\n\n", .{});
    }

    try w.print("}};\n\n", .{});
}

fn writeParamPack(w: anytype, p: ParamInfo) !void {
    const v = escapeParamName(p.param_name);
    if (std.mem.eql(u8, p.type_name, "Integer") or std.mem.eql(u8, p.type_name, "LuaRef")) {
        try w.print("        .{{ .integer = {s} }},\n", .{v});
    } else if (std.mem.eql(u8, p.type_name, "Boolean")) {
        try w.print("        .{{ .boolean = {s} }},\n", .{v});
    } else if (std.mem.eql(u8, p.type_name, "Float")) {
        try w.print("        .{{ .float64 = {s} }},\n", .{v});
    } else if (std.mem.eql(u8, p.type_name, "String")) {
        try w.print("        .{{ .string = @constCast({s}) }},\n", .{v});
    } else if (std.mem.eql(u8, p.type_name, "Buffer")) {
        try w.print("        try {s}.toObject(arena, nvim.ext_types.buffer_id),\n", .{v});
    } else if (std.mem.eql(u8, p.type_name, "Window")) {
        try w.print("        try {s}.toObject(arena, nvim.ext_types.window_id),\n", .{v});
    } else if (std.mem.eql(u8, p.type_name, "Tabpage")) {
        try w.print("        try {s}.toObject(arena, nvim.ext_types.tabpage_id),\n", .{v});
    } else if (std.mem.eql(u8, p.type_name, "Array")) {
        try w.print("        .{{ .array = @constCast({s}) }},\n", .{v});
    } else if (std.mem.eql(u8, p.type_name, "Dict")) {
        try w.print("        .{{ .map = @constCast({s}) }},\n", .{v});
    } else {
        try w.print("        {s},\n", .{v});
    }
}

fn writeFunction(w: anytype, f: FunctionInfo) !void {
    if (f.deprecated_since) |dep| {
        try w.print("/// Deprecated since API level {d}.\n", .{dep});
    } else if (f.since) |since| {
        try w.print("/// Since API level {d}.\n", .{since});
    }

    const ret_zig = mapReturnType(f.return_type);
    try w.print("pub fn {s}(nvim: *Nvim, arena: std.mem.Allocator", .{f.name});
    for (f.parameters) |p| {
        const zig_type = mapParamType(p.type_name);
        const escaped = escapeParamName(p.param_name);
        try w.print(", {s}: {s}", .{ escaped, zig_type });
    }
    try w.print(") !{s} {{\n", .{ret_zig});

    if (f.parameters.len == 0) {
        if (std.mem.eql(u8, f.return_type, "void")) {
            try w.print("    _ = try nvim.client.request(arena, \"{s}\", &.{{}});\n", .{f.name});
            try w.print("    return;\n", .{});
        } else {
            try w.print("    const res = try nvim.client.request(arena, \"{s}\", &.{{}});\n", .{f.name});
            try writeReturnCheck(w, f.return_type);
        }
    } else {
        try w.print("    const params = [_]msgpack.MsgPackObject{{\n", .{});
        for (f.parameters) |p| {
            try writeParamPack(w, p);
        }
        try w.print("    }};\n", .{});

        if (std.mem.eql(u8, f.return_type, "void")) {
            try w.print("    _ = try nvim.client.request(arena, \"{s}\", &params);\n", .{f.name});
            try w.print("    return;\n", .{});
        } else {
            try w.print("    const res = try nvim.client.request(arena, \"{s}\", &params);\n", .{f.name});
            try writeReturnCheck(w, f.return_type);
        }
    }

    try w.print("}}\n\n", .{});
}

fn writeReturnCheck(w: anytype, ret_type: []const u8) !void {
    if (std.mem.eql(u8, ret_type, "Integer")) {
        try w.print(
            \\    return switch (res) {{
            \\        .integer => |i| i,
            \\        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
            \\        else => error.UnexpectedType,
            \\    }};
            \\
        , .{});
    } else if (std.mem.eql(u8, ret_type, "Boolean")) {
        try w.print(
            \\    return switch (res) {{
            \\        .boolean => |b| b,
            \\        else => error.UnexpectedType,
            \\    }};
            \\
        , .{});
    } else if (std.mem.eql(u8, ret_type, "String")) {
        try w.print(
            \\    return switch (res) {{
            \\        .string => |s| s,
            \\        else => error.UnexpectedType,
            \\    }};
            \\
        , .{});
    } else if (std.mem.eql(u8, ret_type, "Buffer")) {
        try w.print(
            \\    return switch (res) {{
            \\        .extension => |ext| try Buffer.decode(ext),
            \\        else => error.UnexpectedType,
            \\    }};
            \\
        , .{});
    } else if (std.mem.eql(u8, ret_type, "Window")) {
        try w.print(
            \\    return switch (res) {{
            \\        .extension => |ext| try Window.decode(ext),
            \\        else => error.UnexpectedType,
            \\    }};
            \\
        , .{});
    } else if (std.mem.eql(u8, ret_type, "Tabpage")) {
        try w.print(
            \\    return switch (res) {{
            \\        .extension => |ext| try Tabpage.decode(ext),
            \\        else => error.UnexpectedType,
            \\    }};
            \\
        , .{});
    } else if (std.mem.eql(u8, ret_type, "Array")) {
        try w.print(
            \\    return switch (res) {{
            \\        .array => |arr| arr,
            \\        else => error.UnexpectedType,
            \\    }};
            \\
        , .{});
    } else if (std.mem.eql(u8, ret_type, "Dict")) {
        try w.print(
            \\    return switch (res) {{
            \\        .map => |m| m,
            \\        else => error.UnexpectedType,
            \\    }};
            \\
        , .{});
    } else {
        // Object
        try w.print("    return res;\n", .{});
    }
}

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const gpa = init.gpa;
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file_writer: std.Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    const file_path = "data/api_info.msgpack";
    const file = try std.Io.Dir.cwd().openFile(io, file_path, .{ .mode = .read_only });
    defer file.close(io);

    var file_buf: [65536]u8 = undefined;
    var fr: std.Io.File.Reader = .init(file, io, &file_buf);
    const stat = try file.stat(io);
    const data = try fr.interface.readAlloc(arena, stat.size);

    var unpacker = try msgpack.Unpacker.init(gpa, .{});
    defer unpacker.deinit();
    try unpacker.feed(data);

    const root_obj = try unpacker.nextAlloc(arena);
    const entries = asMap(root_obj).?;

    const functions = try parseFunctions(arena, entries);

    const out_file_path = "src/api.zig";
    const out_file = try std.Io.Dir.cwd().createFile(io, out_file_path, .{});
    defer out_file.close(io);

    var out_file_buf: [65536]u8 = undefined;
    var f_writer: std.Io.File.Writer = .init(out_file, io, &out_file_buf);
    const w = &f_writer.interface;

    try w.print(
        \\// THIS FILE IS AUTO-GENERATED FROM data/api_info.msgpack. DO NOT EDIT DIRECTLY.
        \\const std = @import("std");
        \\const msgpack = @import("zig_msgpack");
        \\const nvim_mod = @import("nvim.zig");
        \\const Nvim = nvim_mod.Nvim;
        \\const nvim_types = @import("nvim_types.zig");
        \\const TypeError = nvim_types.TypeError;
        \\const decodeHandle = nvim_types.decodeHandle;
        \\const encodeHandleAlloc = nvim_types.encodeHandleAlloc;
        \\
        \\pub const ApiError = error{{
        \\    UnexpectedType,
        \\}} || TypeError || anyerror;
        \\
        \\const root = @This();
        \\
    , .{});

    // Generate Buffer, Window, Tabpage structs
    try writeExtStruct(w, arena, "Buffer", 0, "nvim_buf_", functions);
    try writeExtStruct(w, arena, "Window", 1, "nvim_win_", functions);
    try writeExtStruct(w, arena, "Tabpage", 2, "nvim_tabpage_", functions);

    // Generate all functions
    for (functions) |f| {
        try writeFunction(w, f);
    }

    // Generate Api wrapper struct for Nvim
    try w.print(
        \\/// API namespace providing method syntax on Nvim instances (e.g. nvim.api().getLines(...)).
        \\pub const Api = struct {{
        \\    nvim: *Nvim,
        \\
    , .{});

    for (functions) |f| {
        const ret_zig = mapReturnType(f.return_type);
        try w.print("    pub fn {s}(self: Api, arena: std.mem.Allocator", .{f.name});
        for (f.parameters) |p| {
            const zig_type = mapParamType(p.type_name);
            const escaped = escapeParamName(p.param_name);
            try w.print(", {s}: {s}", .{ escaped, zig_type });
        }
        try w.print(") !{s} {{\n", .{ret_zig});
        try w.print("        return root.{s}(self.nvim, arena", .{f.name});
        for (f.parameters) |p| {
            const var_name = escapeParamName(p.param_name);
            try w.print(", {s}", .{var_name});
        }
        try w.print(");\n    }}\n\n", .{});
    }

    try w.print("}};\n", .{});
    try w.flush();

    var b: [128]u8 = undefined;
    _ = try stdout.write(try std.fmt.bufPrint(&b, "Successfully generated {d} API functions into {s}!\n", .{ functions.len, out_file_path }));
    try stdout.flush();
}
