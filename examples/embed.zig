const std = @import("std");
const Io = std.Io;
const neovim_boss = @import("neovim_boss");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    _ = try stdout.write("Spawning embedded Neovim (nvim --embed --headless)...\n");
    try stdout.flush();

    var nvim = try neovim_boss.attach(gpa, io, .{ .child = null });
    defer nvim.deinit();

    var out_buf: [128]u8 = undefined;
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "Connected! Channel ID: {d}\n", .{nvim.channel_id}));
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "Discovered types: Buffer={d}, Window={d}, Tabpage={d}\n\n", .{
        nvim.ext_types.buffer_id,
        nvim.ext_types.window_id,
        nvim.ext_types.tabpage_id,
    }));
    try stdout.flush();

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const alloc = arena.allocator();

    // 1. Evaluate expression
    const eval_res = try nvim.eval(alloc, "'Embedded Neovim version: ' . v:version");
    if (neovim_boss.asString(eval_res)) |str| {
        _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "1. nvim.eval: {s}\n", .{str}));
    }

    // 2. Set buffer lines via Vimscript command
    try nvim.command(alloc, "call setline(1, ['Hello from Zig!', 'Embedded Neovim RPC works!'])");
    _ = try stdout.write("2. nvim.command: Added lines to current buffer\n");

    // 3. Inspect current buffer
    const buf = try nvim.getCurrentBuf(alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "3. Current buffer: {any}\n", .{buf}));

    // 4. Read back buffer lines using eval
    const lines = try nvim.eval(alloc, "getline(1, '$')");
    _ = try stdout.write("4. Buffer contents: [");
    if (neovim_boss.asArray(lines)) |arr| {
        for (arr, 0..) |item, i| {
            if (i > 0) _ = try stdout.write(", ");
            if (neovim_boss.asString(item)) |s| {
                _ = try stdout.write("\"");
                _ = try stdout.write(s);
                _ = try stdout.write("\"");
            }
        }
    }
    _ = try stdout.write("]\n\nEmbedded session finished successfully!\n");
    try stdout.flush();
}
