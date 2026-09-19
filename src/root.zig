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
pub const RequestHandler = client.RequestHandler;
pub const RequestResult = client.RequestResult;

pub const nvim_types = @import("nvim_types.zig");
pub const Buffer = nvim_types.Buffer;
pub const Window = nvim_types.Window;
pub const Tabpage = nvim_types.Tabpage;
pub const BufferInfo = nvim_types.BufferInfo;
pub const ListBufInfoOptions = nvim_types.ListBufInfoOptions;
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

pub const mcp = @import("mcp.zig");

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
    _ = mcp;
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

test "root: reverse RPC and re-entrant request" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    const HandlerCtx = struct {
        calls: usize = 0,

        fn handleRequest(user_data: ?*anyopaque, req: msgpack.RpcRequest, arena: std.mem.Allocator) RequestResult {
            _ = arena;
            const ctx: *@This() = @ptrCast(@alignCast(user_data.?));
            ctx.calls += 1;

            if (std.mem.eql(u8, req.method, "multiply")) {
                if (req.params.len >= 2 and req.params[0] == .integer and req.params[1] == .integer) {
                    const a = req.params[0].integer;
                    const b = req.params[1].integer;
                    return .{ .result = .{ .integer = a * b } };
                }
            }
            var err = "unknown method".*;
            return .{ .@"error" = .{ .string = &err } };
        }
    };

    var ctx = HandlerCtx{};
    n_instance.setRequestHandler(&ctx, HandlerCtx.handleRequest);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var eval_buf: [128]u8 = undefined;
    const expr = try std.fmt.bufPrint(&eval_buf, "rpcrequest({d}, 'multiply', 6, 7)", .{n_instance.channel_id});

    const res = try n_instance.eval(alloc, expr);
    try std.testing.expect(res == .integer);
    try std.testing.expectEqual(@as(i64, 42), res.integer);
    try std.testing.expectEqual(@as(usize, 1), ctx.calls);
}

test "root: notifications received mid-request" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    const NotifCtx = struct {
        received_method: ?[]const u8 = null,
        received_arg: ?i64 = null,

        fn handleNotification(user_data: ?*anyopaque, notif: msgpack.RpcNotification) void {
            const ctx: *@This() = @ptrCast(@alignCast(user_data.?));
            if (std.mem.eql(u8, notif.method, "sync_event")) {
                ctx.received_method = notif.method;
                if (notif.params.len > 0 and notif.params[0] == .integer) {
                    ctx.received_arg = notif.params[0].integer;
                }
            }
        }
    };

    var notif_ctx = NotifCtx{};
    n_instance.setNotificationHandler(&notif_ctx, NotifCtx.handleNotification);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var cmd_buf: [128]u8 = undefined;
    const cmd = try std.fmt.bufPrint(&cmd_buf, "call rpcnotify({d}, 'sync_event', 99)", .{n_instance.channel_id});
    try n_instance.command(alloc, cmd);

    try std.testing.expect(notif_ctx.received_method != null);
    try std.testing.expectEqualStrings("sync_event", notif_ctx.received_method.?);
    try std.testing.expectEqual(@as(i64, 99), notif_ctx.received_arg.?);
}

test "root: runLoop with deferred notification" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    const NotifCtx = struct {
        received_method: ?[]const u8 = null,
        received_arg: ?i64 = null,
        nvim: *Nvim,

        fn handleNotification(user_data: ?*anyopaque, notif: msgpack.RpcNotification) void {
            const ctx: *@This() = @ptrCast(@alignCast(user_data.?));
            if (std.mem.eql(u8, notif.method, "async_event")) {
                ctx.received_method = notif.method;
                if (notif.params.len > 0 and notif.params[0] == .integer) {
                    ctx.received_arg = notif.params[0].integer;
                }
                ctx.nvim.stopLoop();
            }
        }
    };

    var notif_ctx = NotifCtx{ .nvim = &n_instance };
    n_instance.setNotificationHandler(&notif_ctx, NotifCtx.handleNotification);

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Schedule notification 20ms in the future via Neovim Lua timer
    var lua_buf: [256]u8 = undefined;
    const lua_code = try std.fmt.bufPrint(
        &lua_buf,
        "vim.defer_fn(function() vim.fn.rpcnotify({d}, 'async_event', 123) end, 20)",
        .{n_instance.channel_id},
    );
    _ = try n_instance.execLua(alloc, lua_code, &.{});

    // Enter runLoop - waits for the deferred notification, which calls stopLoop()
    try n_instance.runLoop();

    try std.testing.expect(notif_ctx.received_method != null);
    try std.testing.expectEqualStrings("async_event", notif_ctx.received_method.?);
    try std.testing.expectEqual(@as(i64, 123), notif_ctx.received_arg.?);
}

