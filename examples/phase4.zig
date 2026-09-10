const std = @import("std");
const Io = std.Io;
const neovim_boss = @import("neovim_boss");
const api = neovim_boss.api;
const msgpack = neovim_boss.msgpack;

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const gpa = init.gpa;
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;

    const args = try init.minimal.args.toSlice(arena);
    const target = if (args.len >= 2) args[1] else "child";

    _ = try stdout.write("Attaching to Neovim target: ");
    _ = try stdout.write(target);
    _ = try stdout.write("...\n");
    try stdout.flush();

    var nvim = try neovim_boss.attachAddress(gpa, io, target);
    defer nvim.deinit();

    var out_buf: [256]u8 = undefined;
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "Connected! Channel ID: {d}\n\n", .{nvim.channel_id}));
    try stdout.flush();

    var req_arena = std.heap.ArenaAllocator.init(gpa);
    defer req_arena.deinit();
    const req_alloc = req_arena.allocator();

    // 1. Get current buffer using generated API
    const current_buf = try api.nvim_get_current_buf(&nvim, req_alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "1. nvim_get_current_buf -> {any}\n", .{current_buf}));

    // 2. Buffer methods: setLines and getLines
    var line1 = "Line 1: Hello from neovim-boss Phase 4!".*;
    var line2 = "Line 2: Generated typed Neovim API in Zig 0.16".*;
    var line3 = "Line 3: Strongly-typed wrappers for 260+ functions".*;
    const new_lines = [_]msgpack.MsgPackObject{
        .{ .string = &line1 },
        .{ .string = &line2 },
        .{ .string = &line3 },
    };

    try current_buf.setLines(&nvim, req_alloc, 0, -1, false, &new_lines);
    _ = try stdout.write("2. current_buf.setLines(...) -> OK\n");

    const line_count = try current_buf.lineCount(&nvim, req_alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "   current_buf.lineCount() -> {d}\n", .{line_count}));

    const lines = try current_buf.getLines(&nvim, req_alloc, 0, -1, false);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "   current_buf.getLines() -> read {d} line(s):\n", .{lines.len}));
    for (lines, 0..) |l, i| {
        if (neovim_boss.asString(l)) |str| {
            _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "     [{d}] {s}\n", .{ i, str }));
        }
    }

    // 3. Window methods: getCursor, setCursor
    const current_win = try api.nvim_get_current_win(&nvim, req_alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "\n3. nvim_get_current_win -> {any}\n", .{current_win}));

    const initial_cursor = try current_win.getCursor(&nvim, req_alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "   current_win.getCursor() initial -> {any}\n", .{initial_cursor}));

    // Move cursor to row 2, col 5
    const target_pos = [_]msgpack.MsgPackObject{
        .{ .integer = 2 },
        .{ .integer = 5 },
    };
    try current_win.setCursor(&nvim, req_alloc, &target_pos);
    const updated_cursor = try current_win.getCursor(&nvim, req_alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "   current_win.setCursor(2, 5) -> new pos: {any}\n", .{updated_cursor}));

    // 4. Tabpage methods: listWins
    const current_tab = try api.nvim_get_current_tabpage(&nvim, req_alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "\n4. nvim_get_current_tabpage -> {any}\n", .{current_tab}));
    const tab_wins = try current_tab.listWins(&nvim, req_alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "   current_tab.listWins() -> found {d} window(s): {any}\n", .{ tab_wins.len, tab_wins }));

    // 5. Nvim.api() method syntax
    const bufs = try nvim.api().nvim_list_bufs(req_alloc);
    _ = try stdout.write(try std.fmt.bufPrint(&out_buf, "\n5. nvim.api().nvim_list_bufs() -> found {d} buffer(s)\n", .{bufs.len}));

    _ = try stdout.write("\nAll Phase 4 checks completed successfully!\n");
    try stdout.flush();
}
