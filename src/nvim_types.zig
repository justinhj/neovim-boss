const std = @import("std");
const msgpack = @import("zig_msgpack");

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

/// A remote Neovim Buffer handle.
pub const Buffer = struct {
    handle: i64,

    pub const default_ext_type: i8 = 0;

    pub fn decode(ext: msgpack.MsgPackExtension) TypeError!Buffer {
        return .{ .handle = try decodeHandle(ext.data) };
    }

    pub fn encode(self: Buffer, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackExtension {
        return .{
            .type = ext_type,
            .data = try encodeHandleAlloc(arena, self.handle),
        };
    }

    pub fn toObject(self: Buffer, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackObject {
        return .{ .extension = try self.encode(arena, ext_type) };
    }

    pub fn format(
        self: Buffer,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Buffer({d})", .{self.handle});
    }
};

/// A remote Neovim Window handle.
pub const Window = struct {
    handle: i64,

    pub const default_ext_type: i8 = 1;

    pub fn decode(ext: msgpack.MsgPackExtension) TypeError!Window {
        return .{ .handle = try decodeHandle(ext.data) };
    }

    pub fn encode(self: Window, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackExtension {
        return .{
            .type = ext_type,
            .data = try encodeHandleAlloc(arena, self.handle),
        };
    }

    pub fn toObject(self: Window, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackObject {
        return .{ .extension = try self.encode(arena, ext_type) };
    }

    pub fn format(
        self: Window,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Window({d})", .{self.handle});
    }
};

/// A remote Neovim Tabpage handle.
pub const Tabpage = struct {
    handle: i64,

    pub const default_ext_type: i8 = 2;

    pub fn decode(ext: msgpack.MsgPackExtension) TypeError!Tabpage {
        return .{ .handle = try decodeHandle(ext.data) };
    }

    pub fn encode(self: Tabpage, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackExtension {
        return .{
            .type = ext_type,
            .data = try encodeHandleAlloc(arena, self.handle),
        };
    }

    pub fn toObject(self: Tabpage, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackObject {
        return .{ .extension = try self.encode(arena, ext_type) };
    }

    pub fn format(
        self: Tabpage,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Tabpage({d})", .{self.handle});
    }
};

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
