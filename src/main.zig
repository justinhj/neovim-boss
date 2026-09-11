const std = @import("std");
const Io = std.Io;

const neovim_boss = @import("neovim_boss");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const io = init.io;

    if (args.len >= 2 and std.mem.eql(u8, args[1], "mcp")) {
        const maybe_target: ?[]const u8 = if (args.len >= 3)
            args[2]
        else if (init.environ_map.get("NVIM")) |nvim_env|
            if (nvim_env.len > 0) nvim_env else null
        else
            null;

        const target = maybe_target orelse {
            std.debug.print(
                \\Usage: nb mcp [listener]
                \\
                \\Runs the neovim-boss Model Context Protocol (MCP) server over stdio.
                \\
                \\Supported listeners:
                \\  /path/to/socket    Unix domain socket (e.g. /tmp/nvim.sock)
                \\  host:port          TCP socket (e.g. 127.0.0.1:6666)
                \\  child              Embedded headless Neovim child process
                \\  stdio              Standard I/O Neovim process
                \\
                \\If no listener is provided, the $NVIM environment variable is used if set.
                \\
            , .{});
            return;
        };

        var nvim = neovim_boss.attachAddress(arena, io, target) catch |err| {
            std.debug.print("Failed to connect to Neovim at '{s}': {s}\n", .{ target, @errorName(err) });
            return err;
        };
        defer nvim.deinit();

        try neovim_boss.mcp.run(arena, io, &nvim);
        return;
    }

    std.debug.print(
        \\neovim-boss (nb) {s} - Neovim control plane for humans and AI
        \\
        \\Usage:
        \\  nb mcp [listener]    Start the MCP server over stdio
        \\
    , .{neovim_boss.version});
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa);
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
