const std = @import("std");
const nvim_mod = @import("nvim.zig");
const Nvim = nvim_mod.Nvim;

pub const types = @import("mcp/types.zig");
pub const tools = @import("mcp/tools.zig");
pub const resources = @import("mcp/resources.zig");
pub const server = @import("mcp/server.zig");
pub const Server = server.Server;

/// Run the MCP server over stdio with a persistent connection to Neovim.
pub fn run(allocator: std.mem.Allocator, io: std.Io, nvim: *Nvim) !void {
    var s = Server.init(allocator, io, nvim);
    try s.run();
}