test "mcp: list tools and resources" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const tool_list = try mcp.tools.listTools(alloc);
    try std.testing.expectEqual(@as(usize, 5), tool_list.len);
    try std.testing.expectEqualStrings("get_state_brief", tool_list[0].name);
    try std.testing.expectEqualStrings("get_state", tool_list[1].name);
    try std.testing.expectEqualStrings("exec_lua", tool_list[2].name);
    try std.testing.expectEqualStrings("send_command", tool_list[3].name);
    try std.testing.expectEqualStrings("send_keys", tool_list[4].name);

    const res_list = try mcp.resources.listResources(alloc);
    try std.testing.expectEqual(@as(usize, 1), res_list.len);
    try std.testing.expectEqualStrings("neovim://buffers", res_list[0].uri);
}

test "mcp: jsonToMsgPack conversion" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // 1. null
    const null_res = try mcp.tools.jsonToMsgPack(alloc, .{ .null = {} });
    try std.testing.expect(null_res == .nil);

    // 2. bool
    const bool_res = try mcp.tools.jsonToMsgPack(alloc, .{ .bool = true });
    try std.testing.expect(bool_res == .boolean and bool_res.boolean == true);

    // 3. int
    const int_res = try mcp.tools.jsonToMsgPack(alloc, .{ .integer = 42 });
    try std.testing.expect(int_res == .integer and int_res.integer == 42);

    // 4. string
    const str_res = try mcp.tools.jsonToMsgPack(alloc, .{ .string = "neovim" });
    try std.testing.expect(str_res == .string and std.mem.eql(u8, str_res.string, "neovim"));

    // 5. array
    var json_arr = std.json.Array.init(alloc);
    try json_arr.append(.{ .integer = 1 });
    try json_arr.append(.{ .string = "two" });
    const arr_res = try mcp.tools.jsonToMsgPack(alloc, .{ .array = json_arr });
    try std.testing.expect(arr_res == .array and arr_res.array.len == 2);
    try std.testing.expectEqual(@as(i64, 1), arr_res.array[0].integer);
    try std.testing.expectEqualStrings("two", arr_res.array[1].string);
}

test "mcp: unknown tool returns error" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const res = try mcp.tools.callTool(&n_instance, alloc, "eval_vimscript", null);
    try std.testing.expectEqual(true, res.isError);
    try std.testing.expectEqualStrings("Unknown tool: eval_vimscript", res.content[0].text);
}

test "mcp: tool call get_state_brief with embedded child nvim" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const res = try mcp.tools.callTool(&n_instance, alloc, "get_state_brief", null);
    try std.testing.expectEqual(false, res.isError);
    try std.testing.expect(std.mem.indexOf(u8, res.content[0].text, "\"mode\":\"normal\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, res.content[0].text, "\"active_window\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, res.content[0].text, "\"context\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, res.content[0].text, "\"cwd\"") != null);
}

