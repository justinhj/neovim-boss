const std = @import("std");
const Io = std.Io;
const neovim_boss = @import("neovim_boss");
const msgpack = neovim_boss.msgpack;

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const gpa = init.gpa;
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) {
        _ = try stdout.write(
            \\Usage: basic <path-to-nvim-unix-socket>
            \\
            \\Connects to a running Neovim instance via Unix domain socket and calls nvim_eval("2+2").
            \\
            \\Example:
            \\  1. Start Neovim in another terminal:
            \\     nvim --headless --listen /tmp/nvim.sock
            \\  2. Run this example:
            \\     zig build run-basic -- /tmp/nvim.sock
            \\
        );
        try stdout.flush();
        return;
    }

    const socket_path = args[1];

    _ = try stdout.write("Connecting to Neovim at ");
    _ = try stdout.write(socket_path);
    _ = try stdout.write("...\n");
    try stdout.flush();

    const transport = neovim_boss.Transport.connectUnix(io, socket_path) catch |err| {
        std.log.err("Failed to connect to '{s}': {s}", .{ socket_path, @errorName(err) });
        return err;
    };

    var client = try neovim_boss.Client.init(gpa, transport);
    defer client.deinit();

    _ = try stdout.write("Connected successfully!\nSending request: nvim_eval(\"2 + 2\")...\n");
    try stdout.flush();

    var req_arena = std.heap.ArenaAllocator.init(gpa);
    defer req_arena.deinit();
    const req_alloc = req_arena.allocator();

    var expr = "2 + 2".*;
    const params = [_]msgpack.MsgPackObject{
        .{ .string = &expr },
    };

    const result = try client.request(req_alloc, "nvim_eval", &params);

    _ = try stdout.write("Received response: ");
    switch (result) {
        .integer => |i| {
            var buf: [32]u8 = undefined;
            _ = try stdout.write(try std.fmt.bufPrint(&buf, "{d}\n", .{i}));
        },
        .unsigned_integer => |u| {
            var buf: [32]u8 = undefined;
            _ = try stdout.write(try std.fmt.bufPrint(&buf, "{d}\n", .{u}));
        },
        else => {
            _ = try stdout.write("<unexpected result type>\n");
        },
    }
    try stdout.flush();
}
