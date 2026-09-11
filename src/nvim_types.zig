const std = @import("std");
const msgpack = @import("zig_msgpack");
const object_util = @import("object_util.zig");

pub const TypeError = error{
    InvalidHandle,
    InvalidExtType,
};

/// Decode an integer handle from raw MessagePack extension bytes without heap allocation.
pub fn decodeHandle(data: []const u8) TypeError!i64 {
    if (data.len == 0) return TypeError.InvalidHandle;

    // Positive fixint: 0x00..0x7f
    if (data[0] <= 0x7f) return @as(i64, data[0]);

    // uint8: 0xcc
    if (data[0] == 0xcc and data.len >= 2) return @as(i64, data[1]);

    // uint16: 0xcd
    if (data[0] == 0xcd and data.len >= 3) return @as(i64, std.mem.readInt(u16, data[1..3], .big));

    // uint32: 0xce
    if (data[0] == 0xce and data.len >= 5) return @as(i64, std.mem.readInt(u32, data[1..5], .big));

    // uint64: 0xcf
    if (data[0] == 0xcf and data.len >= 9) {
        const u = std.mem.readInt(u64, data[1..9], .big);
        return std.math.cast(i64, u) orelse TypeError.InvalidHandle;
    }

    // int8: 0xd0
    if (data[0] == 0xd0 and data.len >= 2) return @as(i64, @as(i8, @bitCast(data[1])));

    // int16: 0xd1
    if (data[0] == 0xd1 and data.len >= 3) return @as(i64, std.mem.readInt(i16, data[1..3], .big));

    // int32: 0xd2
    if (data[0] == 0xd2 and data.len >= 5) return @as(i64, std.mem.readInt(i32, data[1..5], .big));

    // int64: 0xd3
    if (data[0] == 0xd3 and data.len >= 9) return std.mem.readInt(i64, data[1..9], .big);

    // Negative fixint: 0xe0..0xff (-32..-1)
    if (data[0] >= 0xe0) return @as(i64, @as(i8, @bitCast(data[0])));

    return TypeError.InvalidHandle;
}

/// Encode an integer handle into a stack buffer. Returns the written slice.
pub fn encodeHandleBuf(handle: i64, buf: *[9]u8) []u8 {
    if (handle >= 0 and handle <= 0x7f) {
        buf[0] = @intCast(handle);
        return buf[0..1];
    } else if (handle >= 0 and handle <= 0xff) {
        buf[0] = 0xcc;
        buf[1] = @intCast(handle);
        return buf[0..2];
    } else if (handle >= 0 and handle <= 0xffff) {
        buf[0] = 0xcd;
        std.mem.writeInt(u16, buf[1..3], @intCast(handle), .big);
        return buf[0..3];
    } else if (handle >= 0 and handle <= 0xffff_ffff) {
        buf[0] = 0xce;
        std.mem.writeInt(u32, buf[1..5], @intCast(handle), .big);
        return buf[0..5];
    } else if (handle >= 0) {
        buf[0] = 0xcf;
        std.mem.writeInt(u64, buf[1..9], @intCast(handle), .big);
        return buf[0..9];
    } else if (handle >= -32) {
        buf[0] = @bitCast(@as(i8, @intCast(handle)));
        return buf[0..1];
    } else if (handle >= -128) {
        buf[0] = 0xd0;
        buf[1] = @bitCast(@as(i8, @intCast(handle)));
        return buf[0..2];
    } else if (handle >= -32768) {
        buf[0] = 0xd1;
        std.mem.writeInt(i16, buf[1..3], @intCast(handle), .big);
        return buf[0..3];
    } else if (handle >= -2147483648) {
        buf[0] = 0xd2;
        std.mem.writeInt(i32, buf[1..5], @intCast(handle), .big);
        return buf[0..5];
    } else {
        buf[0] = 0xd3;
        std.mem.writeInt(i64, buf[1..9], handle, .big);
        return buf[0..9];
    }
}