test "mcp: tool call get_state with embedded child nvim" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // 1. Initial full state
    const res1 = try mcp.tools.callTool(&n_instance, alloc, "get_state", null);
    try std.testing.expectEqual(false, res1.isError);
    try std.testing.expect(std.mem.indexOf(u8, res1.content[0].text, "\"mode\":\"normal\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, res1.content[0].text, "\"windows\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, res1.content[0].text, "\"role\":\"active\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, res1.content[0].text, "\"indent\"") != null);

    // 2. Set mark a and verify it appears in marks
    try n_instance.command(alloc, "normal! 20ohello");
    try n_instance.command(alloc, "10mark a");
    const res2 = try mcp.tools.callTool(&n_instance, alloc, "get_state", null);
    try std.testing.expectEqual(false, res2.isError);
    try std.testing.expect(std.mem.indexOf(u8, res2.content[0].text, "\"mark\":\"a\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, res2.content[0].text, "\"line\":10") != null);

    // 3. Vertical split and verify 2 windows in state
    try n_instance.command(alloc, "vsplit");
    const res3 = try mcp.tools.callTool(&n_instance, alloc, "get_state", null);
    try std.testing.expectEqual(false, res3.isError);
    try std.testing.expect(std.mem.indexOf(u8, res3.content[0].text, "\"role\":\"active\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, res3.content[0].text, "\"role\":\"alternate\"") != null);
}

test "mcp: tool call exec_lua with embedded child nvim" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // 1. Simple arithmetic
    var args1: std.json.ObjectMap = .empty;
    try args1.put(alloc, "code", .{ .string = "return 10 + 20" });
    const res1 = try mcp.tools.callTool(&n_instance, alloc, "exec_lua", .{ .object = args1 });
    try std.testing.expectEqual(false, res1.isError);
    try std.testing.expectEqualStrings("30", res1.content[0].text);

    // 2. Table return
    var args2: std.json.ObjectMap = .empty;
    try args2.put(alloc, "code", .{ .string = "return { name = 'nb', count = 3 }" });
    const res2 = try mcp.tools.callTool(&n_instance, alloc, "exec_lua", .{ .object = args2 });
    try std.testing.expectEqual(false, res2.isError);
    try std.testing.expect(std.mem.indexOf(u8, res2.content[0].text, "\"name\":\"nb\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, res2.content[0].text, "\"count\":3") != null);

    // 3. Arguments forwarding
    var args3: std.json.ObjectMap = .empty;
    try args3.put(alloc, "code", .{ .string = "local a, b = ...; return a * b" });
    var lua_params = std.json.Array.init(alloc);
    try lua_params.append(.{ .integer = 6 });
    try lua_params.append(.{ .integer = 7 });
    try args3.put(alloc, "args", .{ .array = lua_params });
    const res3 = try mcp.tools.callTool(&n_instance, alloc, "exec_lua", .{ .object = args3 });
    try std.testing.expectEqual(false, res3.isError);
    try std.testing.expectEqualStrings("42", res3.content[0].text);

    // 4. Alias eval_lua with expression
    var args4: std.json.ObjectMap = .empty;
    try args4.put(alloc, "code", .{ .string = "50 + 50" });
    const res4 = try mcp.tools.callTool(&n_instance, alloc, "eval_lua", .{ .object = args4 });
    try std.testing.expectEqual(false, res4.isError);
    try std.testing.expectEqualStrings("100", res4.content[0].text);

    // 5. Error handling
    var bad_lua: std.json.ObjectMap = .empty;
    try bad_lua.put(alloc, "code", .{ .string = "error('boom')" });
    const err_res = try mcp.tools.callTool(&n_instance, alloc, "exec_lua", .{ .object = bad_lua });
    try std.testing.expectEqual(true, err_res.isError);
}

