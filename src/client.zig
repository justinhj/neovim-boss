const std = @import("std");
const msgpack = @import("zig_msgpack");
const Transport = @import("transport.zig").Transport;
const TransportError = @import("transport.zig").TransportError;

pub const ClientError = anyerror;

pub const NotificationHandler = *const fn (user_data: ?*anyopaque, notification: msgpack.RpcNotification) void;

/// Layer 3: RPC Client tracking message IDs, sending blocking requests,
/// and dispatching notifications.
pub const Client = struct {
    allocator: std.mem.Allocator,
    transport: Transport,
    session: msgpack.RpcSession,
    unpacker: msgpack.Unpacker,

    last_error_message: ?[]u8 = null,
    notification_handler: ?NotificationHandler = null,
    notification_user_data: ?*anyopaque = null,

    pub fn init(allocator: std.mem.Allocator, transport: Transport) !Client {
        const session = msgpack.RpcSession.init(allocator);
        const unpacker = try msgpack.Unpacker.init(allocator, .{});

        return .{
            .allocator = allocator,
            .transport = transport,
            .session = session,
            .unpacker = unpacker,
        };
    }

    pub fn deinit(self: *Client) void {
        self.transport.close();
        self.unpacker.deinit();
        self.session.deinit();
        if (self.last_error_message) |msg| {
            self.allocator.free(msg);
            self.last_error_message = null;
        }
    }

    /// Set an optional callback to handle RPC notifications received mid-wait.
    pub fn setNotificationHandler(
        self: *Client,
        user_data: ?*anyopaque,
        handler: ?NotificationHandler,
    ) void {
        self.notification_user_data = user_data;
        self.notification_handler = handler;
    }

    /// Retrieve the error message from the most recent RPC error response, if available.
    pub fn lastError(self: *const Client) ?[]const u8 {
        return self.last_error_message;
    }

    /// Send a fire-and-forget notification to Neovim.
    pub fn notify(
        self: *Client,
        method: []const u8,
        params: []const msgpack.MsgPackObject,
    ) ClientError!void {
        var p = msgpack.Packer.init(self.allocator);
        defer p.deinit();

        try msgpack.rpc.packNotification(&p, method, params);
        try self.transport.writeAll(p.getSlice());
    }

    /// Poll for an already-buffered message from the unpacker stream.
    /// Returns null if more bytes are needed from the transport.
    pub fn poll(self: *Client, arena: std.mem.Allocator) ClientError!?msgpack.RpcMessage {
        const obj = self.unpacker.nextAlloc(arena) catch |err| switch (err) {
            error.Incomplete, error.NoMessage => return null,
            else => return err,
        };
        const msg = try msgpack.rpc.parseMessage(obj);
        return msg;
    }

    /// Send an RPC request, blocking until the matching response arrives.
    /// Notifications received mid-wait are dispatched to notification_handler.
    /// Memory for the returned MsgPackObject tree is allocated from `arena`.
    pub fn request(
        self: *Client,
        arena: std.mem.Allocator,
        method: []const u8,
        params: []const msgpack.MsgPackObject,
    ) ClientError!msgpack.MsgPackObject {
        var p = msgpack.Packer.init(arena);
        defer p.deinit();

        const msgid = try self.session.packRequest(&p, method, params);
        try self.transport.writeAll(p.getSlice());

        var read_buf: [4096]u8 = undefined;

        while (true) {
            // First drain any messages already unpacked or ready in the buffer
            if (try self.poll(arena)) |msg| {
                switch (msg) {
                    .response => |res| {
                        if (res.msgid == msgid) {
                            if (res.@"error") |err_obj| {
                                self.setLastError(err_obj);
                                return error.RpcError;
                            }
                            return res.result orelse .nil;
                        }
                        // Non-matching response ID (stale or interleaved), skip
                    },
                    .notification => |notif| {
                        if (self.notification_handler) |handler| {
                            handler(self.notification_user_data, notif);
                        }
                    },
                    .request => {
                        // Reverse RPC request (handling deferred to Phase 5)
                    },
                }
            } else {
                // Buffer needs more data from transport
                const n = try self.transport.read(&read_buf);
                if (n == 0) return error.EndOfStream;
                try self.unpacker.feed(read_buf[0..n]);
            }
        }
    }

    fn setLastError(self: *Client, err_obj: msgpack.MsgPackObject) void {
        if (self.last_error_message) |msg| {
            self.allocator.free(msg);
            self.last_error_message = null;
        }

        switch (err_obj) {
            .string => |s| {
                self.last_error_message = self.allocator.dupe(u8, s) catch null;
            },
            .array => |arr| {
                if (arr.len >= 2 and arr[1] == .string) {
                    self.last_error_message = self.allocator.dupe(u8, arr[1].string) catch null;
                } else if (arr.len >= 1 and arr[0] == .string) {
                    self.last_error_message = self.allocator.dupe(u8, arr[0].string) catch null;
                }
            },
            else => {},
        }
    }
};

