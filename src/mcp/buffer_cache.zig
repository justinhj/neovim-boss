const std = @import("std");
const msgpack = @import("zig_msgpack");
const MsgPackObject = msgpack.MsgPackObject;
const nvim_mod = @import("../nvim.zig");
const Nvim = nvim_mod.Nvim;
const object_util = @import("../object_util.zig");

/// Event-driven cache of visible-buffer metadata for `neovim://buffers`
/// (issue #6). Instead of one `listBufInfo` RPC per MCP read, we attach
/// `nvim_buf_attach` once (lazily, on first read), keep per-buffer metadata
/// fresh from buffer-event notifications, and serve reads from the cache
/// after draining pending notifications.
///
/// Cheap metadata only: bufnr, name, line count, modified flag, changedtick.
/// Buffer contents are never mirrored.
const sync_lua = @embedFile("buffer_cache.lua");

/// Pure line-count math for `nvim_buf_attach` on_lines events:
/// on_lines(firstline, lastline, linedata) replaces the half-open range
/// [firstline, lastline) with `new_line_count` lines.
pub fn applyLineDelta(line_count: i64, firstline: i64, lastline: i64, new_line_count: i64) i64 {
    return line_count + new_line_count - (lastline - firstline);
}

/// Cached per-buffer metadata. `name` is owned by the cache allocator.
pub const CachedBuffer = struct {
    bufnr: i64,
    name: []const u8,
    line_count: i64,
    modified: bool,
    changedtick: i64,
};

/// JSON shape served for `neovim://buffers` once subscribed.
pub const CachedBufferInfo = struct {
    id: i64,
    name: []const u8,
    line_count: i64,
    modified: bool,
    changedtick: i64,
};