pub fn encodeHandleAlloc(arena: std.mem.Allocator, handle: i64) ![]u8 {
    var buf: [9]u8 = undefined;
    const slice = encodeHandleBuf(handle, &buf);
    return arena.dupe(u8, slice);
}

const api = @import("api.zig");
pub const Buffer = api.Buffer;
pub const Window = api.Window;
pub const Tabpage = api.Tabpage;

/// Registry of ext type codes received from Neovim during handshake.
pub const ExtTypes = struct {
    buffer_id: i8 = Buffer.default_ext_type,
    window_id: i8 = Window.default_ext_type,
    tabpage_id: i8 = Tabpage.default_ext_type,
};

pub const RemoteObject = union(enum) {
    buffer: Buffer,
    window: Window,
    tabpage: Tabpage,

    pub fn fromExtension(ext: msgpack.MsgPackExtension, types: ExtTypes) TypeError!RemoteObject {
        if (ext.type == types.buffer_id) {
            return .{ .buffer = try Buffer.decode(ext) };
        } else if (ext.type == types.window_id) {
            return .{ .window = try Window.decode(ext) };
        } else if (ext.type == types.tabpage_id) {
            return .{ .tabpage = try Tabpage.decode(ext) };
        } else {
            return TypeError.InvalidExtType;
        }
    }
};

pub const BufferInfo = struct {
    id: i64,
    name: []const u8,
    listed: bool,
    loaded: bool,
    modified: bool,
    hidden: bool,
    line_count: i64,
    cursor_line: i64,
    windows: []const i64,
    last_used: i64,
    filetype: []const u8 = "",
    buftype: []const u8 = "",

    pub fn fromMsgPack(arena: std.mem.Allocator, entries: []const msgpack.MsgPackMapEntry) !BufferInfo {
        const id = getInt(entries, "bufnr", i64, 0);
        const name = getString(entries, "name");
        const listed = getBool(entries, "listed");
        const loaded = getBool(entries, "loaded");
        const modified = getBool(entries, "changed");
        const hidden = getBool(entries, "hidden");
        const line_count = getInt(entries, "linecount", i64, 0);
        const cursor_line = getInt(entries, "lnum", i64, 0);
        const last_used = getInt(entries, "lastused", i64, 0);
        const filetype = getString(entries, "filetype");
        const buftype = getString(entries, "buftype");

        var windows: []const i64 = &.{};
        if (object_util.mapGet(entries, "windows")) |win_obj| {
            if (object_util.asArray(win_obj)) |win_arr| {
                const wins = try arena.alloc(i64, win_arr.len);
                for (win_arr, 0..) |item, i| {
                    wins[i] = object_util.asInt(item, i64) orelse 0;
                }
                windows = wins;
            }
        }

        return .{
            .id = id,
            .name = name,
            .listed = listed,
            .loaded = loaded,
            .modified = modified,
            .hidden = hidden,
            .line_count = line_count,
            .cursor_line = cursor_line,
            .windows = windows,
            .last_used = last_used,
            .filetype = filetype,
            .buftype = buftype,
        };
    }
};

fn getBool(entries: []const msgpack.MsgPackMapEntry, key: []const u8) bool {
    if (object_util.mapGet(entries, key)) |val| {
        if (object_util.asBool(val)) |b| return b;
        if (object_util.asInt(val, i64)) |i| return i != 0;
    }
    return false;
}

fn getInt(entries: []const msgpack.MsgPackMapEntry, key: []const u8, comptime T: type, default: T) T {
    if (object_util.mapGet(entries, key)) |val| {
        if (object_util.asInt(val, T)) |i| return i;
    }
    return default;
}

fn getString(entries: []const msgpack.MsgPackMapEntry, key: []const u8) []const u8 {
    if (object_util.mapGet(entries, key)) |val| {
        if (object_util.asString(val)) |s| return s;
    }
    return "";
}

pub const ListBufInfoOptions = struct {
    buflisted: ?bool = null,
    bufloaded: ?bool = null,
    bufmodified: ?bool = null,
};

// --------------------------------------------------------------------------
// Unit Tests
// --------------------------------------------------------------------------