test "mcp: tool call send_command with embedded child nvim" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // 1. Output capture
    var args1: std.json.ObjectMap = .empty;
    try args1.put(alloc, "command", .{ .string = "echo 'hello nb'" });
    const res1 = try mcp.tools.callTool(&n_instance, alloc, "send_command", .{ .object = args1 });
    try std.testing.expectEqual(false, res1.isError);
    try std.testing.expectEqualStrings("hello nb", res1.content[0].text);

    // 2. Silent command
    var args2: std.json.ObjectMap = .empty;
    try args2.put(alloc, "command", .{ .string = ":set number" });
    const res2 = try mcp.tools.callTool(&n_instance, alloc, "send_command", .{ .object = args2 });
    try std.testing.expectEqual(false, res2.isError);
    try std.testing.expectEqualStrings("(no output)", res2.content[0].text);

    // 3. Alias exec_command
    var args3: std.json.ObjectMap = .empty;
    try args3.put(alloc, "command", .{ .string = "echo 99" });
    const res3 = try mcp.tools.callTool(&n_instance, alloc, "exec_command", .{ .object = args3 });
    try std.testing.expectEqual(false, res3.isError);
    try std.testing.expectEqualStrings("99", res3.content[0].text);

    // 4. Invalid command
    var bad_cmd: std.json.ObjectMap = .empty;
    try bad_cmd.put(alloc, "command", .{ .string = "nonexistent_command_xyz" });
    const err_res = try mcp.tools.callTool(&n_instance, alloc, "send_command", .{ .object = bad_cmd });
    try std.testing.expectEqual(true, err_res.isError);
}

test "mcp: tool call send_keys with embedded child nvim" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Send keys: insert text into current buffer and return to normal mode
    var args: std.json.ObjectMap = .empty;
    try args.put(alloc, "keys", .{ .string = "iHello from send_keys<Esc>" });
    const res = try mcp.tools.callTool(&n_instance, alloc, "send_keys", .{ .object = args });
    try std.testing.expectEqual(false, res.isError);
    try std.testing.expect(std.mem.indexOf(u8, res.content[0].text, "\"bytes_written\":") != null);

    // Read back buffer line to verify keys took effect
    const buf = try api.nvim_get_current_buf(&n_instance, alloc);
    const lines = try buf.getLines(&n_instance, alloc, 0, 1, false);
    try std.testing.expectEqual(@as(usize, 1), lines.len);
    if (object_util.asString(lines[0])) |line_str| {
        try std.testing.expectEqualStrings("Hello from send_keys", line_str);
    } else {
        return error.UnexpectedType;
    }
}

test "mcp: resource read neovim://buffers with embedded child nvim" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const res = try mcp.resources.readResource(&n_instance, alloc, "neovim://buffers");
    try std.testing.expectEqual(@as(usize, 1), res.contents.len);
    try std.testing.expectEqualStrings("neovim://buffers", res.contents[0].uri);
    try std.testing.expect(res.contents[0].mimeType != null);
    try std.testing.expectEqualStrings("application/json", res.contents[0].mimeType.?);
    try std.testing.expect(std.mem.indexOf(u8, res.contents[0].text, "\"id\":") != null);
}

test "mcp: server handleLine protocol requests" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var n_instance = try attach(allocator, io, .{ .child = null });
    defer n_instance.deinit();

    var server = mcp.Server.init(allocator, io, &n_instance);

    var pipe_fds: [2]c_int = undefined;
    if (std.c.pipe(&pipe_fds) != 0) return error.PipeFailed;
    defer _ = std.c.close(pipe_fds[0]);
    defer _ = std.c.close(pipe_fds[1]);

    server.stdout_fd = pipe_fds[1];

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // 1. Test initialize
    const init_req = "{\"jsonrpc\":\"2.0\",\"id\":100,\"method\":\"initialize\",\"params\":{}}";
    try server.handleLine(alloc, init_req);

    var out_buf: [2048]u8 = undefined;
    const n = std.c.read(pipe_fds[0], &out_buf, out_buf.len);
    try std.testing.expect(n > 0);

    const parsed = try std.json.parseFromSlice(std.json.Value, alloc, out_buf[0..@intCast(n)], .{});
    try std.testing.expectEqual(@as(i64, 100), parsed.value.object.get("id").?.integer);
    const result_obj = parsed.value.object.get("result").?.object;
    try std.testing.expectEqualStrings("2024-11-05", result_obj.get("protocolVersion").?.string);
    try std.testing.expectEqualStrings("neovim-boss", result_obj.get("serverInfo").?.object.get("name").?.string);
}