pub const BufferCache = struct {
    allocator: std.mem.Allocator,
    nvim: *Nvim,
    subscribed: bool = false,
    visibility_dirty: bool = false,
    last_error: ?anyerror = null,
    entries: std.AutoHashMap(i64, CachedBuffer),

    pub fn init(allocator: std.mem.Allocator, nvim: *Nvim) BufferCache {
        return .{
            .allocator = allocator,
            .nvim = nvim,
            .entries = std.AutoHashMap(i64, CachedBuffer).init(allocator),
        };
    }

    pub fn deinit(self: *BufferCache) void {
        deinitEntries(self.allocator, &self.entries);
    }

    /// Drop subscription state (e.g. after reconnect). The next read
    /// resubscribes lazily.
    pub fn reset(self: *BufferCache) void {
        deinitEntries(self.allocator, &self.entries);
        self.entries = std.AutoHashMap(i64, CachedBuffer).init(self.allocator);
        self.subscribed = false;
        self.visibility_dirty = false;
        self.last_error = null;
    }

    /// One-shot subscribe: a single `nvim_exec_lua` attaches to every buffer
    /// backing a visible window, installs the visibility autocmds, and
    /// returns the initial snapshot. One RPC, no N+1.
    pub fn subscribe(self: *BufferCache, arena: std.mem.Allocator) !void {
        // While subscribed, this cache owns the client's notification dispatch.
        self.nvim.setNotificationHandler(@ptrCast(self), onNotification);
        errdefer self.nvim.setNotificationHandler(null, null);

        const res = try self.runSync(arena, true);
        try self.replaceFromSnapshot(res);
        self.subscribed = true;
        // NB: visibility_dirty is intentionally left alone here. A visibility
        // notification dispatched mid-wait during the subscribe RPC describes
        // a change *after* the snapshot was taken, so the read path's
        // drain + syncVisibility still needs to see it.
    }

    /// Re-diff the visible set after a visibility notification: attach newly
    /// visible buffers, detach ones that are gone, and take the authoritative
    /// snapshot (overwrites; deltas applied before/after still converge).
    pub fn syncVisibility(self: *BufferCache, arena: std.mem.Allocator) !void {
        // Clear first: notifications arriving during the sync RPC describe
        // post-snapshot changes and must survive for the next read.
        self.visibility_dirty = false;
        const res = try self.runSync(arena, false);
        try self.replaceFromSnapshot(res);
    }

    /// Sorted snapshot for JSON serialization. Names are borrowed from the
    /// cache; the slice itself is arena-owned.
    pub fn toSortedInfos(self: *const BufferCache, arena: std.mem.Allocator) ![]CachedBufferInfo {
        const infos = try arena.alloc(CachedBufferInfo, self.entries.count());
        var it = self.entries.iterator();
        var i: usize = 0;
        while (it.next()) |kv| {
            infos[i] = .{
                .id = kv.value_ptr.bufnr,
                .name = kv.value_ptr.name,
                .line_count = kv.value_ptr.line_count,
                .modified = kv.value_ptr.modified,
                .changedtick = kv.value_ptr.changedtick,
            };
            i += 1;
        }
        std.mem.sort(CachedBufferInfo, infos, {}, lessThanInfo);
        return infos;
    }

    fn runSync(self: *BufferCache, arena: std.mem.Allocator, setup_autocmds: bool) !MsgPackObject {
        // The attached-bufnr list is transient; the request arena is fine.
        const attached = try arena.alloc(MsgPackObject, self.entries.count());
        var kit = self.entries.keyIterator();
        var n: usize = 0;
        while (kit.next()) |k| {
            attached[n] = .{ .integer = k.* };
            n += 1;
        }

        const args = [_]MsgPackObject{
            .{ .integer = self.nvim.channel_id },
            .{ .array = attached },
            .{ .boolean = setup_autocmds },
        };
        return try self.nvim.execLua(arena, sync_lua, &args);
    }

    fn replaceFromSnapshot(self: *BufferCache, res: MsgPackObject) !void {
        const arr = object_util.asArray(res) orelse return error.UnexpectedSnapshot;

        // Parse into a fresh map first so a malformed snapshot can't wipe a
        // good cache.
        var fresh = std.AutoHashMap(i64, CachedBuffer).init(self.allocator);
        errdefer deinitEntries(self.allocator, &fresh);

        for (arr) |item| {
            const m = object_util.asMap(item) orelse return error.UnexpectedSnapshot;
            const bufnr = intField(m, "bufnr") orelse return error.UnexpectedSnapshot;
            const name_obj = object_util.mapGet(m, "name") orelse return error.UnexpectedSnapshot;
            const name_src = object_util.asString(name_obj) orelse return error.UnexpectedSnapshot;
            const name = try self.allocator.dupe(u8, name_src);
            errdefer self.allocator.free(name);
            try fresh.put(bufnr, .{
                .bufnr = bufnr,
                .name = name,
                .line_count = intField(m, "line_count") orelse return error.UnexpectedSnapshot,
                .modified = boolField(m, "modified"),
                .changedtick = intField(m, "changedtick") orelse 0,
            });
        }

        deinitEntries(self.allocator, &self.entries);
        self.entries = fresh;
    }

    fn onNotification(user_data: ?*anyopaque, notification: msgpack.RpcNotification) void {
        const self: *BufferCache = @ptrCast(@alignCast(user_data.?));
        // The handler signature is infallible; record failures for the read
        // path to surface once instead of dropping them silently.
        self.handleNotification(notification) catch |err| {
            self.last_error = err;
        };
    }

    fn handleNotification(self: *BufferCache, notif: msgpack.RpcNotification) !void {
        if (std.mem.eql(u8, notif.method, "neoboss_buf_lines")) {
            // [bufnr, changedtick, firstline, lastline, linedata_len]
            if (notif.params.len != 5) return;
            const bufnr = object_util.asInt(notif.params[0], i64) orelse return;
            const tick = object_util.asInt(notif.params[1], i64) orelse return;
            const firstline = object_util.asInt(notif.params[2], i64) orelse return;
            const lastline = object_util.asInt(notif.params[3], i64) orelse return;
            const new_lines = object_util.asInt(notif.params[4], i64) orelse return;
            if (self.entries.getPtr(bufnr)) |e| {
                e.line_count = applyLineDelta(e.line_count, firstline, lastline, new_lines);
                e.changedtick = tick;
                e.modified = true;
            }
        } else if (std.mem.eql(u8, notif.method, "neoboss_buf_tick")) {
            // [bufnr, changedtick]
            if (notif.params.len != 2) return;
            const bufnr = object_util.asInt(notif.params[0], i64) orelse return;
            const tick = object_util.asInt(notif.params[1], i64) orelse return;
            if (self.entries.getPtr(bufnr)) |e| {
                e.changedtick = tick;
            }
        } else if (std.mem.eql(u8, notif.method, "neoboss_buf_detach")) {
            // [bufnr]
            if (notif.params.len != 1) return;
            const bufnr = object_util.asInt(notif.params[0], i64) orelse return;
            if (self.entries.fetchRemove(bufnr)) |kv| {
                self.allocator.free(kv.value.name);
            }
        } else if (std.mem.eql(u8, notif.method, "neoboss_buf_visibility")) {
            self.visibility_dirty = true;
        }
        // Everything else is none of this cache's business.
    }
};

fn deinitEntries(allocator: std.mem.Allocator, map: *std.AutoHashMap(i64, CachedBuffer)) void {
    var it = map.iterator();
    while (it.next()) |kv| allocator.free(kv.value_ptr.name);
    map.deinit();
}

fn intField(m: []const msgpack.MsgPackMapEntry, key: []const u8) ?i64 {
    const v = object_util.mapGet(m, key) orelse return null;
    return object_util.asInt(v, i64);
}

fn boolField(m: []const msgpack.MsgPackMapEntry, key: []const u8) bool {
    const v = object_util.mapGet(m, key) orelse return false;
    return object_util.asBool(v) orelse false;
}