// --------------------------------------------------------------------------
// Unit Tests (using in-memory socketpair)
// --------------------------------------------------------------------------

test "client: roundtrip request and response" {
    const allocator = std.testing.allocator;

    var fds: [2]std.posix.fd_t = undefined;
    const rc = std.c.socketpair(std.c.AF.UNIX, std.c.SOCK.STREAM, 0, &fds);
    try std.testing.expectEqual(@as(c_int, 0), rc);

    var client = try Client.init(allocator, Transport.fromFd(fds[0]));
    defer client.deinit();

    var server_transport = Transport.fromFd(fds[1]);
    defer server_transport.close();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    // Server thread to respond to the request
    const ServerContext = struct {
        fn run(transport: *Transport) !void {
            var s_unpacker = try msgpack.Unpacker.init(std.testing.allocator, .{});
            defer s_unpacker.deinit();

            var buf: [1024]u8 = undefined;
            const n = try transport.read(&buf);
            try s_unpacker.feed(buf[0..n]);

            var temp_arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer temp_arena.deinit();
            const temp_alloc = temp_arena.allocator();

            const obj = try s_unpacker.nextAlloc(temp_alloc);
            const msg = try msgpack.rpc.parseMessage(obj);

            switch (msg) {
                .request => |req| {
                    try std.testing.expectEqualStrings("nvim_eval", req.method);
                    // Send back response with result = 4
                    var p = msgpack.Packer.init(temp_alloc);
                    defer p.deinit();
                    try msgpack.rpc.packResponse(&p, req.msgid, null, .{ .integer = 4 });
                    try transport.writeAll(p.getSlice());
                },
                else => unreachable,
            }
        }
    };

    const thread = try std.Thread.spawn(.{}, ServerContext.run, .{&server_transport});

    var expr = "2 + 2".*;
    const params = [_]msgpack.MsgPackObject{
        .{ .string = &expr },
    };

    const result = try client.request(arena_alloc, "nvim_eval", &params);
    thread.join();

    try std.testing.expect(result == .integer);
    try std.testing.expectEqual(@as(i64, 4), result.integer);
}