test "nvim_types: handle encode and decode roundtrip" {
    const test_handles = [_]i64{
        0, 1, 2, 42, 127, 128, 255, 256, 65535, 65536, 1_000_000,
        -1, -16, -32, -33, -128, -129, -32768,
    };

    for (test_handles) |h| {
        var buf: [9]u8 = undefined;
        const encoded = encodeHandleBuf(h, &buf);
        const decoded = try decodeHandle(encoded);
        try std.testing.expectEqual(h, decoded);
    }
}

test "nvim_types: buffer, window, tabpage decode and encode" {
    const allocator = std.testing.allocator;

    var buf_storage = [_]u8{1}; // fixint 1
    const buf_ext = msgpack.MsgPackExtension{
        .type = 0,
        .data = &buf_storage,
    };

    const b = try Buffer.decode(buf_ext);
    try std.testing.expectEqual(@as(i64, 1), b.handle);

    const re_encoded = try b.encode(allocator, 0);
    defer allocator.free(re_encoded.data);
    try std.testing.expectEqual(@as(i8, 0), re_encoded.type);
    try std.testing.expectEqualSlices(u8, &buf_storage, re_encoded.data);

    // RemoteObject mapping
    const types = ExtTypes{};
    const obj = try RemoteObject.fromExtension(buf_ext, types);
    try std.testing.expect(obj == .buffer);
    try std.testing.expectEqual(@as(i64, 1), obj.buffer.handle);
}

test "nvim_types: BufferInfo fromMsgPack" {
    const allocator = std.testing.allocator;

    var name_storage = "src/main.zig".*;
    var ft_storage = "zig".*;
    var bt_storage = "".*;

    var win_items = [_]msgpack.MsgPackObject{
        .{ .integer = 1000 },
        .{ .integer = 1001 },
    };

    const entries = [_]msgpack.MsgPackMapEntry{
        .{ .key = .{ .string = @constCast("bufnr") }, .value = .{ .integer = 42 } },
        .{ .key = .{ .string = @constCast("name") }, .value = .{ .string = &name_storage } },
        .{ .key = .{ .string = @constCast("listed") }, .value = .{ .integer = 1 } },
        .{ .key = .{ .string = @constCast("loaded") }, .value = .{ .integer = 1 } },
        .{ .key = .{ .string = @constCast("changed") }, .value = .{ .integer = 0 } },
        .{ .key = .{ .string = @constCast("hidden") }, .value = .{ .integer = 0 } },
        .{ .key = .{ .string = @constCast("linecount") }, .value = .{ .integer = 120 } },
        .{ .key = .{ .string = @constCast("lnum") }, .value = .{ .integer = 15 } },
        .{ .key = .{ .string = @constCast("lastused") }, .value = .{ .integer = 1726000000 } },
        .{ .key = .{ .string = @constCast("windows") }, .value = .{ .array = &win_items } },
        .{ .key = .{ .string = @constCast("filetype") }, .value = .{ .string = &ft_storage } },
        .{ .key = .{ .string = @constCast("buftype") }, .value = .{ .string = &bt_storage } },
    };

    const info = try BufferInfo.fromMsgPack(allocator, &entries);
    try std.testing.expectEqual(@as(i64, 42), info.id);
    try std.testing.expectEqualStrings("src/main.zig", info.name);
    try std.testing.expect(info.listed);
    try std.testing.expect(info.loaded);
    try std.testing.expect(!info.modified);
    try std.testing.expect(!info.hidden);
    try std.testing.expectEqual(@as(i64, 120), info.line_count);
    try std.testing.expectEqual(@as(i64, 15), info.cursor_line);
    try std.testing.expectEqual(@as(i64, 1726000000), info.last_used);
    try std.testing.expectEqual(@as(usize, 2), info.windows.len);
    try std.testing.expectEqual(@as(i64, 1000), info.windows[0]);
    try std.testing.expectEqual(@as(i64, 1001), info.windows[1]);
    try std.testing.expectEqualStrings("zig", info.filetype);
    try std.testing.expectEqualStrings("", info.buftype);
    allocator.free(info.windows);
}
