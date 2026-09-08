const std = @import("std");
const msgpack = @import("zig_msgpack");
const MsgPackObject = msgpack.MsgPackObject;
const MsgPackMapEntry = msgpack.MsgPackMapEntry;

const Transport = @import("transport.zig").Transport;
const Client = @import("client.zig").Client;
const nvim_types = @import("nvim_types.zig");
const Buffer = nvim_types.Buffer;
const Window = nvim_types.Window;
const Tabpage = nvim_types.Tabpage;
const ExtTypes = nvim_types.ExtTypes;
const object_util = @import("object_util.zig");

pub const NvimError = error{
    HandshakeFailed,
    InvalidApiInfo,
    UnexpectedType,
} || anyerror;

/// Layer 4: Neovim client instance managing RPC handshake, channel state,
/// and user-facing convenience operations.
pub const Nvim = struct {
    allocator: std.mem.Allocator,
    client: Client,
    channel_id: i64 = 0,
    ext_types: ExtTypes = .{},

    pub fn init(allocator: std.mem.Allocator, transport: Transport) NvimError!Nvim {
        var client = try Client.init(allocator, transport);
        errdefer client.deinit();

        var self = Nvim{
            .allocator = allocator,
            .client = client,
        };

        try self.performHandshake();
        return self;
    }

    pub fn deinit(self: *Nvim) void {
        self.client.deinit();
    }

    fn performHandshake(self: *Nvim) !void {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const alloc = arena.allocator();

        // 1. Send nvim_set_client_info notification
        try self.sendClientInfo(alloc);

        // 2. Request nvim_get_api_info -> [channel_id, metadata]
        const api_info_obj = try self.client.request(alloc, "nvim_get_api_info", &.{});

        const arr = object_util.asArray(api_info_obj) orelse return error.InvalidApiInfo;
        if (arr.len < 2) return error.InvalidApiInfo;

        self.channel_id = object_util.asInt(arr[0], i64) orelse return error.InvalidApiInfo;

        if (object_util.asMap(arr[1])) |meta_map| {
            if (object_util.mapGet(meta_map, "types")) |types_obj| {
                if (object_util.asMap(types_obj)) |types_map| {
                    if (extractTypeId(types_map, "Buffer")) |id| {
                        self.ext_types.buffer_id = id;
                    }
                    if (extractTypeId(types_map, "Window")) |id| {
                        self.ext_types.window_id = id;
                    }
                    if (extractTypeId(types_map, "Tabpage")) |id| {
                        self.ext_types.tabpage_id = id;
                    }
                }
            }
        }
    }

    fn extractTypeId(types_map: []const MsgPackMapEntry, type_name: []const u8) ?i8 {
        const type_info_obj = object_util.mapGet(types_map, type_name) orelse return null;
        const type_info_map = object_util.asMap(type_info_obj) orelse return null;
        const id_obj = object_util.mapGet(type_info_map, "id") orelse return null;
        return object_util.asInt(id_obj, i8);
    }

    fn sendClientInfo(self: *Nvim, alloc: std.mem.Allocator) !void {
        // Build version map
        var v_maj_k = "major".*;
        var v_min_k = "minor".*;
        var v_pat_k = "patch".*;
        const version_entries = try alloc.dupe(MsgPackMapEntry, &[_]MsgPackMapEntry{
            .{ .key = .{ .string = &v_maj_k }, .value = .{ .integer = 0 } },
            .{ .key = .{ .string = &v_min_k }, .value = .{ .integer = 0 } },
            .{ .key = .{ .string = &v_pat_k }, .value = .{ .integer = 1 } },
        });

        var name = "neovim-boss".*;
        var client_type = "remote".*;

        const empty_map = try alloc.alloc(MsgPackMapEntry, 0);

        var attr_k = "website".*;
        var attr_v = "https://github.com/justinhj/neovim-boss".*;
        const attr_entries = try alloc.dupe(MsgPackMapEntry, &[_]MsgPackMapEntry{
            .{ .key = .{ .string = &attr_k }, .value = .{ .string = &attr_v } },
        });

        const params = [_]MsgPackObject{
            .{ .string = &name },
            .{ .map = version_entries },
            .{ .string = &client_type },
            .{ .map = empty_map },
            .{ .map = attr_entries },
        };

        try self.client.notify("nvim_set_client_info", &params);
    }

    // ----------------------------------------------------------------------
    // Convenience RPC Methods
    // ----------------------------------------------------------------------

    /// Execute a Vimscript command.
    pub fn command(self: *Nvim, arena: std.mem.Allocator, cmd: []const u8) !void {
        const cmd_mut = try arena.dupe(u8, cmd);
        const params = [_]MsgPackObject{
            .{ .string = cmd_mut },
        };
        _ = try self.client.request(arena, "nvim_command", &params);
    }

    /// Evaluate a Vimscript expression.
    pub fn eval(self: *Nvim, arena: std.mem.Allocator, expr: []const u8) !MsgPackObject {
        const expr_mut = try arena.dupe(u8, expr);
        const params = [_]MsgPackObject{
            .{ .string = expr_mut },
        };
        return try self.client.request(arena, "nvim_eval", &params);
    }

    /// Call a Vimscript / Lua global function with arguments.
    pub fn callFunction(
        self: *Nvim,
        arena: std.mem.Allocator,
        func_name: []const u8,
        args: []const MsgPackObject,
    ) !MsgPackObject {
        const name_mut = try arena.dupe(u8, func_name);
        const args_mut = try arena.dupe(MsgPackObject, args);
        const params = [_]MsgPackObject{
            .{ .string = name_mut },
            .{ .array = args_mut },
        };
        return try self.client.request(arena, "nvim_call_function", &params);
    }

    /// Execute a snippet of Lua code.
    pub fn execLua(
        self: *Nvim,
        arena: std.mem.Allocator,
        code: []const u8,
        args: []const MsgPackObject,
    ) !MsgPackObject {
        const code_mut = try arena.dupe(u8, code);
        const args_mut = try arena.dupe(MsgPackObject, args);
        const params = [_]MsgPackObject{
            .{ .string = code_mut },
            .{ .array = args_mut },
        };
        return try self.client.request(arena, "nvim_exec_lua", &params);
    }

    /// Get the current active Buffer.
    pub fn getCurrentBuf(self: *Nvim, arena: std.mem.Allocator) !Buffer {
        const res = try self.client.request(arena, "nvim_get_current_buf", &.{});
        return switch (res) {
            .extension => |ext| try Buffer.decode(ext),
            else => error.UnexpectedType,
        };
    }

    /// List all open buffers.
    pub fn listBufs(self: *Nvim, arena: std.mem.Allocator) ![]Buffer {
        const res = try self.client.request(arena, "nvim_list_bufs", &.{});
        return switch (res) {
            .array => |arr| {
                const bufs = try arena.alloc(Buffer, arr.len);
                for (arr, 0..) |item, i| {
                    switch (item) {
                        .extension => |ext| bufs[i] = try Buffer.decode(ext),
                        else => return error.UnexpectedType,
                    }
                }
                return bufs;
            },
            else => error.UnexpectedType,
        };
    }
};

