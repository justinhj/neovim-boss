const std = @import("std");
const nvim_mod = @import("../nvim.zig");
const Nvim = nvim_mod.Nvim;
const api = @import("../api.zig");
const types = @import("types.zig");

pub const ResourceReadResult = struct {
    contents: []const types.ResourceContent,
};

pub const BufferInfo = struct {
    id: i64,
    name: []const u8,
};

pub fn listResources(arena: std.mem.Allocator) ![]const types.Resource {
    const resources = try arena.alloc(types.Resource, 1);
    resources[0] = .{
        .uri = "neovim://buffers",
        .name = "Open Buffers",
        .description = "List of currently open Neovim buffers",
        .mimeType = "application/json",
    };
    return resources;
}

pub fn readResource(
    nvim: *Nvim,
    arena: std.mem.Allocator,
    uri: []const u8,
) !ResourceReadResult {
    if (std.mem.eql(u8, uri, "neovim://buffers")) {
        return readOpenBuffers(nvim, arena);
    }

    return error.ResourceNotFound;
}

fn readOpenBuffers(nvim: *Nvim, arena: std.mem.Allocator) !ResourceReadResult {
    const bufs = try nvim.listBufs(arena);
    const buf_infos = try arena.alloc(BufferInfo, bufs.len);

    for (bufs, 0..) |buf, i| {
        const name = api.nvim_buf_get_name(nvim, arena, buf) catch "";
        buf_infos[i] = .{
            .id = buf.handle,
            .name = name,
        };
    }

    const json_text = try std.fmt.allocPrint(arena, "{f}", .{std.json.fmt(buf_infos, .{})});

    const contents = try arena.alloc(types.ResourceContent, 1);
    contents[0] = .{
        .uri = "neovim://buffers",
        .mimeType = "application/json",
        .text = json_text,
    };

    return .{
        .contents = contents,
    };
}
