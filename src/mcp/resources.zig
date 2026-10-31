const std = @import("std");
const nvim_types = @import("../nvim_types.zig");
const types = @import("types.zig");
const buffer_cache = @import("buffer_cache.zig");

pub const ResourceReadResult = struct {
    contents: []const types.ResourceContent,
};

pub const BufferInfo = nvim_types.BufferInfo;

pub fn listResources(arena: std.mem.Allocator) ![]const types.Resource {
    const resources = try arena.alloc(types.Resource, 1);
    resources[0] = .{
        .uri = "neovim://buffers",
        .name = "Open Buffers",
        .description = "List of currently open Neovim buffers with detailed metadata",
        .mimeType = "application/json",
    };
    return resources;
}

pub fn readResource(
    cache: *buffer_cache.BufferCache,
    arena: std.mem.Allocator,
    uri: []const u8,
) !ResourceReadResult {
    if (std.mem.eql(u8, uri, "neovim://buffers")) {
        return readOpenBuffers(cache, arena);
    }

    return error.ResourceNotFound;
}

fn readOpenBuffers(cache: *buffer_cache.BufferCache, arena: std.mem.Allocator) !ResourceReadResult {
    // Lazy subscription: attach on first read, not at MCP connect.
    if (!cache.subscribed) try cache.subscribe(arena);

    // Drain pending Neovim notifications so the cache reflects everything
    // received so far. (Notifications are also dispatched mid-wait during any
    // blocking RPC, so the cache stays fresh across tool calls too.)
    while (try cache.nvim.processOne(arena)) {}

    // Re-diff the visible set if anything changed since the last read.
    // (syncVisibility clears the flag up front; visibility changes that land
    // during the sync RPC re-arm it for the next read.)
    if (cache.visibility_dirty) {
        try cache.syncVisibility(arena);
    }

    // Surface (once) any error the notification handler recorded.
    if (cache.last_error) |err| {
        cache.last_error = null;
        return err;
    }

    const infos = try cache.toSortedInfos(arena);

    const json_text = try std.fmt.allocPrint(arena, "{f}", .{std.json.fmt(infos, .{})});

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