test "client: notification dispatch mid-wait" {
    const allocator = std.testing.allocator;

    var fds: [2]std.posix.fd_t = undefined;
    const rc = std.c.socketpair(std.c.AF.UNIX, std.c.SOCK.STREAM, 0, &fds);
    try std.testing.expectEqual(@as(c_int, 0), rc);

    var client = try Client.init(allocator, Transport.fromFd(fds[0]));
    defer client.deinit();

    var server_transport = Transport.fromFd(fds[1]);
    defer server_transport.close();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    var notif_received = false;
    const Handler = struct {
        fn onNotification(ud: ?*anyopaque, notif: msgpack.RpcNotification) void {
            const received_ptr: *bool = @ptrCast(@alignCast(ud.?));
            if (std.mem.eql(u8, notif.method, "test_event")) {
                received_ptr.* = true;
            }
        }
    };

    client.setNotificationHandler(&notif_received, Handler.onNotification);

    // Server sends a notification first, then the response
    const ServerContext = struct {
        fn run(transport: *Transport) !void {
            var s_unpacker = try msgpack.Unpacker.init(std.testing.allocator, .{});
            defer s_unpacker.deinit();

            var buf: [1024]u8 = undefined;
            const n = try transport.read(&buf);
            try s_unpacker.feed(buf[0..n]);

            var temp_arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer temp_arena.deinit();
            const temp_alloc = temp_arena.allocator();

            const obj = try s_unpacker.nextAlloc(temp_alloc);
            const msg = try msgpack.rpc.parseMessage(obj);

            switch (msg) {
                .request => |req| {
                    var p = msgpack.Packer.init(temp_alloc);
                    defer p.deinit();

                    // 1. Pack and send notification
                    try msgpack.rpc.packNotification(&p, "test_event", &.{});
                    try transport.writeAll(p.getSlice());

                    // 2. Pack and send response
                    var p2 = msgpack.Packer.init(temp_alloc);
                    defer p2.deinit();
                    try msgpack.rpc.packResponse(&p2, req.msgid, null, .{ .boolean = true });
                    try transport.writeAll(p2.getSlice());
                },
                else => unreachable,
            }
        }
    };

    const thread = try std.Thread.spawn(.{}, ServerContext.run, .{&server_transport});

    const result = try client.request(arena_alloc, "test_req", &.{});
    thread.join();

    try std.testing.expect(notif_received);
    try std.testing.expect(result == .boolean);
    try std.testing.expectEqual(true, result.boolean);
}

test "client: rpc error response handling" {
    const allocator = std.testing.allocator;

    var fds: [2]std.posix.fd_t = undefined;
    const rc = std.c.socketpair(std.c.AF.UNIX, std.c.SOCK.STREAM, 0, &fds);
    try std.testing.expectEqual(@as(c_int, 0), rc);

    var client = try Client.init(allocator, Transport.fromFd(fds[0]));
    defer client.deinit();

    var server_transport = Transport.fromFd(fds[1]);
    defer server_transport.close();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const ServerContext = struct {
        fn run(transport: *Transport) !void {
            var s_unpacker = try msgpack.Unpacker.init(std.testing.allocator, .{});
            defer s_unpacker.deinit();

            var buf: [1024]u8 = undefined;
            const n = try transport.read(&buf);
            try s_unpacker.feed(buf[0..n]);

            var temp_arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer temp_arena.deinit();
            const temp_alloc = temp_arena.allocator();

            const obj = try s_unpacker.nextAlloc(temp_alloc);
            const msg = try msgpack.rpc.parseMessage(obj);

            switch (msg) {
                .request => |req| {
                    var p = msgpack.Packer.init(temp_alloc);
                    defer p.deinit();

                    // Neovim error format: [error_type, "error message"]
                    var err_msg = "Invalid function call".*;
                    var err_items = [_]msgpack.MsgPackObject{
                        .{ .integer = 1 },
                        .{ .string = &err_msg },
                    };
                    const err_obj = msgpack.MsgPackObject{ .array = &err_items };

                    try msgpack.rpc.packResponse(&p, req.msgid, err_obj, null);
                    try transport.writeAll(p.getSlice());
                },
                else => unreachable,
            }
        }
    };

    const thread = try std.Thread.spawn(.{}, ServerContext.run, .{&server_transport});

    const err = client.request(arena_alloc, "bad_call", &.{});
    thread.join();

    try std.testing.expectError(error.RpcError, err);
    try std.testing.expect(client.lastError() != null);
    try std.testing.expectEqualStrings("Invalid function call", client.lastError().?);
}
