const std = @import("std");
const msgpack = @import("zig_msgpack");
const MsgPackObject = msgpack.MsgPackObject;
const MsgPackMapEntry = msgpack.MsgPackMapEntry;

/// Extract string slice if the object is a string.
pub fn asString(obj: MsgPackObject) ?[]const u8 {
    return switch (obj) {
        .string => |s| s,
        else => null,
    };
}

/// Extract integer as type T if the object is an integer or unsigned integer.
pub fn asInt(obj: MsgPackObject, comptime T: type) ?T {
    return switch (obj) {
        .integer => |i| std.math.cast(T, i),
        .unsigned_integer => |u| std.math.cast(T, u),
        else => null,
    };
}

/// Extract boolean if the object is a boolean.
pub fn asBool(obj: MsgPackObject) ?bool {
    return switch (obj) {
        .boolean => |b| b,
        else => null,
    };
}

/// Extract array slice if the object is an array.
pub fn asArray(obj: MsgPackObject) ?[]MsgPackObject {
    return switch (obj) {
        .array => |arr| arr,
        else => null,
    };
}

/// Extract map entries if the object is a map.
pub fn asMap(obj: MsgPackObject) ?[]MsgPackMapEntry {
    return switch (obj) {
        .map => |entries| entries,
        else => null,
    };
}

/// Lookup a value in a MsgPack map by string key.
pub fn mapGet(entries: []const MsgPackMapEntry, key: []const u8) ?MsgPackObject {
    for (entries) |entry| {
        if (asString(entry.key)) |k| {
            if (std.mem.eql(u8, k, key)) {
                return entry.value;
            }
        }
    }
    return null;
}

/// Recursively traverses a MsgPackObject tree, applying a transform function
/// to each node. New nodes are allocated from `arena`.
pub fn walkObject(
    arena: std.mem.Allocator,
    obj: MsgPackObject,
    context: anytype,
    transformFn: fn (ctx: @TypeOf(context), arena: std.mem.Allocator, node: MsgPackObject) anyerror!MsgPackObject,
) anyerror!MsgPackObject {
    const transformed = try transformFn(context, arena, obj);

    switch (transformed) {
        .array => |arr| {
            const new_arr = try arena.alloc(MsgPackObject, arr.len);
            for (arr, 0..) |item, i| {
                new_arr[i] = try walkObject(arena, item, context, transformFn);
            }
            return .{ .array = new_arr };
        },
        .map => |entries| {
            const new_entries = try arena.alloc(MsgPackMapEntry, entries.len);
            for (entries, 0..) |entry, i| {
                new_entries[i] = .{
                    .key = try walkObject(arena, entry.key, context, transformFn),
                    .value = try walkObject(arena, entry.value, context, transformFn),
                };
            }
            return .{ .map = new_entries };
        },
        else => return transformed,
    }
}

// --------------------------------------------------------------------------
// Unit Tests
// --------------------------------------------------------------------------

test "object_util: type extractors" {
    var s_buf = "neovim".*;
    const obj_str = MsgPackObject{ .string = &s_buf };
    try std.testing.expectEqualStrings("neovim", asString(obj_str).?);
    try std.testing.expect(asInt(obj_str, i64) == null);

    const obj_int = MsgPackObject{ .integer = 42 };
    try std.testing.expectEqual(@as(i64, 42), asInt(obj_int, i64).?);
    try std.testing.expectEqual(@as(u32, 42), asInt(obj_int, u32).?);

    const obj_bool = MsgPackObject{ .boolean = true };
    try std.testing.expectEqual(true, asBool(obj_bool).?);
}

test "object_util: mapGet lookup" {
    var k1 = "name".*;
    var v1 = "nvim".*;
    var k2 = "channel".*;

    var entries = [_]MsgPackMapEntry{
        .{ .key = .{ .string = &k1 }, .value = .{ .string = &v1 } },
        .{ .key = .{ .string = &k2 }, .value = .{ .integer = 1 } },
    };

    const val = mapGet(&entries, "channel");
    try std.testing.expect(val != null);
    try std.testing.expectEqual(@as(i64, 1), val.?.integer);

    try std.testing.expect(mapGet(&entries, "missing") == null);
}

test "object_util: walkObject recursive transform" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const Transformer = struct {
        fn doubleInts(_: void, _: std.mem.Allocator, node: MsgPackObject) anyerror!MsgPackObject {
            return switch (node) {
                .integer => |i| .{ .integer = i * 2 },
                else => node,
            };
        }
    };

    var items = [_]MsgPackObject{
        .{ .integer = 5 },
        .{ .integer = 10 },
    };
    const root = MsgPackObject{ .array = &items };

    const result = try walkObject(arena.allocator(), root, {}, Transformer.doubleInts);
    try std.testing.expect(result == .array);
    try std.testing.expectEqual(@as(i64, 10), result.array[0].integer);
    try std.testing.expectEqual(@as(i64, 20), result.array[1].integer);
}