fn lessThanInfo(_: void, a: CachedBufferInfo, b: CachedBufferInfo) bool {
    return a.id < b.id;
}

// --------------------------------------------------------------------------
// Unit tests (no Neovim required)
// --------------------------------------------------------------------------

test "buffer_cache: applyLineDelta" {
    // Insert 3 lines at (0-based) line 5: [5,5) -> 3 lines.
    try std.testing.expectEqual(@as(i64, 13), applyLineDelta(10, 5, 5, 3));
    // Delete lines [2,5): 3 lines removed.
    try std.testing.expectEqual(@as(i64, 7), applyLineDelta(10, 2, 5, 0));
    // Replace [0,10) with 4 lines.
    try std.testing.expectEqual(@as(i64, 4), applyLineDelta(10, 0, 10, 4));
    // Empty replacement is a no-op.
    try std.testing.expectEqual(@as(i64, 10), applyLineDelta(10, 3, 3, 0));
    // Whole-buffer replace.
    try std.testing.expectEqual(@as(i64, 1), applyLineDelta(100, 0, 100, 1));
}

test "buffer_cache: notification handling updates entries" {
    const allocator = std.testing.allocator;

    var cache = BufferCache{
        .allocator = allocator,
        .nvim = undefined, // never touched by handleNotification
        .entries = std.AutoHashMap(i64, CachedBuffer).init(allocator),
    };
    defer cache.deinit();

    const name = try allocator.dupe(u8, "foo.zig");
    try cache.entries.put(1, .{
        .bufnr = 1,
        .name = name,
        .line_count = 10,
        .modified = false,
        .changedtick = 5,
    });

    // on_lines: replace [2,5) (3 lines) with 4 new lines, tick 6.
    var lines_params = [_]MsgPackObject{
        .{ .integer = 1 },
        .{ .integer = 6 },
        .{ .integer = 2 },
        .{ .integer = 5 },
        .{ .integer = 4 },
    };
    try cache.handleNotification(.{ .method = "neoboss_buf_lines", .params = &lines_params });
    {
        const e = cache.entries.getPtr(1).?;
        try std.testing.expectEqual(@as(i64, 11), e.line_count);
        try std.testing.expectEqual(@as(i64, 6), e.changedtick);
        try std.testing.expect(e.modified);
    }

    // Unknown bufnr: ignored, no entry created.
    var unknown_params = [_]MsgPackObject{
        .{ .integer = 99 },
        .{ .integer = 7 },
        .{ .integer = 0 },
        .{ .integer = 0 },
        .{ .integer = 1 },
    };
    try cache.handleNotification(.{ .method = "neoboss_buf_lines", .params = &unknown_params });
    try std.testing.expect(cache.entries.getPtr(99) == null);

    // Tick-only update.
    var tick_params = [_]MsgPackObject{ .{ .integer = 1 }, .{ .integer = 9 } };
    try cache.handleNotification(.{ .method = "neoboss_buf_tick", .params = &tick_params });
    try std.testing.expectEqual(@as(i64, 9), cache.entries.getPtr(1).?.changedtick);

    // Visibility notification just sets the dirty flag.
    try cache.handleNotification(.{ .method = "neoboss_buf_visibility", .params = &[_]MsgPackObject{} });
    try std.testing.expect(cache.visibility_dirty);

    // Detach removes the entry.
    var detach_params = [_]MsgPackObject{.{ .integer = 1 }};
    try cache.handleNotification(.{ .method = "neoboss_buf_detach", .params = &detach_params });
    try std.testing.expect(cache.entries.getPtr(1) == null);
    try std.testing.expectEqual(@as(u32, 0), cache.entries.count());

    // Unrelated notifications are ignored.
    try cache.handleNotification(.{ .method = "nvim_buf_changedtick_event", .params = &[_]MsgPackObject{} });
    try std.testing.expect(cache.last_error == null);
}

test "buffer_cache: malformed notifications are ignored" {
    const allocator = std.testing.allocator;

    var cache = BufferCache{
        .allocator = allocator,
        .nvim = undefined, // never touched by handleNotification
        .entries = std.AutoHashMap(i64, CachedBuffer).init(allocator),
    };
    defer cache.deinit();

    // Wrong param count.
    var short = [_]MsgPackObject{ .{ .integer = 1 }, .{ .integer = 2 } };
    try cache.handleNotification(.{ .method = "neoboss_buf_lines", .params = &short });
    // Wrong param types.
    var bad_types = [_]MsgPackObject{ .{ .string = @constCast("x") }, .{ .integer = 2 } };
    try cache.handleNotification(.{ .method = "neoboss_buf_tick", .params = &bad_types });

    try std.testing.expectEqual(@as(u32, 0), cache.entries.count());
    try std.testing.expect(cache.last_error == null);
}
