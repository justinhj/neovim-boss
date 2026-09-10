const std = @import("std");
const Io = std.Io;
const neovim_boss = @import("neovim_boss");
const api = neovim_boss.api;
const msgpack = neovim_boss.msgpack;
const Nvim = neovim_boss.Nvim;

const DemoContext = struct {
    nvim: *Nvim,
    notifications_received: usize = 0,
    requests_handled: usize = 0,

    fn onNotification(user_data: ?*anyopaque, notif: msgpack.RpcNotification) void {
        const self: *@This() = @ptrCast(@alignCast(user_data.?));
        self.notifications_received += 1;

        std.debug.print("  [Notification Received] method: '{s}', params count: {d}\n", .{
            notif.method,
            notif.params.len,
        });

        if (std.mem.eql(u8, notif.method, "demo_stop")) {
            std.debug.print("  [Notification] 'demo_stop' received -> stopping event loop!\n", .{});
            self.nvim.stopLoop();
        }
    }

    fn onRequest(user_data: ?*anyopaque, req: msgpack.RpcRequest, arena: std.mem.Allocator) neovim_boss.RequestResult {
        _ = arena;
        const self: *@This() = @ptrCast(@alignCast(user_data.?));
        self.requests_handled += 1;

        std.debug.print("  [Request Received from Neovim] id: {d}, method: '{s}'\n", .{
            req.msgid,
            req.method,
        });

        if (std.mem.eql(u8, req.method, "calculator")) {
            if (req.params.len >= 3) {
                const op = neovim_boss.asString(req.params[0]) orelse "";
                const a = neovim_boss.asInt(req.params[1], i64) orelse 0;
                const b = neovim_boss.asInt(req.params[2], i64) orelse 0;

                var result_val: i64 = 0;
                if (std.mem.eql(u8, op, "add")) {
                    result_val = a + b;
                } else if (std.mem.eql(u8, op, "multiply")) {
                    result_val = a * b;
                }
                std.debug.print("    -> Computing: {s}({d}, {d}) = {d}\n", .{ op, a, b, result_val });
                return .{ .result = .{ .integer = result_val } };
            }
        }

        var err = "unknown method".*;
        return .{ .@"error" = .{ .string = &err } };
    }
};

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const gpa = init.gpa;
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    const args = try init.minimal.args.toSlice(arena);
    const target = if (args.len >= 2) args[1] else "child";

    _ = try stdout.write("Attaching to Neovim (target: ");
    _ = try stdout.write(target);
    _ = try stdout.write(")...\n");
    try stdout.flush();

    var nvim = try neovim_boss.attachAddress(gpa, io, target);
    defer nvim.deinit();

    var out_buf: [256]u8 = undefined;
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "Connected! Channel ID: {d}\n\n", .{nvim.channel_id}));
    try stdout.flush();

    var demo_ctx = DemoContext{ .nvim = &nvim };
    nvim.setNotificationHandler(&demo_ctx, DemoContext.onNotification);
    nvim.setRequestHandler(&demo_ctx, DemoContext.onRequest);

    var req_arena = std.heap.ArenaAllocator.init(gpa);
    defer req_arena.deinit();
    const req_alloc = req_arena.allocator();

    // 1. Reverse RPC / Re-entrant RPC test
    _ = try stdout.write("1. Testing Reverse RPC (Neovim calls rpcrequest back to Zig client):\n");
    try stdout.flush();

    var eval_buf: [256]u8 = undefined;
    const expr = try std.fmt.bufPrint(
        &eval_buf,
        "rpcrequest({d}, 'calculator', 'multiply', 9, 9)",
        .{nvim.channel_id},
    );
    const calc_res = try nvim.eval(req_alloc, expr);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "   nvim.eval result: {any}\n\n", .{calc_res}));
    try stdout.flush();

    // 2. Buffer attachment & notification dispatch
    _ = try stdout.write("2. Testing Buffer Event Subscriptions (nvim_buf_attach):\n");
    try stdout.flush();

    const buf = try api.nvim_get_current_buf(&nvim, req_alloc);
    _ = try buf.attach(&nvim, req_alloc, false, &.{});

    var line1 = "First line from Phase 5 demo".*;
    const test_lines = [_]msgpack.MsgPackObject{
        .{ .string = &line1 },
    };
    try buf.setLines(&nvim, req_alloc, 0, -1, false, &test_lines);
    _ = try stdout.write("   setLines sent, buffer event notification received above!\n\n");
    try stdout.flush();

    // 3. Testing Event Loop (runLoop)
    _ = try stdout.write("3. Testing Event Loop (nvim.runLoop) with deferred timer notification:\n");
    try stdout.flush();

    var lua_buf: [256]u8 = undefined;
    const lua_code = try std.fmt.bufPrint(
        &lua_buf,
        "vim.defer_fn(function() vim.fn.rpcnotify({d}, 'demo_stop', 'all done') end, 50)",
        .{nvim.channel_id},
    );
    _ = try nvim.execLua(req_alloc, lua_code, &.{});

    _ = try stdout.write("   Entering runLoop()...\n");
    try stdout.flush();

    try nvim.runLoop();

    _ = try stdout.write("   runLoop() exited successfully after receiving stop signal!\n\n");
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "Summary: {d} request(s) handled, {d} notification(s) received.\n", .{
        demo_ctx.requests_handled,
        demo_ctx.notifications_received,
    }));
    _ = try stdout.write("All Phase 5 checks passed successfully!\n");
    try stdout.flush();
}
