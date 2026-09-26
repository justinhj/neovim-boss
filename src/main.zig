const std = @import("std");
const Io = std.Io;

const neovim_boss = @import("neovim_boss");

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const io = init.io;

    if (args.len >= 2 and (std.mem.eql(u8, args[1], "detect") or std.mem.eql(u8, args[1], "--detect"))) {
        const target_dir = if (args.len >= 3)
            args[2]
        else
            try std.process.currentPathAlloc(io, arena);

        const git_root = neovim_boss.findGitRoot(io, arena, target_dir);

        std.debug.print("Detecting Neovim instances for:\n  Directory: {s}\n", .{target_dir});
        if (git_root) |gr| {
            std.debug.print("  Git Root:  {s}\n", .{gr});
        }
        std.debug.print("\n", .{});

        var disc = try neovim_boss.findBestMatch(arena, io, target_dir);
        defer disc.deinit(arena);

        if (disc.best_match) |match| {
            std.debug.print("✓ MATCH FOUND ({s}):\n", .{match.match_score.label()});
            std.debug.print("    Socket:       {s}\n", .{match.socket_path});
            std.debug.print("    PID:          {d}\n", .{match.pid});
            std.debug.print("    CWD:          {s}\n", .{match.cwd});
            if (match.current_file.len > 0) {
                std.debug.print("    Active File:  {s}\n", .{match.current_file});
            }
            if (match.server_name.len > 0) {
                std.debug.print("    Server Name:  {s}\n", .{match.server_name});
            }
        } else {
            std.debug.print("✗ No matching Neovim instance found for this project.\n", .{});
        }

        if (disc.all_instances.len > 0) {
            std.debug.print("\nAll active Neovim instances ({d}):\n", .{disc.all_instances.len});
            for (disc.all_instances, 1..) |inst, i| {
                const is_match = inst.match_score.isMatch();
                const marker: []const u8 = if (is_match) " [*]" else "    ";
                const pid_u: u64 = if (inst.pid >= 0) @intCast(inst.pid) else 0;
                std.debug.print("  {d}.{s} PID {d:>6} | CWD: {s}\n", .{ i, marker, pid_u, inst.cwd });
                std.debug.print("        Socket: {s}\n", .{inst.socket_path});
                if (inst.current_file.len > 0) {
                    std.debug.print("        File:   {s}\n", .{inst.current_file});
                }
            }
        } else {
            std.debug.print("\nNo running Neovim sockets discovered on the system.\n", .{});
        }
        return;
    }

    if (args.len >= 2 and std.mem.eql(u8, args[1], "mcp")) {
        const raw_target: ?[]const u8 = if (args.len >= 3)
            args[2]
        else if (init.environ_map.get("NVIM")) |nvim_env|
            if (nvim_env.len > 0) nvim_env else null
        else
            null;

        // Auto-detect mode if no target provided or "detect" passed explicitly
        if (raw_target == null or std.mem.eql(u8, raw_target.?, "detect") or std.mem.eql(u8, raw_target.?, "--detect")) {
            const cwd = std.process.currentPathAlloc(io, arena) catch ".";
            var disc = neovim_boss.discovery.findBestMatch(arena, io, cwd) catch |err| {
                std.debug.print("Error during Neovim socket auto-detection: {s}\n", .{@errorName(err)});
                return err;
            };
            defer disc.deinit(arena);

            if (disc.best_match) |match| {
                std.debug.print("Auto-detected Neovim instance ({s}):\n  Socket: {s}\n  PID:    {d}\n  CWD:    {s}\n", .{
                    match.match_score.label(),
                    match.socket_path,
                    match.pid,
                    match.cwd,
                });

                var nvim = neovim_boss.attach(arena, io, .{ .socket = match.socket_path }) catch |err| {
                    std.debug.print("Failed to connect to detected Neovim at '{s}': {s}\n", .{ match.socket_path, @errorName(err) });
                    return err;
                };
                defer nvim.deinit();

                try neovim_boss.mcp.run(arena, io, &nvim);
                return;
            }

            std.debug.print("No running Neovim instance detected for project folder: '{s}'\n", .{cwd});
            if (disc.all_instances.len > 0) {
                std.debug.print("\nFound {d} Neovim instance(s) running in other directories:\n", .{disc.all_instances.len});
                for (disc.all_instances) |inst| {
                    const pid_u: u64 = if (inst.pid >= 0) @intCast(inst.pid) else 0;
                    std.debug.print("  - PID {d:>6}: {s} (socket: {s})\n", .{ pid_u, inst.cwd, inst.socket_path });
                }
                std.debug.print("\nTo connect explicitly, run: nb mcp <socket-path>\n", .{});
            } else {
                std.debug.print("\nNo active Neovim sockets found. Is Neovim running?\n", .{});
                std.debug.print("To start Neovim with a listener: nvim --listen /tmp/nvim.sock\n", .{});
            }
            return error.ConnectionFailed;
        }

        const target = raw_target.?;
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
        \\  nb detect [dir]      Find and display running Neovim instances
        \\
        \\Supported listeners for 'nb mcp':
        \\  (omitted)          Auto-detects Neovim socket for current project (or uses $NVIM)
        \\  detect             Explicit auto-detection for current project
        \\  /path/to/socket    Unix domain socket (e.g. /tmp/nvim.sock)
        \\  host:port          TCP socket (e.g. 127.0.0.1:6666)
        \\  child              Embedded headless Neovim child process
        \\  stdio              Standard I/O Neovim process
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
