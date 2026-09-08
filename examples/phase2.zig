const std = @import("std");
const Io = std.Io;
const neovim_boss = @import("neovim_boss");
const Nvim = neovim_boss.Nvim;

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
            \\Usage: phase2 <path-to-nvim-unix-socket>
            \\
            \\Connects to a running Neovim instance, performs handshake via Nvim.init(),
            \\and demonstrates convenience methods and Buffer ext types.
            \\
            \\Example:
            \\  1. In another terminal:
            \\     nvim --headless --listen /tmp/nvim.sock
            \\  2. Run this demo:
            \\     zig build run-phase2 -- /tmp/nvim.sock
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

    const transport = try neovim_boss.Transport.connectUnix(io, socket_path);
    var nvim = try Nvim.init(gpa, transport);
    defer nvim.deinit();

    var out_buf: [128]u8 = undefined;
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "Connected! Channel ID: {d}\n", .{nvim.channel_id}));
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "Ext Types registered: Buffer={d}, Window={d}, Tabpage={d}\n\n", .{
        nvim.ext_types.buffer_id,
        nvim.ext_types.window_id,
        nvim.ext_types.tabpage_id,
    }));
    try stdout.flush();

    var req_arena = std.heap.ArenaAllocator.init(gpa);
    defer req_arena.deinit();
    const req_alloc = req_arena.allocator();

    // 1. Eval
    const eval_res = try nvim.eval(req_alloc, "21 * 2");
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "1. nvim.eval(\"21 * 2\") -> {any}\n", .{eval_res}));

    // 2. Command
    try nvim.command(req_alloc, "let g:nb_greeting = 'Hello from neovim-boss!'");
    _ = try stdout.write("2. nvim.command(\"let g:nb_greeting = ...\") -> OK\n");

    const greeting = try nvim.eval(req_alloc, "g:nb_greeting");
    if (neovim_boss.asString(greeting)) |str| {
        _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "   Verified variable: {s}\n", .{str}));
    }

    // 3. Get Current Buffer (Ext type decode)
    const current_buf = try nvim.getCurrentBuf(req_alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "3. nvim.getCurrentBuf() -> {any}\n", .{current_buf}));

    // 4. List Buffers
    const bufs = try nvim.listBufs(req_alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "4. nvim.listBufs() -> found {d} buffer(s): ", .{bufs.len}));
    for (bufs, 0..) |buf, i| {
        if (i > 0) _ = try stdout.write(", ");
        _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "{any}", .{buf}));
    }
    _ = try stdout.write("\n\nAll Phase 2 checks passed successfully!\n");
    try stdout.flush();
}
