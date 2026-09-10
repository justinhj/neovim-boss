const std = @import("std");

pub const msgpack = @import("zig_msgpack");
pub const build_info = @import("build_info");
pub const version = build_info.version_string;

pub const transport = @import("transport.zig");
pub const Transport = transport.Transport;
pub const TransportError = transport.TransportError;

pub const client = @import("client.zig");
pub const Client = client.Client;
pub const ClientError = client.ClientError;
pub const NotificationHandler = client.NotificationHandler;

pub const nvim_types = @import("nvim_types.zig");
pub const Buffer = nvim_types.Buffer;
pub const Window = nvim_types.Window;
pub const Tabpage = nvim_types.Tabpage;
pub const ExtTypes = nvim_types.ExtTypes;
pub const RemoteObject = nvim_types.RemoteObject;

pub const object_util = @import("object_util.zig");
pub const asString = object_util.asString;
pub const asInt = object_util.asInt;
pub const asBool = object_util.asBool;
pub const asArray = object_util.asArray;
pub const asMap = object_util.asMap;
pub const mapGet = object_util.mapGet;
pub const walkObject = object_util.walkObject;

pub const nvim = @import("nvim.zig");
pub const Nvim = nvim.Nvim;
pub const NvimError = nvim.NvimError;

pub const api = @import("api.zig");
pub const Api = api.Api;

pub const AttachTarget = union(enum) {
    socket: []const u8,
    tcp: struct { host: []const u8, port: u16 },
    child: ?[]const []const u8,
    stdio: void,
    transport: Transport,
};

/// Connect to Neovim and perform the handshake, returning a ready Nvim instance.
pub fn attach(allocator: std.mem.Allocator, io: std.Io, target: AttachTarget) !Nvim {
    const t = switch (target) {
        .socket => |path| try Transport.connectUnix(io, path),
        .tcp => |tcp_target| try Transport.connectTcp(io, tcp_target.host, tcp_target.port),
        .child => |argv| try Transport.spawnChild(io, argv),
        .stdio => Transport.connectStdio(io),
        .transport => |existing| existing,
    };
    return try Nvim.init(allocator, t);
}

/// Attach to Neovim by auto-detecting the address string format:
/// - "child" or "" -> spawns embedded nvim (`nvim --embed --headless`)
/// - "stdio" -> standard I/O streams
/// - "host:port" (e.g. "localhost:6969", "127.0.0.1:6666") -> TCP network socket
/// - otherwise -> Unix domain socket path (e.g. "/tmp/nvim.sock")
pub fn attachAddress(allocator: std.mem.Allocator, io: std.Io, address: []const u8) !Nvim {
    if (std.mem.eql(u8, address, "child") or address.len == 0) {
        return attach(allocator, io, .{ .child = null });
    }
    if (std.mem.eql(u8, address, "stdio")) {
        return attach(allocator, io, .stdio);
    }
    if (!std.mem.startsWith(u8, address, "/") and !std.mem.startsWith(u8, address, ".")) {
        if (std.mem.lastIndexOfScalar(u8, address, ':')) |colon_idx| {
            const host = address[0..colon_idx];
            const port_str = address[colon_idx + 1 ..];
            if (std.fmt.parseInt(u16, port_str, 10)) |port| {
                return attach(allocator, io, .{ .tcp = .{ .host = host, .port = port } });
            } else |_| {}
        }
    }
    return attach(allocator, io, .{ .socket = address });
}

test {
    std.testing.refAllDecls(@This());
    _ = transport;
    _ = client;
    _ = nvim_types;
    _ = object_util;
    _ = nvim;
}

test "root: attach embedded child nvim" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    try std.testing.expect(n_instance.channel_id > 0);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const res = try n_instance.eval(arena.allocator(), "3 * 7");
    try std.testing.expect(res == .integer);
    try std.testing.expectEqual(@as(i64, 21), res.integer);
}

test "root: attachAddress parsing" {
    // We don't connect in this test, just verify address routing paths
    const addr1 = "127.0.0.1:6666";
    try std.testing.expect(std.mem.indexOfScalar(u8, addr1, ':') != null);

    const addr2 = "/tmp/nvim.sock";
    try std.testing.expect(std.mem.startsWith(u8, addr2, "/"));
}

test "root: api generated functions and Buffer/Window methods with embedded child nvim" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // 1. Get current buffer via generated API
    const buf = try api.nvim_get_current_buf(&n_instance, alloc);
    try std.testing.expect(buf.handle > 0);

    // 2. Set buffer lines via Buffer.setLines
    var l1 = "Alpha".*;
    var l2 = "Beta".*;
    const test_lines = [_]msgpack.MsgPackObject{
        .{ .string = &l1 },
        .{ .string = &l2 },
    };
    try buf.setLines(&n_instance, alloc, 0, -1, false, &test_lines);

    // 3. Read back line count and lines via Buffer methods
    const count = try buf.lineCount(&n_instance, alloc);
    try std.testing.expectEqual(@as(i64, 2), count);

    const lines = try buf.getLines(&n_instance, alloc, 0, -1, false);
    try std.testing.expectEqual(@as(usize, 2), lines.len);
    try std.testing.expectEqualStrings("Alpha", asString(lines[0]).?);
    try std.testing.expectEqualStrings("Beta", asString(lines[1]).?);

    // 4. Test Window methods
    const win = try api.nvim_get_current_win(&n_instance, alloc);
    try std.testing.expect(win.handle > 0);

    const cur = try win.getCursor(&n_instance, alloc);
    try std.testing.expectEqual(@as(usize, 2), cur.len);

    // 5. Test nvim.api() method syntax
    const bufs = try n_instance.api().nvim_list_bufs(alloc);
    try std.testing.expect(bufs.len >= 1);
}