// --------------------------------------------------------------------------
// Unit Tests (using in-memory socketpair)
// --------------------------------------------------------------------------

test "nvim: handshake and convenience methods" {
    const allocator = std.testing.allocator;

    var fds: [2]std.posix.fd_t = undefined;
    const rc = std.c.socketpair(std.c.AF.UNIX, std.c.SOCK.STREAM, 0, &fds);
    try std.testing.expectEqual(@as(c_int, 0), rc);

    var server_transport = Transport.fromFd(fds[1]);
    defer server_transport.close();

    // Mock Neovim server thread
    const ServerContext = struct {
        fn run(transport: *Transport) !void {
            var s_unpacker = try msgpack.Unpacker.init(std.testing.allocator, .{});
            defer s_unpacker.deinit();

            var temp_arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer temp_arena.deinit();
            const alloc = temp_arena.allocator();

            // 1. Read notification: nvim_set_client_info
            while (true) {
                var buf: [2048]u8 = undefined;
                const n = try transport.read(&buf);
                try s_unpacker.feed(buf[0..n]);

                if (s_unpacker.nextAlloc(alloc)) |obj| {
                    const msg = try msgpack.rpc.parseMessage(obj);
                    try std.testing.expect(msg == .notification);
                    try std.testing.expectEqualStrings("nvim_set_client_info", msg.notification.method);
                    break;
                } else |_| {}
            }

            // 2. Read request: nvim_get_api_info
            while (true) {
                if (s_unpacker.nextAlloc(alloc)) |obj| {
                    const msg = try msgpack.rpc.parseMessage(obj);
                    switch (msg) {
                        .request => |req| {
                            try std.testing.expectEqualStrings("nvim_get_api_info", req.method);

                            // Send response: [channel_id=3, metadata={types={Buffer={id=0}}}]
                            var k_types = "types".*;
                            var k_buf = "Buffer".*;
                            var k_id = "id".*;

                            var buf_meta = [_]MsgPackMapEntry{
                                .{ .key = .{ .string = &k_id }, .value = .{ .integer = 0 } },
                            };
                            var types_meta = [_]MsgPackMapEntry{
                                .{ .key = .{ .string = &k_buf }, .value = .{ .map = &buf_meta } },
                            };
                            var meta_entries = [_]MsgPackMapEntry{
                                .{ .key = .{ .string = &k_types }, .value = .{ .map = &types_meta } },
                            };

                            var resp_arr = [_]MsgPackObject{
                                .{ .integer = 3 },
                                .{ .map = &meta_entries },
                            };

                            var p = msgpack.Packer.init(alloc);
                            defer p.deinit();
                            try msgpack.rpc.packResponse(&p, req.msgid, null, .{ .array = &resp_arr });
                            try transport.writeAll(p.getSlice());
                            break;
                        },
                        else => unreachable,
                    }
                } else |_| {
                    var buf: [2048]u8 = undefined;
                    const n = try transport.read(&buf);
                    try s_unpacker.feed(buf[0..n]);
                }
            }

            // 3. Read request: nvim_eval("1 + 1")
            while (true) {
                if (s_unpacker.nextAlloc(alloc)) |obj| {
                    const msg = try msgpack.rpc.parseMessage(obj);
                    switch (msg) {
                        .request => |req| {
                            try std.testing.expectEqualStrings("nvim_eval", req.method);

                            var p = msgpack.Packer.init(alloc);
                            defer p.deinit();
                            try msgpack.rpc.packResponse(&p, req.msgid, null, .{ .integer = 2 });
                            try transport.writeAll(p.getSlice());
                            return;
                        },
                        else => unreachable,
                    }
                } else |_| {
                    var buf: [2048]u8 = undefined;
                    const n = try transport.read(&buf);
                    try s_unpacker.feed(buf[0..n]);
                }
            }
        }
    };

    const thread = try std.Thread.spawn(.{}, ServerContext.run, .{&server_transport});

    var nvim = try Nvim.init(allocator, Transport.fromFd(fds[0]));
    defer nvim.deinit();

    try std.testing.expectEqual(@as(i64, 3), nvim.channel_id);
    try std.testing.expectEqual(@as(i8, 0), nvim.ext_types.buffer_id);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const eval_res = try nvim.eval(arena.allocator(), "1 + 1");
    thread.join();

    try std.testing.expectEqual(@as(i64, 2), eval_res.integer);
}
