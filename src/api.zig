// THIS FILE IS AUTO-GENERATED FROM data/api_info.msgpack. DO NOT EDIT DIRECTLY.
const std = @import("std");
const msgpack = @import("zig_msgpack");
const nvim_mod = @import("nvim.zig");
const Nvim = nvim_mod.Nvim;
const nvim_types = @import("nvim_types.zig");
const TypeError = nvim_types.TypeError;
const decodeHandle = nvim_types.decodeHandle;
const encodeHandleAlloc = nvim_types.encodeHandleAlloc;

pub const ApiError = error{
    UnexpectedType,
} || TypeError || anyerror;

const root = @This();
/// Remote Neovim Buffer handle.
pub const Buffer = struct {
    handle: i64,

    pub const default_ext_type: i8 = 0;

    pub fn decode(ext: msgpack.MsgPackExtension) TypeError!Buffer {
        return .{ .handle = try decodeHandle(ext.data) };
    }

    pub fn encode(self: Buffer, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackExtension {
        return .{
            .type = ext_type,
            .data = try encodeHandleAlloc(arena, self.handle),
        };
    }

    pub fn toObject(self: Buffer, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackObject {
        return .{ .extension = try self.encode(arena, ext_type) };
    }

    pub fn format(
        self: Buffer,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Buffer({d})", .{self.handle});
    }
    /// Since API level 1.
    pub fn lineCount(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator) !i64 {
        return nvim_buf_line_count(nvim, arena, self);
    }

    /// Since API level 4.
    pub fn attach(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, send_buffer: bool, opts: []const msgpack.MsgPackMapEntry) !bool {
        return nvim_buf_attach(nvim, arena, self, send_buffer, opts);
    }

    /// Since API level 4.
    pub fn detach(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator) !bool {
        return nvim_buf_detach(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn getLines(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, start: i64, end: i64, strict_indexing: bool) ![]msgpack.MsgPackObject {
        return nvim_buf_get_lines(nvim, arena, self, start, end, strict_indexing);
    }

    /// Since API level 1.
    pub fn setLines(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, start: i64, end: i64, strict_indexing: bool, replacement: []const msgpack.MsgPackObject) !void {
        return nvim_buf_set_lines(nvim, arena, self, start, end, strict_indexing, replacement);
    }

    /// Since API level 7.
    pub fn setText(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, start_row: i64, start_col: i64, end_row: i64, end_col: i64, replacement: []const msgpack.MsgPackObject) !void {
        return nvim_buf_set_text(nvim, arena, self, start_row, start_col, end_row, end_col, replacement);
    }

    /// Since API level 9.
    pub fn getText(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, start_row: i64, start_col: i64, end_row: i64, end_col: i64, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
        return nvim_buf_get_text(nvim, arena, self, start_row, start_col, end_row, end_col, opts);
    }

    /// Since API level 5.
    pub fn getOffset(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, index: i64) !i64 {
        return nvim_buf_get_offset(nvim, arena, self, index);
    }

    /// Since API level 1.
    pub fn getVar(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return nvim_buf_get_var(nvim, arena, self, name);
    }

    /// Since API level 2.
    pub fn getChangedtick(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator) !i64 {
        return nvim_buf_get_changedtick(nvim, arena, self);
    }

    /// Since API level 3.
    pub fn getKeymap(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, mode: []const u8) ![]msgpack.MsgPackObject {
        return nvim_buf_get_keymap(nvim, arena, self, mode);
    }

    /// Since API level 6.
    pub fn setKeymap(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, mode: []const u8, lhs: []const u8, rhs: []const u8, opts: []const msgpack.MsgPackMapEntry) !void {
        return nvim_buf_set_keymap(nvim, arena, self, mode, lhs, rhs, opts);
    }

    /// Since API level 6.
    pub fn delKeymap(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, mode: []const u8, lhs: []const u8) !void {
        return nvim_buf_del_keymap(nvim, arena, self, mode, lhs);
    }

    /// Since API level 1.
    pub fn setVar(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
        return nvim_buf_set_var(nvim, arena, self, name, value);
    }

    /// Since API level 1.
    pub fn delVar(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !void {
        return nvim_buf_del_var(nvim, arena, self, name);
    }

    /// Since API level 1.
    pub fn getName(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator) ![]u8 {
        return nvim_buf_get_name(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn setName(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !void {
        return nvim_buf_set_name(nvim, arena, self, name);
    }

    /// Since API level 5.
    pub fn isLoaded(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator) !bool {
        return nvim_buf_is_loaded(nvim, arena, self);
    }

    /// Since API level 7.
    pub fn delete(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) !void {
        return nvim_buf_delete(nvim, arena, self, opts);
    }

    /// Since API level 1.
    pub fn isValid(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator) !bool {
        return nvim_buf_is_valid(nvim, arena, self);
    }

    /// Since API level 8.
    pub fn delMark(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !bool {
        return nvim_buf_del_mark(nvim, arena, self, name);
    }

    /// Since API level 8.
    pub fn setMark(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, line: i64, col: i64, opts: []const msgpack.MsgPackMapEntry) !bool {
        return nvim_buf_set_mark(nvim, arena, self, name, line, col, opts);
    }

    /// Since API level 1.
    pub fn getMark(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) ![]msgpack.MsgPackObject {
        return nvim_buf_get_mark(nvim, arena, self, name);
    }

    /// Since API level 7.
    pub fn call(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, fun: i64) !msgpack.MsgPackObject {
        return nvim_buf_call(nvim, arena, self, fun);
    }

    /// Since API level 9.
    pub fn createUserCommand(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, cmd: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !void {
        return nvim_buf_create_user_command(nvim, arena, self, name, cmd, opts);
    }

    /// Since API level 9.
    pub fn delUserCommand(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !void {
        return nvim_buf_del_user_command(nvim, arena, self, name);
    }

    /// Since API level 4.
    pub fn getCommands(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return nvim_buf_get_commands(nvim, arena, self, opts);
    }

    /// Deprecated since API level 2.
    pub fn getNumber(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator) !i64 {
        return nvim_buf_get_number(nvim, arena, self);
    }

    /// Deprecated since API level 7.
    pub fn clearHighlight(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64, line_start: i64, line_end: i64) !void {
        return nvim_buf_clear_highlight(nvim, arena, self, ns_id, line_start, line_end);
    }

    /// Deprecated since API level 13.
    pub fn addHighlight(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64, hl_group: []const u8, line: i64, col_start: i64, col_end: i64) !i64 {
        return nvim_buf_add_highlight(nvim, arena, self, ns_id, hl_group, line, col_start, col_end);
    }

    /// Deprecated since API level 8.
    pub fn setVirtualText(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, src_id: i64, line: i64, chunks: []const msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !i64 {
        return nvim_buf_set_virtual_text(nvim, arena, self, src_id, line, chunks, opts);
    }

    /// Deprecated since API level 11.
    pub fn getOption(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return nvim_buf_get_option(nvim, arena, self, name);
    }

    /// Deprecated since API level 11.
    pub fn setOption(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
        return nvim_buf_set_option(nvim, arena, self, name, value);
    }

    /// Since API level 7.
    pub fn getExtmarkById(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64, id: i64, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
        return nvim_buf_get_extmark_by_id(nvim, arena, self, ns_id, id, opts);
    }

    /// Since API level 7.
    pub fn getExtmarks(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64, start: msgpack.MsgPackObject, end: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
        return nvim_buf_get_extmarks(nvim, arena, self, ns_id, start, end, opts);
    }

    /// Since API level 7.
    pub fn setExtmark(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64, line: i64, col: i64, opts: []const msgpack.MsgPackMapEntry) !i64 {
        return nvim_buf_set_extmark(nvim, arena, self, ns_id, line, col, opts);
    }

    /// Since API level 7.
    pub fn delExtmark(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64, id: i64) !bool {
        return nvim_buf_del_extmark(nvim, arena, self, ns_id, id);
    }

    /// Since API level 5.
    pub fn clearNamespace(self: Buffer, nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64, line_start: i64, line_end: i64) !void {
        return nvim_buf_clear_namespace(nvim, arena, self, ns_id, line_start, line_end);
    }

};

/// Remote Neovim Window handle.
pub const Window = struct {
    handle: i64,

    pub const default_ext_type: i8 = 1;

    pub fn decode(ext: msgpack.MsgPackExtension) TypeError!Window {
        return .{ .handle = try decodeHandle(ext.data) };
    }

    pub fn encode(self: Window, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackExtension {
        return .{
            .type = ext_type,
            .data = try encodeHandleAlloc(arena, self.handle),
        };
    }

    pub fn toObject(self: Window, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackObject {
        return .{ .extension = try self.encode(arena, ext_type) };
    }

    pub fn format(
        self: Window,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Window({d})", .{self.handle});
    }
    /// Deprecated since API level 11.
    pub fn getOption(self: Window, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return nvim_win_get_option(nvim, arena, self, name);
    }

    /// Deprecated since API level 11.
    pub fn setOption(self: Window, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
        return nvim_win_set_option(nvim, arena, self, name, value);
    }

    /// Since API level 6.
    pub fn setConfig(self: Window, nvim: *Nvim, arena: std.mem.Allocator, config: []const msgpack.MsgPackMapEntry) !void {
        return nvim_win_set_config(nvim, arena, self, config);
    }

    /// Since API level 6.
    pub fn getConfig(self: Window, nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
        return nvim_win_get_config(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn getBuf(self: Window, nvim: *Nvim, arena: std.mem.Allocator) !Buffer {
        return nvim_win_get_buf(nvim, arena, self);
    }

    /// Since API level 5.
    pub fn setBuf(self: Window, nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) !void {
        return nvim_win_set_buf(nvim, arena, self, buf);
    }

    /// Since API level 1.
    pub fn getCursor(self: Window, nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return nvim_win_get_cursor(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn setCursor(self: Window, nvim: *Nvim, arena: std.mem.Allocator, pos: []const msgpack.MsgPackObject) !void {
        return nvim_win_set_cursor(nvim, arena, self, pos);
    }

    /// Since API level 1.
    pub fn getHeight(self: Window, nvim: *Nvim, arena: std.mem.Allocator) !i64 {
        return nvim_win_get_height(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn setHeight(self: Window, nvim: *Nvim, arena: std.mem.Allocator, height: i64) !void {
        return nvim_win_set_height(nvim, arena, self, height);
    }

    /// Since API level 1.
    pub fn getWidth(self: Window, nvim: *Nvim, arena: std.mem.Allocator) !i64 {
        return nvim_win_get_width(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn setWidth(self: Window, nvim: *Nvim, arena: std.mem.Allocator, width: i64) !void {
        return nvim_win_set_width(nvim, arena, self, width);
    }

    /// Since API level 1.
    pub fn getVar(self: Window, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return nvim_win_get_var(nvim, arena, self, name);
    }

    /// Since API level 1.
    pub fn setVar(self: Window, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
        return nvim_win_set_var(nvim, arena, self, name, value);
    }

    /// Since API level 1.
    pub fn delVar(self: Window, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !void {
        return nvim_win_del_var(nvim, arena, self, name);
    }

    /// Since API level 1.
    pub fn getPosition(self: Window, nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return nvim_win_get_position(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn getTabpage(self: Window, nvim: *Nvim, arena: std.mem.Allocator) !Tabpage {
        return nvim_win_get_tabpage(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn getNumber(self: Window, nvim: *Nvim, arena: std.mem.Allocator) !i64 {
        return nvim_win_get_number(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn isValid(self: Window, nvim: *Nvim, arena: std.mem.Allocator) !bool {
        return nvim_win_is_valid(nvim, arena, self);
    }

    /// Since API level 7.
    pub fn hide(self: Window, nvim: *Nvim, arena: std.mem.Allocator) !void {
        return nvim_win_hide(nvim, arena, self);
    }

    /// Since API level 6.
    pub fn close(self: Window, nvim: *Nvim, arena: std.mem.Allocator, force: bool) !void {
        return nvim_win_close(nvim, arena, self, force);
    }

    /// Since API level 7.
    pub fn call(self: Window, nvim: *Nvim, arena: std.mem.Allocator, fun: i64) !msgpack.MsgPackObject {
        return nvim_win_call(nvim, arena, self, fun);
    }

    /// Since API level 10.
    pub fn setHlNs(self: Window, nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64) !void {
        return nvim_win_set_hl_ns(nvim, arena, self, ns_id);
    }

    /// Since API level 12.
    pub fn textHeight(self: Window, nvim: *Nvim, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return nvim_win_text_height(nvim, arena, self, opts);
    }

};

/// Remote Neovim Tabpage handle.
pub const Tabpage = struct {
    handle: i64,

    pub const default_ext_type: i8 = 2;

    pub fn decode(ext: msgpack.MsgPackExtension) TypeError!Tabpage {
        return .{ .handle = try decodeHandle(ext.data) };
    }

    pub fn encode(self: Tabpage, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackExtension {
        return .{
            .type = ext_type,
            .data = try encodeHandleAlloc(arena, self.handle),
        };
    }

    pub fn toObject(self: Tabpage, arena: std.mem.Allocator, ext_type: i8) !msgpack.MsgPackObject {
        return .{ .extension = try self.encode(arena, ext_type) };
    }

    pub fn format(
        self: Tabpage,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Tabpage({d})", .{self.handle});
    }
    /// Since API level 1.
    pub fn listWins(self: Tabpage, nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return nvim_tabpage_list_wins(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn getVar(self: Tabpage, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return nvim_tabpage_get_var(nvim, arena, self, name);
    }

    /// Since API level 1.
    pub fn setVar(self: Tabpage, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
        return nvim_tabpage_set_var(nvim, arena, self, name, value);
    }

    /// Since API level 1.
    pub fn delVar(self: Tabpage, nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !void {
        return nvim_tabpage_del_var(nvim, arena, self, name);
    }

    /// Since API level 1.
    pub fn getWin(self: Tabpage, nvim: *Nvim, arena: std.mem.Allocator) !Window {
        return nvim_tabpage_get_win(nvim, arena, self);
    }

    /// Since API level 12.
    pub fn setWin(self: Tabpage, nvim: *Nvim, arena: std.mem.Allocator, win: Window) !void {
        return nvim_tabpage_set_win(nvim, arena, self, win);
    }

    /// Since API level 1.
    pub fn getNumber(self: Tabpage, nvim: *Nvim, arena: std.mem.Allocator) !i64 {
        return nvim_tabpage_get_number(nvim, arena, self);
    }

    /// Since API level 1.
    pub fn isValid(self: Tabpage, nvim: *Nvim, arena: std.mem.Allocator) !bool {
        return nvim_tabpage_is_valid(nvim, arena, self);
    }

};

/// Since API level 9.
pub fn nvim_get_autocmds(nvim: *Nvim, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_get_autocmds", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 9.
pub fn nvim_create_autocmd(nvim: *Nvim, arena: std.mem.Allocator, event: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !i64 {
    const params = [_]msgpack.MsgPackObject{
        event,
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_create_autocmd", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 9.
pub fn nvim_del_autocmd(nvim: *Nvim, arena: std.mem.Allocator, id: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = id },
    };
    _ = try nvim.client.request(arena, "nvim_del_autocmd", &params);
    return;
}

/// Since API level 9.
pub fn nvim_clear_autocmds(nvim: *Nvim, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .map = @constCast(opts) },
    };
    _ = try nvim.client.request(arena, "nvim_clear_autocmds", &params);
    return;
}

/// Since API level 9.
pub fn nvim_create_augroup(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, opts: []const msgpack.MsgPackMapEntry) !i64 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_create_augroup", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 9.
pub fn nvim_del_augroup_by_id(nvim: *Nvim, arena: std.mem.Allocator, id: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = id },
    };
    _ = try nvim.client.request(arena, "nvim_del_augroup_by_id", &params);
    return;
}

/// Since API level 9.
pub fn nvim_del_augroup_by_name(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    _ = try nvim.client.request(arena, "nvim_del_augroup_by_name", &params);
    return;
}

/// Since API level 9.
pub fn nvim_exec_autocmds(nvim: *Nvim, arena: std.mem.Allocator, event: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        event,
        .{ .map = @constCast(opts) },
    };
    _ = try nvim.client.request(arena, "nvim_exec_autocmds", &params);
    return;
}

/// Since API level 1.
pub fn nvim_buf_line_count(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "nvim_buf_line_count", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 4.
pub fn nvim_buf_attach(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, send_buffer: bool, opts: []const msgpack.MsgPackMapEntry) !bool {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .boolean = send_buffer },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_attach", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 4.
pub fn nvim_buf_detach(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) !bool {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "nvim_buf_detach", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_buf_get_lines(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, start: i64, end: i64, strict_indexing: bool) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = start },
        .{ .integer = end },
        .{ .boolean = strict_indexing },
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_lines", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_buf_set_lines(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, start: i64, end: i64, strict_indexing: bool, replacement: []const msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = start },
        .{ .integer = end },
        .{ .boolean = strict_indexing },
        .{ .array = @constCast(replacement) },
    };
    _ = try nvim.client.request(arena, "nvim_buf_set_lines", &params);
    return;
}

/// Since API level 7.
pub fn nvim_buf_set_text(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, start_row: i64, start_col: i64, end_row: i64, end_col: i64, replacement: []const msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = start_row },
        .{ .integer = start_col },
        .{ .integer = end_row },
        .{ .integer = end_col },
        .{ .array = @constCast(replacement) },
    };
    _ = try nvim.client.request(arena, "nvim_buf_set_text", &params);
    return;
}

/// Since API level 9.
pub fn nvim_buf_get_text(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, start_row: i64, start_col: i64, end_row: i64, end_col: i64, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = start_row },
        .{ .integer = start_col },
        .{ .integer = end_row },
        .{ .integer = end_col },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_text", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 5.
pub fn nvim_buf_get_offset(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, index: i64) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = index },
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_offset", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_buf_get_var(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_var", &params);
    return res;
}

/// Since API level 2.
pub fn nvim_buf_get_changedtick(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_changedtick", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 3.
pub fn nvim_buf_get_keymap(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, mode: []const u8) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(mode) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_keymap", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 6.
pub fn nvim_buf_set_keymap(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, mode: []const u8, lhs: []const u8, rhs: []const u8, opts: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(mode) },
        .{ .string = @constCast(lhs) },
        .{ .string = @constCast(rhs) },
        .{ .map = @constCast(opts) },
    };
    _ = try nvim.client.request(arena, "nvim_buf_set_keymap", &params);
    return;
}

/// Since API level 6.
pub fn nvim_buf_del_keymap(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, mode: []const u8, lhs: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(mode) },
        .{ .string = @constCast(lhs) },
    };
    _ = try nvim.client.request(arena, "nvim_buf_del_keymap", &params);
    return;
}

/// Since API level 1.
pub fn nvim_buf_set_var(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "nvim_buf_set_var", &params);
    return;
}

/// Since API level 1.
pub fn nvim_buf_del_var(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    _ = try nvim.client.request(arena, "nvim_buf_del_var", &params);
    return;
}

/// Since API level 1.
pub fn nvim_buf_get_name(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) ![]u8 {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_name", &params);
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_buf_set_name(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    _ = try nvim.client.request(arena, "nvim_buf_set_name", &params);
    return;
}

/// Since API level 5.
pub fn nvim_buf_is_loaded(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) !bool {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "nvim_buf_is_loaded", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_buf_delete(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, opts: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .map = @constCast(opts) },
    };
    _ = try nvim.client.request(arena, "nvim_buf_delete", &params);
    return;
}

/// Since API level 1.
pub fn nvim_buf_is_valid(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) !bool {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "nvim_buf_is_valid", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 8.
pub fn nvim_buf_del_mark(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !bool {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_del_mark", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 8.
pub fn nvim_buf_set_mark(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8, line: i64, col: i64, opts: []const msgpack.MsgPackMapEntry) !bool {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
        .{ .integer = line },
        .{ .integer = col },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_set_mark", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_buf_get_mark(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_mark", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_buf_call(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, fun: i64) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = fun },
    };
    const res = try nvim.client.request(arena, "nvim_buf_call", &params);
    return res;
}

/// Since API level 10.
pub fn nvim_parse_cmd(nvim: *Nvim, arena: std.mem.Allocator, str: []const u8, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(str) },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_parse_cmd", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 10.
pub fn nvim_cmd(nvim: *Nvim, arena: std.mem.Allocator, cmd: []const msgpack.MsgPackMapEntry, opts: []const msgpack.MsgPackMapEntry) ![]u8 {
    const params = [_]msgpack.MsgPackObject{
        .{ .map = @constCast(cmd) },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_cmd", &params);
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Since API level 9.
pub fn nvim_create_user_command(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, cmd: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        cmd,
        .{ .map = @constCast(opts) },
    };
    _ = try nvim.client.request(arena, "nvim_create_user_command", &params);
    return;
}

/// Since API level 9.
pub fn nvim_del_user_command(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    _ = try nvim.client.request(arena, "nvim_del_user_command", &params);
    return;
}

/// Since API level 9.
pub fn nvim_buf_create_user_command(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8, cmd: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
        cmd,
        .{ .map = @constCast(opts) },
    };
    _ = try nvim.client.request(arena, "nvim_buf_create_user_command", &params);
    return;
}

/// Since API level 9.
pub fn nvim_buf_del_user_command(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    _ = try nvim.client.request(arena, "nvim_buf_del_user_command", &params);
    return;
}

/// Since API level 4.
pub fn nvim_get_commands(nvim: *Nvim, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_get_commands", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 4.
pub fn nvim_buf_get_commands(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_commands", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 11.
pub fn nvim_exec(nvim: *Nvim, arena: std.mem.Allocator, src: []const u8, output: bool) ![]u8 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(src) },
        .{ .boolean = output },
    };
    const res = try nvim.client.request(arena, "nvim_exec", &params);
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 7.
pub fn nvim_command_output(nvim: *Nvim, arena: std.mem.Allocator, command: []const u8) ![]u8 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(command) },
    };
    const res = try nvim.client.request(arena, "nvim_command_output", &params);
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 7.
pub fn nvim_execute_lua(nvim: *Nvim, arena: std.mem.Allocator, code: []const u8, args: []const msgpack.MsgPackObject) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(code) },
        .{ .array = @constCast(args) },
    };
    const res = try nvim.client.request(arena, "nvim_execute_lua", &params);
    return res;
}

/// Deprecated since API level 2.
pub fn nvim_buf_get_number(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_number", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 7.
pub fn nvim_buf_clear_highlight(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, ns_id: i64, line_start: i64, line_end: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = ns_id },
        .{ .integer = line_start },
        .{ .integer = line_end },
    };
    _ = try nvim.client.request(arena, "nvim_buf_clear_highlight", &params);
    return;
}

/// Deprecated since API level 13.
pub fn nvim_buf_add_highlight(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, ns_id: i64, hl_group: []const u8, line: i64, col_start: i64, col_end: i64) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = ns_id },
        .{ .string = @constCast(hl_group) },
        .{ .integer = line },
        .{ .integer = col_start },
        .{ .integer = col_end },
    };
    const res = try nvim.client.request(arena, "nvim_buf_add_highlight", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 8.
pub fn nvim_buf_set_virtual_text(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, src_id: i64, line: i64, chunks: []const msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = src_id },
        .{ .integer = line },
        .{ .array = @constCast(chunks) },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_set_virtual_text", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 9.
pub fn nvim_get_hl_by_id(nvim: *Nvim, arena: std.mem.Allocator, hl_id: i64, rgb: bool) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = hl_id },
        .{ .boolean = rgb },
    };
    const res = try nvim.client.request(arena, "nvim_get_hl_by_id", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 9.
pub fn nvim_get_hl_by_name(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, rgb: bool) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        .{ .boolean = rgb },
    };
    const res = try nvim.client.request(arena, "nvim_get_hl_by_name", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn buffer_insert(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, lnum: i64, lines: []const msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = lnum },
        .{ .array = @constCast(lines) },
    };
    _ = try nvim.client.request(arena, "buffer_insert", &params);
    return;
}

/// Deprecated since API level 1.
pub fn buffer_get_line(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, index: i64) ![]u8 {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = index },
    };
    const res = try nvim.client.request(arena, "buffer_get_line", &params);
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn buffer_set_line(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, index: i64, line: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = index },
        .{ .string = @constCast(line) },
    };
    _ = try nvim.client.request(arena, "buffer_set_line", &params);
    return;
}

/// Deprecated since API level 1.
pub fn buffer_del_line(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, index: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = index },
    };
    _ = try nvim.client.request(arena, "buffer_del_line", &params);
    return;
}

/// Deprecated since API level 1.
pub fn buffer_get_line_slice(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, start: i64, end: i64, include_start: bool, include_end: bool) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = start },
        .{ .integer = end },
        .{ .boolean = include_start },
        .{ .boolean = include_end },
    };
    const res = try nvim.client.request(arena, "buffer_get_line_slice", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn buffer_set_line_slice(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, start: i64, end: i64, include_start: bool, include_end: bool, replacement: []const msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = start },
        .{ .integer = end },
        .{ .boolean = include_start },
        .{ .boolean = include_end },
        .{ .array = @constCast(replacement) },
    };
    _ = try nvim.client.request(arena, "buffer_set_line_slice", &params);
    return;
}

/// Deprecated since API level 1.
pub fn buffer_set_var(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, name: []const u8, value: msgpack.MsgPackObject) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
        value,
    };
    const res = try nvim.client.request(arena, "buffer_set_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn buffer_del_var(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "buffer_del_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn window_set_var(nvim: *Nvim, arena: std.mem.Allocator, window: Window, name: []const u8, value: msgpack.MsgPackObject) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try window.toObject(arena, nvim.ext_types.window_id),
        .{ .string = @constCast(name) },
        value,
    };
    const res = try nvim.client.request(arena, "window_set_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn window_del_var(nvim: *Nvim, arena: std.mem.Allocator, window: Window, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try window.toObject(arena, nvim.ext_types.window_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "window_del_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn tabpage_set_var(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8, value: msgpack.MsgPackObject) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
        .{ .string = @constCast(name) },
        value,
    };
    const res = try nvim.client.request(arena, "tabpage_set_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn tabpage_del_var(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "tabpage_del_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn vim_set_var(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        value,
    };
    const res = try nvim.client.request(arena, "vim_set_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn vim_del_var(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "vim_del_var", &params);
    return res;
}

/// Deprecated since API level 11.
pub fn nvim_get_option_info(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_get_option_info", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 11.
pub fn nvim_set_option(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "nvim_set_option", &params);
    return;
}

/// Deprecated since API level 11.
pub fn nvim_get_option(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_get_option", &params);
    return res;
}

/// Deprecated since API level 11.
pub fn nvim_buf_get_option(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_option", &params);
    return res;
}

/// Deprecated since API level 11.
pub fn nvim_buf_set_option(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "nvim_buf_set_option", &params);
    return;
}

/// Deprecated since API level 11.
pub fn nvim_win_get_option(nvim: *Nvim, arena: std.mem.Allocator, window: Window, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try window.toObject(arena, nvim.ext_types.window_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_win_get_option", &params);
    return res;
}

/// Deprecated since API level 11.
pub fn nvim_win_set_option(nvim: *Nvim, arena: std.mem.Allocator, window: Window, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try window.toObject(arena, nvim.ext_types.window_id),
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "nvim_win_set_option", &params);
    return;
}

/// Deprecated since API level 12.
pub fn nvim_call_atomic(nvim: *Nvim, arena: std.mem.Allocator, calls: []const msgpack.MsgPackObject) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .array = @constCast(calls) },
    };
    const res = try nvim.client.request(arena, "nvim_call_atomic", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 13.
pub fn nvim_subscribe(nvim: *Nvim, arena: std.mem.Allocator, event: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(event) },
    };
    _ = try nvim.client.request(arena, "nvim_subscribe", &params);
    return;
}

/// Deprecated since API level 13.
pub fn nvim_unsubscribe(nvim: *Nvim, arena: std.mem.Allocator, event: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(event) },
    };
    _ = try nvim.client.request(arena, "nvim_unsubscribe", &params);
    return;
}

/// Deprecated since API level 13.
pub fn nvim_out_write(nvim: *Nvim, arena: std.mem.Allocator, str: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(str) },
    };
    _ = try nvim.client.request(arena, "nvim_out_write", &params);
    return;
}

/// Deprecated since API level 13.
pub fn nvim_err_write(nvim: *Nvim, arena: std.mem.Allocator, str: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(str) },
    };
    _ = try nvim.client.request(arena, "nvim_err_write", &params);
    return;
}

/// Deprecated since API level 13.
pub fn nvim_err_writeln(nvim: *Nvim, arena: std.mem.Allocator, str: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(str) },
    };
    _ = try nvim.client.request(arena, "nvim_err_writeln", &params);
    return;
}

/// Deprecated since API level 13.
pub fn nvim_notify(nvim: *Nvim, arena: std.mem.Allocator, msg: []const u8, log_level: i64, opts: []const msgpack.MsgPackMapEntry) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(msg) },
        .{ .integer = log_level },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_notify", &params);
    return res;
}

/// Since API level 12.
pub fn nvim_ui_term_event(nvim: *Nvim, arena: std.mem.Allocator, event: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(event) },
        value,
    };
    _ = try nvim.client.request(arena, "nvim_ui_term_event", &params);
    return;
}

/// Since API level 5.
pub fn nvim_create_namespace(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !i64 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_create_namespace", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 5.
pub fn nvim_get_namespaces(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
    const res = try nvim.client.request(arena, "nvim_get_namespaces", &.{});
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_buf_get_extmark_by_id(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, ns_id: i64, id: i64, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = ns_id },
        .{ .integer = id },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_extmark_by_id", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_buf_get_extmarks(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, ns_id: i64, start: msgpack.MsgPackObject, end: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = ns_id },
        start,
        end,
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_get_extmarks", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_buf_set_extmark(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, ns_id: i64, line: i64, col: i64, opts: []const msgpack.MsgPackMapEntry) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = ns_id },
        .{ .integer = line },
        .{ .integer = col },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_buf_set_extmark", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_buf_del_extmark(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, ns_id: i64, id: i64) !bool {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = ns_id },
        .{ .integer = id },
    };
    const res = try nvim.client.request(arena, "nvim_buf_del_extmark", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 5.
pub fn nvim_buf_clear_namespace(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, ns_id: i64, line_start: i64, line_end: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = ns_id },
        .{ .integer = line_start },
        .{ .integer = line_end },
    };
    _ = try nvim.client.request(arena, "nvim_buf_clear_namespace", &params);
    return;
}

/// Since API level 7.
pub fn nvim_set_decoration_provider(nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64, opts: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = ns_id },
        .{ .map = @constCast(opts) },
    };
    _ = try nvim.client.request(arena, "nvim_set_decoration_provider", &params);
    return;
}

/// Since API level 9.
pub fn nvim_get_option_value(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, opts: []const msgpack.MsgPackMapEntry) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_get_option_value", &params);
    return res;
}

/// Since API level 9.
pub fn nvim_set_option_value(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        value,
        .{ .map = @constCast(opts) },
    };
    _ = try nvim.client.request(arena, "nvim_set_option_value", &params);
    return;
}

/// Since API level 7.
pub fn nvim_get_all_options_info(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
    const res = try nvim.client.request(arena, "nvim_get_all_options_info", &.{});
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 11.
pub fn nvim_get_option_info2(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_get_option_info2", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_tabpage_list_wins(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
    };
    const res = try nvim.client.request(arena, "nvim_tabpage_list_wins", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_tabpage_get_var(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_tabpage_get_var", &params);
    return res;
}

/// Since API level 1.
pub fn nvim_tabpage_set_var(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "nvim_tabpage_set_var", &params);
    return;
}

/// Since API level 1.
pub fn nvim_tabpage_del_var(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
        .{ .string = @constCast(name) },
    };
    _ = try nvim.client.request(arena, "nvim_tabpage_del_var", &params);
    return;
}

/// Since API level 1.
pub fn nvim_tabpage_get_win(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage) !Window {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
    };
    const res = try nvim.client.request(arena, "nvim_tabpage_get_win", &params);
    return switch (res) {
        .extension => |ext| try Window.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Since API level 12.
pub fn nvim_tabpage_set_win(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage, win: Window) !void {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    _ = try nvim.client.request(arena, "nvim_tabpage_set_win", &params);
    return;
}

/// Since API level 1.
pub fn nvim_tabpage_get_number(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
    };
    const res = try nvim.client.request(arena, "nvim_tabpage_get_number", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_tabpage_is_valid(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage) !bool {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
    };
    const res = try nvim.client.request(arena, "nvim_tabpage_is_valid", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 14.
pub fn nvim_open_tabpage(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, enter: bool, config: []const msgpack.MsgPackMapEntry) !Tabpage {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .boolean = enter },
        .{ .map = @constCast(config) },
    };
    const res = try nvim.client.request(arena, "nvim_open_tabpage", &params);
    return switch (res) {
        .extension => |ext| try Tabpage.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_ui_attach(nvim: *Nvim, arena: std.mem.Allocator, width: i64, height: i64, options: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = width },
        .{ .integer = height },
        .{ .map = @constCast(options) },
    };
    _ = try nvim.client.request(arena, "nvim_ui_attach", &params);
    return;
}

/// Deprecated since API level 1.
pub fn ui_attach(nvim: *Nvim, arena: std.mem.Allocator, width: i64, height: i64, enable_rgb: bool) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = width },
        .{ .integer = height },
        .{ .boolean = enable_rgb },
    };
    _ = try nvim.client.request(arena, "ui_attach", &params);
    return;
}

/// Since API level 11.
pub fn nvim_ui_set_focus(nvim: *Nvim, arena: std.mem.Allocator, gained: bool) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .boolean = gained },
    };
    _ = try nvim.client.request(arena, "nvim_ui_set_focus", &params);
    return;
}

/// Since API level 1.
pub fn nvim_ui_detach(nvim: *Nvim, arena: std.mem.Allocator) !void {
    _ = try nvim.client.request(arena, "nvim_ui_detach", &.{});
    return;
}

/// Since API level 1.
pub fn nvim_ui_try_resize(nvim: *Nvim, arena: std.mem.Allocator, width: i64, height: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = width },
        .{ .integer = height },
    };
    _ = try nvim.client.request(arena, "nvim_ui_try_resize", &params);
    return;
}

/// Since API level 1.
pub fn nvim_ui_set_option(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "nvim_ui_set_option", &params);
    return;
}

/// Since API level 6.
pub fn nvim_ui_try_resize_grid(nvim: *Nvim, arena: std.mem.Allocator, grid: i64, width: i64, height: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = grid },
        .{ .integer = width },
        .{ .integer = height },
    };
    _ = try nvim.client.request(arena, "nvim_ui_try_resize_grid", &params);
    return;
}

/// Since API level 6.
pub fn nvim_ui_pum_set_height(nvim: *Nvim, arena: std.mem.Allocator, height: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = height },
    };
    _ = try nvim.client.request(arena, "nvim_ui_pum_set_height", &params);
    return;
}

/// Since API level 7.
pub fn nvim_ui_pum_set_bounds(nvim: *Nvim, arena: std.mem.Allocator, width: f64, height: f64, row: f64, col: f64) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .float64 = width },
        .{ .float64 = height },
        .{ .float64 = row },
        .{ .float64 = col },
    };
    _ = try nvim.client.request(arena, "nvim_ui_pum_set_bounds", &params);
    return;
}

/// Since API level 14.
pub fn nvim_ui_send(nvim: *Nvim, arena: std.mem.Allocator, content: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(content) },
    };
    _ = try nvim.client.request(arena, "nvim_ui_send", &params);
    return;
}

/// Since API level 7.
pub fn nvim_get_hl_id_by_name(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !i64 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_get_hl_id_by_name", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 11.
pub fn nvim_get_hl(nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = ns_id },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_get_hl", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_set_hl(nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64, name: []const u8, val: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = ns_id },
        .{ .string = @constCast(name) },
        .{ .map = @constCast(val) },
    };
    _ = try nvim.client.request(arena, "nvim_set_hl", &params);
    return;
}

/// Since API level 12.
pub fn nvim_get_hl_ns(nvim: *Nvim, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) !i64 {
    const params = [_]msgpack.MsgPackObject{
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_get_hl_ns", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 10.
pub fn nvim_set_hl_ns(nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = ns_id },
    };
    _ = try nvim.client.request(arena, "nvim_set_hl_ns", &params);
    return;
}

/// Since API level 10.
pub fn nvim_set_hl_ns_fast(nvim: *Nvim, arena: std.mem.Allocator, ns_id: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = ns_id },
    };
    _ = try nvim.client.request(arena, "nvim_set_hl_ns_fast", &params);
    return;
}

/// Since API level 1.
pub fn nvim_feedkeys(nvim: *Nvim, arena: std.mem.Allocator, keys: []const u8, mode: []const u8, escape_ks: bool) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(keys) },
        .{ .string = @constCast(mode) },
        .{ .boolean = escape_ks },
    };
    _ = try nvim.client.request(arena, "nvim_feedkeys", &params);
    return;
}

/// Since API level 1.
pub fn nvim_input(nvim: *Nvim, arena: std.mem.Allocator, keys: []const u8) !i64 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(keys) },
    };
    const res = try nvim.client.request(arena, "nvim_input", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 6.
pub fn nvim_input_mouse(nvim: *Nvim, arena: std.mem.Allocator, button: []const u8, action: []const u8, modifier: []const u8, grid: i64, row: i64, col: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(button) },
        .{ .string = @constCast(action) },
        .{ .string = @constCast(modifier) },
        .{ .integer = grid },
        .{ .integer = row },
        .{ .integer = col },
    };
    _ = try nvim.client.request(arena, "nvim_input_mouse", &params);
    return;
}

/// Since API level 1.
pub fn nvim_replace_termcodes(nvim: *Nvim, arena: std.mem.Allocator, str: []const u8, from_part: bool, do_lt: bool, special: bool) ![]u8 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(str) },
        .{ .boolean = from_part },
        .{ .boolean = do_lt },
        .{ .boolean = special },
    };
    const res = try nvim.client.request(arena, "nvim_replace_termcodes", &params);
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_exec_lua(nvim: *Nvim, arena: std.mem.Allocator, code: []const u8, args: []const msgpack.MsgPackObject) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(code) },
        .{ .array = @constCast(args) },
    };
    const res = try nvim.client.request(arena, "nvim_exec_lua", &params);
    return res;
}

/// Since API level 1.
pub fn nvim_strwidth(nvim: *Nvim, arena: std.mem.Allocator, text: []const u8) !i64 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(text) },
    };
    const res = try nvim.client.request(arena, "nvim_strwidth", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_list_runtime_paths(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "nvim_list_runtime_paths", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_get_runtime_file(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, all: bool) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        .{ .boolean = all },
    };
    const res = try nvim.client.request(arena, "nvim_get_runtime_file", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_set_current_dir(nvim: *Nvim, arena: std.mem.Allocator, dir: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(dir) },
    };
    _ = try nvim.client.request(arena, "nvim_set_current_dir", &params);
    return;
}

/// Since API level 1.
pub fn nvim_get_current_line(nvim: *Nvim, arena: std.mem.Allocator) ![]u8 {
    const res = try nvim.client.request(arena, "nvim_get_current_line", &.{});
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_set_current_line(nvim: *Nvim, arena: std.mem.Allocator, line: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(line) },
    };
    _ = try nvim.client.request(arena, "nvim_set_current_line", &params);
    return;
}

/// Since API level 1.
pub fn nvim_del_current_line(nvim: *Nvim, arena: std.mem.Allocator) !void {
    _ = try nvim.client.request(arena, "nvim_del_current_line", &.{});
    return;
}

/// Since API level 1.
pub fn nvim_get_var(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_get_var", &params);
    return res;
}

/// Since API level 1.
pub fn nvim_set_var(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "nvim_set_var", &params);
    return;
}

/// Since API level 1.
pub fn nvim_del_var(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    _ = try nvim.client.request(arena, "nvim_del_var", &params);
    return;
}

/// Since API level 1.
pub fn nvim_get_vvar(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_get_vvar", &params);
    return res;
}

/// Since API level 6.
pub fn nvim_set_vvar(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "nvim_set_vvar", &params);
    return;
}

/// Since API level 7.
pub fn nvim_echo(nvim: *Nvim, arena: std.mem.Allocator, chunks: []const msgpack.MsgPackObject, history: bool, opts: []const msgpack.MsgPackMapEntry) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .array = @constCast(chunks) },
        .{ .boolean = history },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_echo", &params);
    return res;
}

/// Since API level 1.
pub fn nvim_list_bufs(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "nvim_list_bufs", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_get_current_buf(nvim: *Nvim, arena: std.mem.Allocator) !Buffer {
    const res = try nvim.client.request(arena, "nvim_get_current_buf", &.{});
    return switch (res) {
        .extension => |ext| try Buffer.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_set_current_buf(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    _ = try nvim.client.request(arena, "nvim_set_current_buf", &params);
    return;
}

/// Since API level 1.
pub fn nvim_list_wins(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "nvim_list_wins", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_get_current_win(nvim: *Nvim, arena: std.mem.Allocator) !Window {
    const res = try nvim.client.request(arena, "nvim_get_current_win", &.{});
    return switch (res) {
        .extension => |ext| try Window.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_set_current_win(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    _ = try nvim.client.request(arena, "nvim_set_current_win", &params);
    return;
}

/// Since API level 6.
pub fn nvim_create_buf(nvim: *Nvim, arena: std.mem.Allocator, listed: bool, scratch: bool) !Buffer {
    const params = [_]msgpack.MsgPackObject{
        .{ .boolean = listed },
        .{ .boolean = scratch },
    };
    const res = try nvim.client.request(arena, "nvim_create_buf", &params);
    return switch (res) {
        .extension => |ext| try Buffer.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_open_term(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, opts: []const msgpack.MsgPackMapEntry) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_open_term", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_chan_send(nvim: *Nvim, arena: std.mem.Allocator, chan: i64, data: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = chan },
        .{ .string = @constCast(data) },
    };
    _ = try nvim.client.request(arena, "nvim_chan_send", &params);
    return;
}

/// Since API level 1.
pub fn nvim_list_tabpages(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "nvim_list_tabpages", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_get_current_tabpage(nvim: *Nvim, arena: std.mem.Allocator) !Tabpage {
    const res = try nvim.client.request(arena, "nvim_get_current_tabpage", &.{});
    return switch (res) {
        .extension => |ext| try Tabpage.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_set_current_tabpage(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage) !void {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
    };
    _ = try nvim.client.request(arena, "nvim_set_current_tabpage", &params);
    return;
}

/// Since API level 6.
pub fn nvim_paste(nvim: *Nvim, arena: std.mem.Allocator, data: []const u8, crlf: bool, phase: i64) !bool {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(data) },
        .{ .boolean = crlf },
        .{ .integer = phase },
    };
    const res = try nvim.client.request(arena, "nvim_paste", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 6.
pub fn nvim_put(nvim: *Nvim, arena: std.mem.Allocator, lines: []const msgpack.MsgPackObject, @"type": []const u8, after: bool, follow: bool) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .array = @constCast(lines) },
        .{ .string = @constCast(@"type") },
        .{ .boolean = after },
        .{ .boolean = follow },
    };
    _ = try nvim.client.request(arena, "nvim_put", &params);
    return;
}

/// Since API level 1.
pub fn nvim_get_color_by_name(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !i64 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_get_color_by_name", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_get_color_map(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
    const res = try nvim.client.request(arena, "nvim_get_color_map", &.{});
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 6.
pub fn nvim_get_context(nvim: *Nvim, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_get_context", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 6.
pub fn nvim_load_context(nvim: *Nvim, arena: std.mem.Allocator, dict: []const msgpack.MsgPackMapEntry) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .map = @constCast(dict) },
    };
    const res = try nvim.client.request(arena, "nvim_load_context", &params);
    return res;
}

/// Since API level 2.
pub fn nvim_get_mode(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
    const res = try nvim.client.request(arena, "nvim_get_mode", &.{});
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 3.
pub fn nvim_get_keymap(nvim: *Nvim, arena: std.mem.Allocator, mode: []const u8) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(mode) },
    };
    const res = try nvim.client.request(arena, "nvim_get_keymap", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 6.
pub fn nvim_set_keymap(nvim: *Nvim, arena: std.mem.Allocator, mode: []const u8, lhs: []const u8, rhs: []const u8, opts: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(mode) },
        .{ .string = @constCast(lhs) },
        .{ .string = @constCast(rhs) },
        .{ .map = @constCast(opts) },
    };
    _ = try nvim.client.request(arena, "nvim_set_keymap", &params);
    return;
}

/// Since API level 6.
pub fn nvim_del_keymap(nvim: *Nvim, arena: std.mem.Allocator, mode: []const u8, lhs: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(mode) },
        .{ .string = @constCast(lhs) },
    };
    _ = try nvim.client.request(arena, "nvim_del_keymap", &params);
    return;
}

/// Since API level 1.
pub fn nvim_get_api_info(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "nvim_get_api_info", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 4.
pub fn nvim_set_client_info(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, version: []const msgpack.MsgPackMapEntry, @"type": []const u8, methods: []const msgpack.MsgPackMapEntry, attributes: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        .{ .map = @constCast(version) },
        .{ .string = @constCast(@"type") },
        .{ .map = @constCast(methods) },
        .{ .map = @constCast(attributes) },
    };
    _ = try nvim.client.request(arena, "nvim_set_client_info", &params);
    return;
}

/// Since API level 4.
pub fn nvim_get_chan_info(nvim: *Nvim, arena: std.mem.Allocator, chan: i64) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = chan },
    };
    const res = try nvim.client.request(arena, "nvim_get_chan_info", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 4.
pub fn nvim_list_chans(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "nvim_list_chans", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 4.
pub fn nvim_list_uis(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "nvim_list_uis", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 4.
pub fn nvim_get_proc_children(nvim: *Nvim, arena: std.mem.Allocator, pid: i64) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = pid },
    };
    const res = try nvim.client.request(arena, "nvim_get_proc_children", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 4.
pub fn nvim_get_proc(nvim: *Nvim, arena: std.mem.Allocator, pid: i64) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = pid },
    };
    const res = try nvim.client.request(arena, "nvim_get_proc", &params);
    return res;
}

/// Since API level 6.
pub fn nvim_select_popupmenu_item(nvim: *Nvim, arena: std.mem.Allocator, item: i64, insert: bool, finish: bool, opts: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = item },
        .{ .boolean = insert },
        .{ .boolean = finish },
        .{ .map = @constCast(opts) },
    };
    _ = try nvim.client.request(arena, "nvim_select_popupmenu_item", &params);
    return;
}

/// Since API level 8.
pub fn nvim_del_mark(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !bool {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_del_mark", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 8.
pub fn nvim_get_mark(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_get_mark", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 8.
pub fn nvim_eval_statusline(nvim: *Nvim, arena: std.mem.Allocator, str: []const u8, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(str) },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_eval_statusline", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 11.
pub fn nvim_exec2(nvim: *Nvim, arena: std.mem.Allocator, src: []const u8, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(src) },
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_exec2", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_command(nvim: *Nvim, arena: std.mem.Allocator, cmd: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(cmd) },
    };
    _ = try nvim.client.request(arena, "nvim_command", &params);
    return;
}

/// Since API level 1.
pub fn nvim_eval(nvim: *Nvim, arena: std.mem.Allocator, expr: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(expr) },
    };
    const res = try nvim.client.request(arena, "nvim_eval", &params);
    return res;
}

/// Since API level 1.
pub fn nvim_call_function(nvim: *Nvim, arena: std.mem.Allocator, @"fn": []const u8, args: []const msgpack.MsgPackObject) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(@"fn") },
        .{ .array = @constCast(args) },
    };
    const res = try nvim.client.request(arena, "nvim_call_function", &params);
    return res;
}

/// Since API level 4.
pub fn nvim_call_dict_function(nvim: *Nvim, arena: std.mem.Allocator, dict: msgpack.MsgPackObject, @"fn": []const u8, args: []const msgpack.MsgPackObject) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        dict,
        .{ .string = @constCast(@"fn") },
        .{ .array = @constCast(args) },
    };
    const res = try nvim.client.request(arena, "nvim_call_dict_function", &params);
    return res;
}

/// Since API level 4.
pub fn nvim_parse_expression(nvim: *Nvim, arena: std.mem.Allocator, expr: []const u8, flags: []const u8, hl: bool) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(expr) },
        .{ .string = @constCast(flags) },
        .{ .boolean = hl },
    };
    const res = try nvim.client.request(arena, "nvim_parse_expression", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 6.
pub fn nvim_open_win(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, enter: bool, config: []const msgpack.MsgPackMapEntry) !Window {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .boolean = enter },
        .{ .map = @constCast(config) },
    };
    const res = try nvim.client.request(arena, "nvim_open_win", &params);
    return switch (res) {
        .extension => |ext| try Window.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Since API level 6.
pub fn nvim_win_set_config(nvim: *Nvim, arena: std.mem.Allocator, win: Window, config: []const msgpack.MsgPackMapEntry) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .map = @constCast(config) },
    };
    _ = try nvim.client.request(arena, "nvim_win_set_config", &params);
    return;
}

/// Since API level 6.
pub fn nvim_win_get_config(nvim: *Nvim, arena: std.mem.Allocator, win: Window) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "nvim_win_get_config", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_win_get_buf(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !Buffer {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "nvim_win_get_buf", &params);
    return switch (res) {
        .extension => |ext| try Buffer.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Since API level 5.
pub fn nvim_win_set_buf(nvim: *Nvim, arena: std.mem.Allocator, win: Window, buf: Buffer) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    _ = try nvim.client.request(arena, "nvim_win_set_buf", &params);
    return;
}

/// Since API level 1.
pub fn nvim_win_get_cursor(nvim: *Nvim, arena: std.mem.Allocator, win: Window) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "nvim_win_get_cursor", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_win_set_cursor(nvim: *Nvim, arena: std.mem.Allocator, win: Window, pos: []const msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .array = @constCast(pos) },
    };
    _ = try nvim.client.request(arena, "nvim_win_set_cursor", &params);
    return;
}

/// Since API level 1.
pub fn nvim_win_get_height(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "nvim_win_get_height", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_win_set_height(nvim: *Nvim, arena: std.mem.Allocator, win: Window, height: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .integer = height },
    };
    _ = try nvim.client.request(arena, "nvim_win_set_height", &params);
    return;
}

/// Since API level 1.
pub fn nvim_win_get_width(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "nvim_win_get_width", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_win_set_width(nvim: *Nvim, arena: std.mem.Allocator, win: Window, width: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .integer = width },
    };
    _ = try nvim.client.request(arena, "nvim_win_set_width", &params);
    return;
}

/// Since API level 1.
pub fn nvim_win_get_var(nvim: *Nvim, arena: std.mem.Allocator, win: Window, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "nvim_win_get_var", &params);
    return res;
}

/// Since API level 1.
pub fn nvim_win_set_var(nvim: *Nvim, arena: std.mem.Allocator, win: Window, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "nvim_win_set_var", &params);
    return;
}

/// Since API level 1.
pub fn nvim_win_del_var(nvim: *Nvim, arena: std.mem.Allocator, win: Window, name: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .string = @constCast(name) },
    };
    _ = try nvim.client.request(arena, "nvim_win_del_var", &params);
    return;
}

/// Since API level 1.
pub fn nvim_win_get_position(nvim: *Nvim, arena: std.mem.Allocator, win: Window) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "nvim_win_get_position", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_win_get_tabpage(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !Tabpage {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "nvim_win_get_tabpage", &params);
    return switch (res) {
        .extension => |ext| try Tabpage.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_win_get_number(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "nvim_win_get_number", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Since API level 1.
pub fn nvim_win_is_valid(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !bool {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "nvim_win_is_valid", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Since API level 7.
pub fn nvim_win_hide(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    _ = try nvim.client.request(arena, "nvim_win_hide", &params);
    return;
}

/// Since API level 6.
pub fn nvim_win_close(nvim: *Nvim, arena: std.mem.Allocator, win: Window, force: bool) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .boolean = force },
    };
    _ = try nvim.client.request(arena, "nvim_win_close", &params);
    return;
}

/// Since API level 7.
pub fn nvim_win_call(nvim: *Nvim, arena: std.mem.Allocator, win: Window, fun: i64) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .integer = fun },
    };
    const res = try nvim.client.request(arena, "nvim_win_call", &params);
    return res;
}

/// Since API level 10.
pub fn nvim_win_set_hl_ns(nvim: *Nvim, arena: std.mem.Allocator, win: Window, ns_id: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .integer = ns_id },
    };
    _ = try nvim.client.request(arena, "nvim_win_set_hl_ns", &params);
    return;
}

/// Since API level 12.
pub fn nvim_win_text_height(nvim: *Nvim, arena: std.mem.Allocator, win: Window, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .map = @constCast(opts) },
    };
    const res = try nvim.client.request(arena, "nvim_win_text_height", &params);
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn buffer_line_count(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "buffer_line_count", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn buffer_get_lines(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, start: i64, end: i64, strict_indexing: bool) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = start },
        .{ .integer = end },
        .{ .boolean = strict_indexing },
    };
    const res = try nvim.client.request(arena, "buffer_get_lines", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn buffer_set_lines(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, start: i64, end: i64, strict_indexing: bool, replacement: []const msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = start },
        .{ .integer = end },
        .{ .boolean = strict_indexing },
        .{ .array = @constCast(replacement) },
    };
    _ = try nvim.client.request(arena, "buffer_set_lines", &params);
    return;
}

/// Deprecated since API level 1.
pub fn buffer_get_var(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "buffer_get_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn buffer_get_name(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) ![]u8 {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "buffer_get_name", &params);
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn buffer_set_name(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    _ = try nvim.client.request(arena, "buffer_set_name", &params);
    return;
}

/// Deprecated since API level 1.
pub fn buffer_is_valid(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) !bool {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "buffer_is_valid", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn buffer_get_mark(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer, name: []const u8) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "buffer_get_mark", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_command_output(nvim: *Nvim, arena: std.mem.Allocator, command: []const u8) ![]u8 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(command) },
    };
    const res = try nvim.client.request(arena, "vim_command_output", &params);
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn buffer_get_number(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
    };
    const res = try nvim.client.request(arena, "buffer_get_number", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn buffer_clear_highlight(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, ns_id: i64, line_start: i64, line_end: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = ns_id },
        .{ .integer = line_start },
        .{ .integer = line_end },
    };
    _ = try nvim.client.request(arena, "buffer_clear_highlight", &params);
    return;
}

/// Deprecated since API level 1.
pub fn buffer_add_highlight(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, ns_id: i64, hl_group: []const u8, line: i64, col_start: i64, col_end: i64) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .integer = ns_id },
        .{ .string = @constCast(hl_group) },
        .{ .integer = line },
        .{ .integer = col_start },
        .{ .integer = col_end },
    };
    const res = try nvim.client.request(arena, "buffer_add_highlight", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_set_option(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "vim_set_option", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_get_option(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "vim_get_option", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn buffer_get_option(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "buffer_get_option", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn buffer_set_option(nvim: *Nvim, arena: std.mem.Allocator, buffer: Buffer, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try buffer.toObject(arena, nvim.ext_types.buffer_id),
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "buffer_set_option", &params);
    return;
}

/// Deprecated since API level 1.
pub fn window_get_option(nvim: *Nvim, arena: std.mem.Allocator, window: Window, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try window.toObject(arena, nvim.ext_types.window_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "window_get_option", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn window_set_option(nvim: *Nvim, arena: std.mem.Allocator, window: Window, name: []const u8, value: msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try window.toObject(arena, nvim.ext_types.window_id),
        .{ .string = @constCast(name) },
        value,
    };
    _ = try nvim.client.request(arena, "window_set_option", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_subscribe(nvim: *Nvim, arena: std.mem.Allocator, event: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(event) },
    };
    _ = try nvim.client.request(arena, "vim_subscribe", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_unsubscribe(nvim: *Nvim, arena: std.mem.Allocator, event: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(event) },
    };
    _ = try nvim.client.request(arena, "vim_unsubscribe", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_out_write(nvim: *Nvim, arena: std.mem.Allocator, str: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(str) },
    };
    _ = try nvim.client.request(arena, "vim_out_write", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_err_write(nvim: *Nvim, arena: std.mem.Allocator, str: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(str) },
    };
    _ = try nvim.client.request(arena, "vim_err_write", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_report_error(nvim: *Nvim, arena: std.mem.Allocator, str: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(str) },
    };
    _ = try nvim.client.request(arena, "vim_report_error", &params);
    return;
}

/// Deprecated since API level 1.
pub fn tabpage_get_windows(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
    };
    const res = try nvim.client.request(arena, "tabpage_get_windows", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn tabpage_get_var(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "tabpage_get_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn tabpage_get_window(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage) !Window {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
    };
    const res = try nvim.client.request(arena, "tabpage_get_window", &params);
    return switch (res) {
        .extension => |ext| try Window.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn tabpage_is_valid(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage) !bool {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
    };
    const res = try nvim.client.request(arena, "tabpage_is_valid", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn ui_detach(nvim: *Nvim, arena: std.mem.Allocator) !void {
    _ = try nvim.client.request(arena, "ui_detach", &.{});
    return;
}

/// Deprecated since API level 1.
pub fn ui_try_resize(nvim: *Nvim, arena: std.mem.Allocator, width: i64, height: i64) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .integer = width },
        .{ .integer = height },
    };
    const res = try nvim.client.request(arena, "ui_try_resize", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn vim_feedkeys(nvim: *Nvim, arena: std.mem.Allocator, keys: []const u8, mode: []const u8, escape_ks: bool) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(keys) },
        .{ .string = @constCast(mode) },
        .{ .boolean = escape_ks },
    };
    _ = try nvim.client.request(arena, "vim_feedkeys", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_input(nvim: *Nvim, arena: std.mem.Allocator, keys: []const u8) !i64 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(keys) },
    };
    const res = try nvim.client.request(arena, "vim_input", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_replace_termcodes(nvim: *Nvim, arena: std.mem.Allocator, str: []const u8, from_part: bool, do_lt: bool, special: bool) ![]u8 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(str) },
        .{ .boolean = from_part },
        .{ .boolean = do_lt },
        .{ .boolean = special },
    };
    const res = try nvim.client.request(arena, "vim_replace_termcodes", &params);
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_strwidth(nvim: *Nvim, arena: std.mem.Allocator, text: []const u8) !i64 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(text) },
    };
    const res = try nvim.client.request(arena, "vim_strwidth", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_list_runtime_paths(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "vim_list_runtime_paths", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_change_directory(nvim: *Nvim, arena: std.mem.Allocator, dir: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(dir) },
    };
    _ = try nvim.client.request(arena, "vim_change_directory", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_get_current_line(nvim: *Nvim, arena: std.mem.Allocator) ![]u8 {
    const res = try nvim.client.request(arena, "vim_get_current_line", &.{});
    return switch (res) {
        .string => |s| s,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_set_current_line(nvim: *Nvim, arena: std.mem.Allocator, line: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(line) },
    };
    _ = try nvim.client.request(arena, "vim_set_current_line", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_del_current_line(nvim: *Nvim, arena: std.mem.Allocator) !void {
    _ = try nvim.client.request(arena, "vim_del_current_line", &.{});
    return;
}

/// Deprecated since API level 1.
pub fn vim_get_var(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "vim_get_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn vim_get_vvar(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "vim_get_vvar", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn vim_get_buffers(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "vim_get_buffers", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_get_current_buffer(nvim: *Nvim, arena: std.mem.Allocator) !Buffer {
    const res = try nvim.client.request(arena, "vim_get_current_buffer", &.{});
    return switch (res) {
        .extension => |ext| try Buffer.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_set_current_buffer(nvim: *Nvim, arena: std.mem.Allocator, buf: Buffer) !void {
    const params = [_]msgpack.MsgPackObject{
        try buf.toObject(arena, nvim.ext_types.buffer_id),
    };
    _ = try nvim.client.request(arena, "vim_set_current_buffer", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_get_windows(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "vim_get_windows", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_get_current_window(nvim: *Nvim, arena: std.mem.Allocator) !Window {
    const res = try nvim.client.request(arena, "vim_get_current_window", &.{});
    return switch (res) {
        .extension => |ext| try Window.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_set_current_window(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    _ = try nvim.client.request(arena, "vim_set_current_window", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_get_tabpages(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "vim_get_tabpages", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_get_current_tabpage(nvim: *Nvim, arena: std.mem.Allocator) !Tabpage {
    const res = try nvim.client.request(arena, "vim_get_current_tabpage", &.{});
    return switch (res) {
        .extension => |ext| try Tabpage.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_set_current_tabpage(nvim: *Nvim, arena: std.mem.Allocator, tabpage: Tabpage) !void {
    const params = [_]msgpack.MsgPackObject{
        try tabpage.toObject(arena, nvim.ext_types.tabpage_id),
    };
    _ = try nvim.client.request(arena, "vim_set_current_tabpage", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_name_to_color(nvim: *Nvim, arena: std.mem.Allocator, name: []const u8) !i64 {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "vim_name_to_color", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_get_color_map(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
    const res = try nvim.client.request(arena, "vim_get_color_map", &.{});
    return switch (res) {
        .map => |m| m,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_get_api_info(nvim: *Nvim, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
    const res = try nvim.client.request(arena, "vim_get_api_info", &.{});
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn vim_command(nvim: *Nvim, arena: std.mem.Allocator, cmd: []const u8) !void {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(cmd) },
    };
    _ = try nvim.client.request(arena, "vim_command", &params);
    return;
}

/// Deprecated since API level 1.
pub fn vim_eval(nvim: *Nvim, arena: std.mem.Allocator, expr: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(expr) },
    };
    const res = try nvim.client.request(arena, "vim_eval", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn vim_call_function(nvim: *Nvim, arena: std.mem.Allocator, @"fn": []const u8, args: []const msgpack.MsgPackObject) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        .{ .string = @constCast(@"fn") },
        .{ .array = @constCast(args) },
    };
    const res = try nvim.client.request(arena, "vim_call_function", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn window_get_buffer(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !Buffer {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "window_get_buffer", &params);
    return switch (res) {
        .extension => |ext| try Buffer.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn window_get_cursor(nvim: *Nvim, arena: std.mem.Allocator, win: Window) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "window_get_cursor", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn window_set_cursor(nvim: *Nvim, arena: std.mem.Allocator, win: Window, pos: []const msgpack.MsgPackObject) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .array = @constCast(pos) },
    };
    _ = try nvim.client.request(arena, "window_set_cursor", &params);
    return;
}

/// Deprecated since API level 1.
pub fn window_get_height(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "window_get_height", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn window_set_height(nvim: *Nvim, arena: std.mem.Allocator, win: Window, height: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .integer = height },
    };
    _ = try nvim.client.request(arena, "window_set_height", &params);
    return;
}

/// Deprecated since API level 1.
pub fn window_get_width(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !i64 {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "window_get_width", &params);
    return switch (res) {
        .integer => |i| i,
        .unsigned_integer => |u| std.math.cast(i64, u) orelse error.UnexpectedType,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn window_set_width(nvim: *Nvim, arena: std.mem.Allocator, win: Window, width: i64) !void {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .integer = width },
    };
    _ = try nvim.client.request(arena, "window_set_width", &params);
    return;
}

/// Deprecated since API level 1.
pub fn window_get_var(nvim: *Nvim, arena: std.mem.Allocator, win: Window, name: []const u8) !msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
        .{ .string = @constCast(name) },
    };
    const res = try nvim.client.request(arena, "window_get_var", &params);
    return res;
}

/// Deprecated since API level 1.
pub fn window_get_position(nvim: *Nvim, arena: std.mem.Allocator, win: Window) ![]msgpack.MsgPackObject {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "window_get_position", &params);
    return switch (res) {
        .array => |arr| arr,
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn window_get_tabpage(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !Tabpage {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "window_get_tabpage", &params);
    return switch (res) {
        .extension => |ext| try Tabpage.decode(ext),
        else => error.UnexpectedType,
    };
}

/// Deprecated since API level 1.
pub fn window_is_valid(nvim: *Nvim, arena: std.mem.Allocator, win: Window) !bool {
    const params = [_]msgpack.MsgPackObject{
        try win.toObject(arena, nvim.ext_types.window_id),
    };
    const res = try nvim.client.request(arena, "window_is_valid", &params);
    return switch (res) {
        .boolean => |b| b,
        else => error.UnexpectedType,
    };
}

/// API namespace providing method syntax on Nvim instances (e.g. nvim.api().getLines(...)).
pub const Api = struct {
    nvim: *Nvim,
    pub fn nvim_get_autocmds(self: Api, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
        return root.nvim_get_autocmds(self.nvim, arena, opts);
    }

    pub fn nvim_create_autocmd(self: Api, arena: std.mem.Allocator, event: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !i64 {
        return root.nvim_create_autocmd(self.nvim, arena, event, opts);
    }

    pub fn nvim_del_autocmd(self: Api, arena: std.mem.Allocator, id: i64) !void {
        return root.nvim_del_autocmd(self.nvim, arena, id);
    }

    pub fn nvim_clear_autocmds(self: Api, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_clear_autocmds(self.nvim, arena, opts);
    }

    pub fn nvim_create_augroup(self: Api, arena: std.mem.Allocator, name: []const u8, opts: []const msgpack.MsgPackMapEntry) !i64 {
        return root.nvim_create_augroup(self.nvim, arena, name, opts);
    }

    pub fn nvim_del_augroup_by_id(self: Api, arena: std.mem.Allocator, id: i64) !void {
        return root.nvim_del_augroup_by_id(self.nvim, arena, id);
    }

    pub fn nvim_del_augroup_by_name(self: Api, arena: std.mem.Allocator, name: []const u8) !void {
        return root.nvim_del_augroup_by_name(self.nvim, arena, name);
    }

    pub fn nvim_exec_autocmds(self: Api, arena: std.mem.Allocator, event: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_exec_autocmds(self.nvim, arena, event, opts);
    }

    pub fn nvim_buf_line_count(self: Api, arena: std.mem.Allocator, buf: Buffer) !i64 {
        return root.nvim_buf_line_count(self.nvim, arena, buf);
    }

    pub fn nvim_buf_attach(self: Api, arena: std.mem.Allocator, buf: Buffer, send_buffer: bool, opts: []const msgpack.MsgPackMapEntry) !bool {
        return root.nvim_buf_attach(self.nvim, arena, buf, send_buffer, opts);
    }

    pub fn nvim_buf_detach(self: Api, arena: std.mem.Allocator, buf: Buffer) !bool {
        return root.nvim_buf_detach(self.nvim, arena, buf);
    }

    pub fn nvim_buf_get_lines(self: Api, arena: std.mem.Allocator, buf: Buffer, start: i64, end: i64, strict_indexing: bool) ![]msgpack.MsgPackObject {
        return root.nvim_buf_get_lines(self.nvim, arena, buf, start, end, strict_indexing);
    }

    pub fn nvim_buf_set_lines(self: Api, arena: std.mem.Allocator, buf: Buffer, start: i64, end: i64, strict_indexing: bool, replacement: []const msgpack.MsgPackObject) !void {
        return root.nvim_buf_set_lines(self.nvim, arena, buf, start, end, strict_indexing, replacement);
    }

    pub fn nvim_buf_set_text(self: Api, arena: std.mem.Allocator, buf: Buffer, start_row: i64, start_col: i64, end_row: i64, end_col: i64, replacement: []const msgpack.MsgPackObject) !void {
        return root.nvim_buf_set_text(self.nvim, arena, buf, start_row, start_col, end_row, end_col, replacement);
    }

    pub fn nvim_buf_get_text(self: Api, arena: std.mem.Allocator, buf: Buffer, start_row: i64, start_col: i64, end_row: i64, end_col: i64, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
        return root.nvim_buf_get_text(self.nvim, arena, buf, start_row, start_col, end_row, end_col, opts);
    }

    pub fn nvim_buf_get_offset(self: Api, arena: std.mem.Allocator, buf: Buffer, index: i64) !i64 {
        return root.nvim_buf_get_offset(self.nvim, arena, buf, index);
    }

    pub fn nvim_buf_get_var(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !msgpack.MsgPackObject {
        return root.nvim_buf_get_var(self.nvim, arena, buf, name);
    }

    pub fn nvim_buf_get_changedtick(self: Api, arena: std.mem.Allocator, buf: Buffer) !i64 {
        return root.nvim_buf_get_changedtick(self.nvim, arena, buf);
    }

    pub fn nvim_buf_get_keymap(self: Api, arena: std.mem.Allocator, buf: Buffer, mode: []const u8) ![]msgpack.MsgPackObject {
        return root.nvim_buf_get_keymap(self.nvim, arena, buf, mode);
    }

    pub fn nvim_buf_set_keymap(self: Api, arena: std.mem.Allocator, buf: Buffer, mode: []const u8, lhs: []const u8, rhs: []const u8, opts: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_buf_set_keymap(self.nvim, arena, buf, mode, lhs, rhs, opts);
    }

    pub fn nvim_buf_del_keymap(self: Api, arena: std.mem.Allocator, buf: Buffer, mode: []const u8, lhs: []const u8) !void {
        return root.nvim_buf_del_keymap(self.nvim, arena, buf, mode, lhs);
    }

    pub fn nvim_buf_set_var(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.nvim_buf_set_var(self.nvim, arena, buf, name, value);
    }

    pub fn nvim_buf_del_var(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !void {
        return root.nvim_buf_del_var(self.nvim, arena, buf, name);
    }

    pub fn nvim_buf_get_name(self: Api, arena: std.mem.Allocator, buf: Buffer) ![]u8 {
        return root.nvim_buf_get_name(self.nvim, arena, buf);
    }

    pub fn nvim_buf_set_name(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !void {
        return root.nvim_buf_set_name(self.nvim, arena, buf, name);
    }

    pub fn nvim_buf_is_loaded(self: Api, arena: std.mem.Allocator, buf: Buffer) !bool {
        return root.nvim_buf_is_loaded(self.nvim, arena, buf);
    }

    pub fn nvim_buf_delete(self: Api, arena: std.mem.Allocator, buf: Buffer, opts: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_buf_delete(self.nvim, arena, buf, opts);
    }

    pub fn nvim_buf_is_valid(self: Api, arena: std.mem.Allocator, buf: Buffer) !bool {
        return root.nvim_buf_is_valid(self.nvim, arena, buf);
    }

    pub fn nvim_buf_del_mark(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !bool {
        return root.nvim_buf_del_mark(self.nvim, arena, buf, name);
    }

    pub fn nvim_buf_set_mark(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8, line: i64, col: i64, opts: []const msgpack.MsgPackMapEntry) !bool {
        return root.nvim_buf_set_mark(self.nvim, arena, buf, name, line, col, opts);
    }

    pub fn nvim_buf_get_mark(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8) ![]msgpack.MsgPackObject {
        return root.nvim_buf_get_mark(self.nvim, arena, buf, name);
    }

    pub fn nvim_buf_call(self: Api, arena: std.mem.Allocator, buf: Buffer, fun: i64) !msgpack.MsgPackObject {
        return root.nvim_buf_call(self.nvim, arena, buf, fun);
    }

    pub fn nvim_parse_cmd(self: Api, arena: std.mem.Allocator, str: []const u8, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return root.nvim_parse_cmd(self.nvim, arena, str, opts);
    }

    pub fn nvim_cmd(self: Api, arena: std.mem.Allocator, cmd: []const msgpack.MsgPackMapEntry, opts: []const msgpack.MsgPackMapEntry) ![]u8 {
        return root.nvim_cmd(self.nvim, arena, cmd, opts);
    }

    pub fn nvim_create_user_command(self: Api, arena: std.mem.Allocator, name: []const u8, cmd: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_create_user_command(self.nvim, arena, name, cmd, opts);
    }

    pub fn nvim_del_user_command(self: Api, arena: std.mem.Allocator, name: []const u8) !void {
        return root.nvim_del_user_command(self.nvim, arena, name);
    }

    pub fn nvim_buf_create_user_command(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8, cmd: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_buf_create_user_command(self.nvim, arena, buf, name, cmd, opts);
    }

    pub fn nvim_buf_del_user_command(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !void {
        return root.nvim_buf_del_user_command(self.nvim, arena, buf, name);
    }

    pub fn nvim_get_commands(self: Api, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_commands(self.nvim, arena, opts);
    }

    pub fn nvim_buf_get_commands(self: Api, arena: std.mem.Allocator, buf: Buffer, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return root.nvim_buf_get_commands(self.nvim, arena, buf, opts);
    }

    pub fn nvim_exec(self: Api, arena: std.mem.Allocator, src: []const u8, output: bool) ![]u8 {
        return root.nvim_exec(self.nvim, arena, src, output);
    }

    pub fn nvim_command_output(self: Api, arena: std.mem.Allocator, command: []const u8) ![]u8 {
        return root.nvim_command_output(self.nvim, arena, command);
    }

    pub fn nvim_execute_lua(self: Api, arena: std.mem.Allocator, code: []const u8, args: []const msgpack.MsgPackObject) !msgpack.MsgPackObject {
        return root.nvim_execute_lua(self.nvim, arena, code, args);
    }

    pub fn nvim_buf_get_number(self: Api, arena: std.mem.Allocator, buffer: Buffer) !i64 {
        return root.nvim_buf_get_number(self.nvim, arena, buffer);
    }

    pub fn nvim_buf_clear_highlight(self: Api, arena: std.mem.Allocator, buffer: Buffer, ns_id: i64, line_start: i64, line_end: i64) !void {
        return root.nvim_buf_clear_highlight(self.nvim, arena, buffer, ns_id, line_start, line_end);
    }

    pub fn nvim_buf_add_highlight(self: Api, arena: std.mem.Allocator, buffer: Buffer, ns_id: i64, hl_group: []const u8, line: i64, col_start: i64, col_end: i64) !i64 {
        return root.nvim_buf_add_highlight(self.nvim, arena, buffer, ns_id, hl_group, line, col_start, col_end);
    }

    pub fn nvim_buf_set_virtual_text(self: Api, arena: std.mem.Allocator, buffer: Buffer, src_id: i64, line: i64, chunks: []const msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !i64 {
        return root.nvim_buf_set_virtual_text(self.nvim, arena, buffer, src_id, line, chunks, opts);
    }

    pub fn nvim_get_hl_by_id(self: Api, arena: std.mem.Allocator, hl_id: i64, rgb: bool) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_hl_by_id(self.nvim, arena, hl_id, rgb);
    }

    pub fn nvim_get_hl_by_name(self: Api, arena: std.mem.Allocator, name: []const u8, rgb: bool) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_hl_by_name(self.nvim, arena, name, rgb);
    }

    pub fn buffer_insert(self: Api, arena: std.mem.Allocator, buffer: Buffer, lnum: i64, lines: []const msgpack.MsgPackObject) !void {
        return root.buffer_insert(self.nvim, arena, buffer, lnum, lines);
    }

    pub fn buffer_get_line(self: Api, arena: std.mem.Allocator, buffer: Buffer, index: i64) ![]u8 {
        return root.buffer_get_line(self.nvim, arena, buffer, index);
    }

    pub fn buffer_set_line(self: Api, arena: std.mem.Allocator, buffer: Buffer, index: i64, line: []const u8) !void {
        return root.buffer_set_line(self.nvim, arena, buffer, index, line);
    }

    pub fn buffer_del_line(self: Api, arena: std.mem.Allocator, buffer: Buffer, index: i64) !void {
        return root.buffer_del_line(self.nvim, arena, buffer, index);
    }

    pub fn buffer_get_line_slice(self: Api, arena: std.mem.Allocator, buffer: Buffer, start: i64, end: i64, include_start: bool, include_end: bool) ![]msgpack.MsgPackObject {
        return root.buffer_get_line_slice(self.nvim, arena, buffer, start, end, include_start, include_end);
    }

    pub fn buffer_set_line_slice(self: Api, arena: std.mem.Allocator, buffer: Buffer, start: i64, end: i64, include_start: bool, include_end: bool, replacement: []const msgpack.MsgPackObject) !void {
        return root.buffer_set_line_slice(self.nvim, arena, buffer, start, end, include_start, include_end, replacement);
    }

    pub fn buffer_set_var(self: Api, arena: std.mem.Allocator, buffer: Buffer, name: []const u8, value: msgpack.MsgPackObject) !msgpack.MsgPackObject {
        return root.buffer_set_var(self.nvim, arena, buffer, name, value);
    }

    pub fn buffer_del_var(self: Api, arena: std.mem.Allocator, buffer: Buffer, name: []const u8) !msgpack.MsgPackObject {
        return root.buffer_del_var(self.nvim, arena, buffer, name);
    }

    pub fn window_set_var(self: Api, arena: std.mem.Allocator, window: Window, name: []const u8, value: msgpack.MsgPackObject) !msgpack.MsgPackObject {
        return root.window_set_var(self.nvim, arena, window, name, value);
    }

    pub fn window_del_var(self: Api, arena: std.mem.Allocator, window: Window, name: []const u8) !msgpack.MsgPackObject {
        return root.window_del_var(self.nvim, arena, window, name);
    }

    pub fn tabpage_set_var(self: Api, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8, value: msgpack.MsgPackObject) !msgpack.MsgPackObject {
        return root.tabpage_set_var(self.nvim, arena, tabpage, name, value);
    }

    pub fn tabpage_del_var(self: Api, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8) !msgpack.MsgPackObject {
        return root.tabpage_del_var(self.nvim, arena, tabpage, name);
    }

    pub fn vim_set_var(self: Api, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !msgpack.MsgPackObject {
        return root.vim_set_var(self.nvim, arena, name, value);
    }

    pub fn vim_del_var(self: Api, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return root.vim_del_var(self.nvim, arena, name);
    }

    pub fn nvim_get_option_info(self: Api, arena: std.mem.Allocator, name: []const u8) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_option_info(self.nvim, arena, name);
    }

    pub fn nvim_set_option(self: Api, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.nvim_set_option(self.nvim, arena, name, value);
    }

    pub fn nvim_get_option(self: Api, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return root.nvim_get_option(self.nvim, arena, name);
    }

    pub fn nvim_buf_get_option(self: Api, arena: std.mem.Allocator, buffer: Buffer, name: []const u8) !msgpack.MsgPackObject {
        return root.nvim_buf_get_option(self.nvim, arena, buffer, name);
    }

    pub fn nvim_buf_set_option(self: Api, arena: std.mem.Allocator, buffer: Buffer, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.nvim_buf_set_option(self.nvim, arena, buffer, name, value);
    }

    pub fn nvim_win_get_option(self: Api, arena: std.mem.Allocator, window: Window, name: []const u8) !msgpack.MsgPackObject {
        return root.nvim_win_get_option(self.nvim, arena, window, name);
    }

    pub fn nvim_win_set_option(self: Api, arena: std.mem.Allocator, window: Window, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.nvim_win_set_option(self.nvim, arena, window, name, value);
    }

    pub fn nvim_call_atomic(self: Api, arena: std.mem.Allocator, calls: []const msgpack.MsgPackObject) ![]msgpack.MsgPackObject {
        return root.nvim_call_atomic(self.nvim, arena, calls);
    }

    pub fn nvim_subscribe(self: Api, arena: std.mem.Allocator, event: []const u8) !void {
        return root.nvim_subscribe(self.nvim, arena, event);
    }

    pub fn nvim_unsubscribe(self: Api, arena: std.mem.Allocator, event: []const u8) !void {
        return root.nvim_unsubscribe(self.nvim, arena, event);
    }

    pub fn nvim_out_write(self: Api, arena: std.mem.Allocator, str: []const u8) !void {
        return root.nvim_out_write(self.nvim, arena, str);
    }

    pub fn nvim_err_write(self: Api, arena: std.mem.Allocator, str: []const u8) !void {
        return root.nvim_err_write(self.nvim, arena, str);
    }

    pub fn nvim_err_writeln(self: Api, arena: std.mem.Allocator, str: []const u8) !void {
        return root.nvim_err_writeln(self.nvim, arena, str);
    }

    pub fn nvim_notify(self: Api, arena: std.mem.Allocator, msg: []const u8, log_level: i64, opts: []const msgpack.MsgPackMapEntry) !msgpack.MsgPackObject {
        return root.nvim_notify(self.nvim, arena, msg, log_level, opts);
    }

    pub fn nvim_ui_term_event(self: Api, arena: std.mem.Allocator, event: []const u8, value: msgpack.MsgPackObject) !void {
        return root.nvim_ui_term_event(self.nvim, arena, event, value);
    }

    pub fn nvim_create_namespace(self: Api, arena: std.mem.Allocator, name: []const u8) !i64 {
        return root.nvim_create_namespace(self.nvim, arena, name);
    }

    pub fn nvim_get_namespaces(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_namespaces(self.nvim, arena);
    }

    pub fn nvim_buf_get_extmark_by_id(self: Api, arena: std.mem.Allocator, buf: Buffer, ns_id: i64, id: i64, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
        return root.nvim_buf_get_extmark_by_id(self.nvim, arena, buf, ns_id, id, opts);
    }

    pub fn nvim_buf_get_extmarks(self: Api, arena: std.mem.Allocator, buf: Buffer, ns_id: i64, start: msgpack.MsgPackObject, end: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
        return root.nvim_buf_get_extmarks(self.nvim, arena, buf, ns_id, start, end, opts);
    }

    pub fn nvim_buf_set_extmark(self: Api, arena: std.mem.Allocator, buf: Buffer, ns_id: i64, line: i64, col: i64, opts: []const msgpack.MsgPackMapEntry) !i64 {
        return root.nvim_buf_set_extmark(self.nvim, arena, buf, ns_id, line, col, opts);
    }

    pub fn nvim_buf_del_extmark(self: Api, arena: std.mem.Allocator, buf: Buffer, ns_id: i64, id: i64) !bool {
        return root.nvim_buf_del_extmark(self.nvim, arena, buf, ns_id, id);
    }

    pub fn nvim_buf_clear_namespace(self: Api, arena: std.mem.Allocator, buf: Buffer, ns_id: i64, line_start: i64, line_end: i64) !void {
        return root.nvim_buf_clear_namespace(self.nvim, arena, buf, ns_id, line_start, line_end);
    }

    pub fn nvim_set_decoration_provider(self: Api, arena: std.mem.Allocator, ns_id: i64, opts: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_set_decoration_provider(self.nvim, arena, ns_id, opts);
    }

    pub fn nvim_get_option_value(self: Api, arena: std.mem.Allocator, name: []const u8, opts: []const msgpack.MsgPackMapEntry) !msgpack.MsgPackObject {
        return root.nvim_get_option_value(self.nvim, arena, name, opts);
    }

    pub fn nvim_set_option_value(self: Api, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject, opts: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_set_option_value(self.nvim, arena, name, value, opts);
    }

    pub fn nvim_get_all_options_info(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_all_options_info(self.nvim, arena);
    }

    pub fn nvim_get_option_info2(self: Api, arena: std.mem.Allocator, name: []const u8, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_option_info2(self.nvim, arena, name, opts);
    }

    pub fn nvim_tabpage_list_wins(self: Api, arena: std.mem.Allocator, tabpage: Tabpage) ![]msgpack.MsgPackObject {
        return root.nvim_tabpage_list_wins(self.nvim, arena, tabpage);
    }

    pub fn nvim_tabpage_get_var(self: Api, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8) !msgpack.MsgPackObject {
        return root.nvim_tabpage_get_var(self.nvim, arena, tabpage, name);
    }

    pub fn nvim_tabpage_set_var(self: Api, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.nvim_tabpage_set_var(self.nvim, arena, tabpage, name, value);
    }

    pub fn nvim_tabpage_del_var(self: Api, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8) !void {
        return root.nvim_tabpage_del_var(self.nvim, arena, tabpage, name);
    }

    pub fn nvim_tabpage_get_win(self: Api, arena: std.mem.Allocator, tabpage: Tabpage) !Window {
        return root.nvim_tabpage_get_win(self.nvim, arena, tabpage);
    }

    pub fn nvim_tabpage_set_win(self: Api, arena: std.mem.Allocator, tabpage: Tabpage, win: Window) !void {
        return root.nvim_tabpage_set_win(self.nvim, arena, tabpage, win);
    }

    pub fn nvim_tabpage_get_number(self: Api, arena: std.mem.Allocator, tabpage: Tabpage) !i64 {
        return root.nvim_tabpage_get_number(self.nvim, arena, tabpage);
    }

    pub fn nvim_tabpage_is_valid(self: Api, arena: std.mem.Allocator, tabpage: Tabpage) !bool {
        return root.nvim_tabpage_is_valid(self.nvim, arena, tabpage);
    }

    pub fn nvim_open_tabpage(self: Api, arena: std.mem.Allocator, buf: Buffer, enter: bool, config: []const msgpack.MsgPackMapEntry) !Tabpage {
        return root.nvim_open_tabpage(self.nvim, arena, buf, enter, config);
    }

    pub fn nvim_ui_attach(self: Api, arena: std.mem.Allocator, width: i64, height: i64, options: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_ui_attach(self.nvim, arena, width, height, options);
    }

    pub fn ui_attach(self: Api, arena: std.mem.Allocator, width: i64, height: i64, enable_rgb: bool) !void {
        return root.ui_attach(self.nvim, arena, width, height, enable_rgb);
    }

    pub fn nvim_ui_set_focus(self: Api, arena: std.mem.Allocator, gained: bool) !void {
        return root.nvim_ui_set_focus(self.nvim, arena, gained);
    }

    pub fn nvim_ui_detach(self: Api, arena: std.mem.Allocator) !void {
        return root.nvim_ui_detach(self.nvim, arena);
    }

    pub fn nvim_ui_try_resize(self: Api, arena: std.mem.Allocator, width: i64, height: i64) !void {
        return root.nvim_ui_try_resize(self.nvim, arena, width, height);
    }

    pub fn nvim_ui_set_option(self: Api, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.nvim_ui_set_option(self.nvim, arena, name, value);
    }

    pub fn nvim_ui_try_resize_grid(self: Api, arena: std.mem.Allocator, grid: i64, width: i64, height: i64) !void {
        return root.nvim_ui_try_resize_grid(self.nvim, arena, grid, width, height);
    }

    pub fn nvim_ui_pum_set_height(self: Api, arena: std.mem.Allocator, height: i64) !void {
        return root.nvim_ui_pum_set_height(self.nvim, arena, height);
    }

    pub fn nvim_ui_pum_set_bounds(self: Api, arena: std.mem.Allocator, width: f64, height: f64, row: f64, col: f64) !void {
        return root.nvim_ui_pum_set_bounds(self.nvim, arena, width, height, row, col);
    }

    pub fn nvim_ui_send(self: Api, arena: std.mem.Allocator, content: []const u8) !void {
        return root.nvim_ui_send(self.nvim, arena, content);
    }

    pub fn nvim_get_hl_id_by_name(self: Api, arena: std.mem.Allocator, name: []const u8) !i64 {
        return root.nvim_get_hl_id_by_name(self.nvim, arena, name);
    }

    pub fn nvim_get_hl(self: Api, arena: std.mem.Allocator, ns_id: i64, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_hl(self.nvim, arena, ns_id, opts);
    }

    pub fn nvim_set_hl(self: Api, arena: std.mem.Allocator, ns_id: i64, name: []const u8, val: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_set_hl(self.nvim, arena, ns_id, name, val);
    }

    pub fn nvim_get_hl_ns(self: Api, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) !i64 {
        return root.nvim_get_hl_ns(self.nvim, arena, opts);
    }

    pub fn nvim_set_hl_ns(self: Api, arena: std.mem.Allocator, ns_id: i64) !void {
        return root.nvim_set_hl_ns(self.nvim, arena, ns_id);
    }

    pub fn nvim_set_hl_ns_fast(self: Api, arena: std.mem.Allocator, ns_id: i64) !void {
        return root.nvim_set_hl_ns_fast(self.nvim, arena, ns_id);
    }

    pub fn nvim_feedkeys(self: Api, arena: std.mem.Allocator, keys: []const u8, mode: []const u8, escape_ks: bool) !void {
        return root.nvim_feedkeys(self.nvim, arena, keys, mode, escape_ks);
    }

    pub fn nvim_input(self: Api, arena: std.mem.Allocator, keys: []const u8) !i64 {
        return root.nvim_input(self.nvim, arena, keys);
    }

    pub fn nvim_input_mouse(self: Api, arena: std.mem.Allocator, button: []const u8, action: []const u8, modifier: []const u8, grid: i64, row: i64, col: i64) !void {
        return root.nvim_input_mouse(self.nvim, arena, button, action, modifier, grid, row, col);
    }

    pub fn nvim_replace_termcodes(self: Api, arena: std.mem.Allocator, str: []const u8, from_part: bool, do_lt: bool, special: bool) ![]u8 {
        return root.nvim_replace_termcodes(self.nvim, arena, str, from_part, do_lt, special);
    }

    pub fn nvim_exec_lua(self: Api, arena: std.mem.Allocator, code: []const u8, args: []const msgpack.MsgPackObject) !msgpack.MsgPackObject {
        return root.nvim_exec_lua(self.nvim, arena, code, args);
    }

    pub fn nvim_strwidth(self: Api, arena: std.mem.Allocator, text: []const u8) !i64 {
        return root.nvim_strwidth(self.nvim, arena, text);
    }

    pub fn nvim_list_runtime_paths(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.nvim_list_runtime_paths(self.nvim, arena);
    }

    pub fn nvim_get_runtime_file(self: Api, arena: std.mem.Allocator, name: []const u8, all: bool) ![]msgpack.MsgPackObject {
        return root.nvim_get_runtime_file(self.nvim, arena, name, all);
    }

    pub fn nvim_set_current_dir(self: Api, arena: std.mem.Allocator, dir: []const u8) !void {
        return root.nvim_set_current_dir(self.nvim, arena, dir);
    }

    pub fn nvim_get_current_line(self: Api, arena: std.mem.Allocator) ![]u8 {
        return root.nvim_get_current_line(self.nvim, arena);
    }

    pub fn nvim_set_current_line(self: Api, arena: std.mem.Allocator, line: []const u8) !void {
        return root.nvim_set_current_line(self.nvim, arena, line);
    }

    pub fn nvim_del_current_line(self: Api, arena: std.mem.Allocator) !void {
        return root.nvim_del_current_line(self.nvim, arena);
    }

    pub fn nvim_get_var(self: Api, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return root.nvim_get_var(self.nvim, arena, name);
    }

    pub fn nvim_set_var(self: Api, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.nvim_set_var(self.nvim, arena, name, value);
    }

    pub fn nvim_del_var(self: Api, arena: std.mem.Allocator, name: []const u8) !void {
        return root.nvim_del_var(self.nvim, arena, name);
    }

    pub fn nvim_get_vvar(self: Api, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return root.nvim_get_vvar(self.nvim, arena, name);
    }

    pub fn nvim_set_vvar(self: Api, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.nvim_set_vvar(self.nvim, arena, name, value);
    }

    pub fn nvim_echo(self: Api, arena: std.mem.Allocator, chunks: []const msgpack.MsgPackObject, history: bool, opts: []const msgpack.MsgPackMapEntry) !msgpack.MsgPackObject {
        return root.nvim_echo(self.nvim, arena, chunks, history, opts);
    }

    pub fn nvim_list_bufs(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.nvim_list_bufs(self.nvim, arena);
    }

    pub fn nvim_get_current_buf(self: Api, arena: std.mem.Allocator) !Buffer {
        return root.nvim_get_current_buf(self.nvim, arena);
    }

    pub fn nvim_set_current_buf(self: Api, arena: std.mem.Allocator, buf: Buffer) !void {
        return root.nvim_set_current_buf(self.nvim, arena, buf);
    }

    pub fn nvim_list_wins(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.nvim_list_wins(self.nvim, arena);
    }

    pub fn nvim_get_current_win(self: Api, arena: std.mem.Allocator) !Window {
        return root.nvim_get_current_win(self.nvim, arena);
    }

    pub fn nvim_set_current_win(self: Api, arena: std.mem.Allocator, win: Window) !void {
        return root.nvim_set_current_win(self.nvim, arena, win);
    }

    pub fn nvim_create_buf(self: Api, arena: std.mem.Allocator, listed: bool, scratch: bool) !Buffer {
        return root.nvim_create_buf(self.nvim, arena, listed, scratch);
    }

    pub fn nvim_open_term(self: Api, arena: std.mem.Allocator, buf: Buffer, opts: []const msgpack.MsgPackMapEntry) !i64 {
        return root.nvim_open_term(self.nvim, arena, buf, opts);
    }

    pub fn nvim_chan_send(self: Api, arena: std.mem.Allocator, chan: i64, data: []const u8) !void {
        return root.nvim_chan_send(self.nvim, arena, chan, data);
    }

    pub fn nvim_list_tabpages(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.nvim_list_tabpages(self.nvim, arena);
    }

    pub fn nvim_get_current_tabpage(self: Api, arena: std.mem.Allocator) !Tabpage {
        return root.nvim_get_current_tabpage(self.nvim, arena);
    }

    pub fn nvim_set_current_tabpage(self: Api, arena: std.mem.Allocator, tabpage: Tabpage) !void {
        return root.nvim_set_current_tabpage(self.nvim, arena, tabpage);
    }

    pub fn nvim_paste(self: Api, arena: std.mem.Allocator, data: []const u8, crlf: bool, phase: i64) !bool {
        return root.nvim_paste(self.nvim, arena, data, crlf, phase);
    }

    pub fn nvim_put(self: Api, arena: std.mem.Allocator, lines: []const msgpack.MsgPackObject, @"type": []const u8, after: bool, follow: bool) !void {
        return root.nvim_put(self.nvim, arena, lines, @"type", after, follow);
    }

    pub fn nvim_get_color_by_name(self: Api, arena: std.mem.Allocator, name: []const u8) !i64 {
        return root.nvim_get_color_by_name(self.nvim, arena, name);
    }

    pub fn nvim_get_color_map(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_color_map(self.nvim, arena);
    }

    pub fn nvim_get_context(self: Api, arena: std.mem.Allocator, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_context(self.nvim, arena, opts);
    }

    pub fn nvim_load_context(self: Api, arena: std.mem.Allocator, dict: []const msgpack.MsgPackMapEntry) !msgpack.MsgPackObject {
        return root.nvim_load_context(self.nvim, arena, dict);
    }

    pub fn nvim_get_mode(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_mode(self.nvim, arena);
    }

    pub fn nvim_get_keymap(self: Api, arena: std.mem.Allocator, mode: []const u8) ![]msgpack.MsgPackObject {
        return root.nvim_get_keymap(self.nvim, arena, mode);
    }

    pub fn nvim_set_keymap(self: Api, arena: std.mem.Allocator, mode: []const u8, lhs: []const u8, rhs: []const u8, opts: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_set_keymap(self.nvim, arena, mode, lhs, rhs, opts);
    }

    pub fn nvim_del_keymap(self: Api, arena: std.mem.Allocator, mode: []const u8, lhs: []const u8) !void {
        return root.nvim_del_keymap(self.nvim, arena, mode, lhs);
    }

    pub fn nvim_get_api_info(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.nvim_get_api_info(self.nvim, arena);
    }

    pub fn nvim_set_client_info(self: Api, arena: std.mem.Allocator, name: []const u8, version: []const msgpack.MsgPackMapEntry, @"type": []const u8, methods: []const msgpack.MsgPackMapEntry, attributes: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_set_client_info(self.nvim, arena, name, version, @"type", methods, attributes);
    }

    pub fn nvim_get_chan_info(self: Api, arena: std.mem.Allocator, chan: i64) ![]msgpack.MsgPackMapEntry {
        return root.nvim_get_chan_info(self.nvim, arena, chan);
    }

    pub fn nvim_list_chans(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.nvim_list_chans(self.nvim, arena);
    }

    pub fn nvim_list_uis(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.nvim_list_uis(self.nvim, arena);
    }

    pub fn nvim_get_proc_children(self: Api, arena: std.mem.Allocator, pid: i64) ![]msgpack.MsgPackObject {
        return root.nvim_get_proc_children(self.nvim, arena, pid);
    }

    pub fn nvim_get_proc(self: Api, arena: std.mem.Allocator, pid: i64) !msgpack.MsgPackObject {
        return root.nvim_get_proc(self.nvim, arena, pid);
    }

    pub fn nvim_select_popupmenu_item(self: Api, arena: std.mem.Allocator, item: i64, insert: bool, finish: bool, opts: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_select_popupmenu_item(self.nvim, arena, item, insert, finish, opts);
    }

    pub fn nvim_del_mark(self: Api, arena: std.mem.Allocator, name: []const u8) !bool {
        return root.nvim_del_mark(self.nvim, arena, name);
    }

    pub fn nvim_get_mark(self: Api, arena: std.mem.Allocator, name: []const u8, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackObject {
        return root.nvim_get_mark(self.nvim, arena, name, opts);
    }

    pub fn nvim_eval_statusline(self: Api, arena: std.mem.Allocator, str: []const u8, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return root.nvim_eval_statusline(self.nvim, arena, str, opts);
    }

    pub fn nvim_exec2(self: Api, arena: std.mem.Allocator, src: []const u8, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return root.nvim_exec2(self.nvim, arena, src, opts);
    }

    pub fn nvim_command(self: Api, arena: std.mem.Allocator, cmd: []const u8) !void {
        return root.nvim_command(self.nvim, arena, cmd);
    }

    pub fn nvim_eval(self: Api, arena: std.mem.Allocator, expr: []const u8) !msgpack.MsgPackObject {
        return root.nvim_eval(self.nvim, arena, expr);
    }

    pub fn nvim_call_function(self: Api, arena: std.mem.Allocator, @"fn": []const u8, args: []const msgpack.MsgPackObject) !msgpack.MsgPackObject {
        return root.nvim_call_function(self.nvim, arena, @"fn", args);
    }

    pub fn nvim_call_dict_function(self: Api, arena: std.mem.Allocator, dict: msgpack.MsgPackObject, @"fn": []const u8, args: []const msgpack.MsgPackObject) !msgpack.MsgPackObject {
        return root.nvim_call_dict_function(self.nvim, arena, dict, @"fn", args);
    }

    pub fn nvim_parse_expression(self: Api, arena: std.mem.Allocator, expr: []const u8, flags: []const u8, hl: bool) ![]msgpack.MsgPackMapEntry {
        return root.nvim_parse_expression(self.nvim, arena, expr, flags, hl);
    }

    pub fn nvim_open_win(self: Api, arena: std.mem.Allocator, buf: Buffer, enter: bool, config: []const msgpack.MsgPackMapEntry) !Window {
        return root.nvim_open_win(self.nvim, arena, buf, enter, config);
    }

    pub fn nvim_win_set_config(self: Api, arena: std.mem.Allocator, win: Window, config: []const msgpack.MsgPackMapEntry) !void {
        return root.nvim_win_set_config(self.nvim, arena, win, config);
    }

    pub fn nvim_win_get_config(self: Api, arena: std.mem.Allocator, win: Window) ![]msgpack.MsgPackMapEntry {
        return root.nvim_win_get_config(self.nvim, arena, win);
    }

    pub fn nvim_win_get_buf(self: Api, arena: std.mem.Allocator, win: Window) !Buffer {
        return root.nvim_win_get_buf(self.nvim, arena, win);
    }

    pub fn nvim_win_set_buf(self: Api, arena: std.mem.Allocator, win: Window, buf: Buffer) !void {
        return root.nvim_win_set_buf(self.nvim, arena, win, buf);
    }

    pub fn nvim_win_get_cursor(self: Api, arena: std.mem.Allocator, win: Window) ![]msgpack.MsgPackObject {
        return root.nvim_win_get_cursor(self.nvim, arena, win);
    }

    pub fn nvim_win_set_cursor(self: Api, arena: std.mem.Allocator, win: Window, pos: []const msgpack.MsgPackObject) !void {
        return root.nvim_win_set_cursor(self.nvim, arena, win, pos);
    }

    pub fn nvim_win_get_height(self: Api, arena: std.mem.Allocator, win: Window) !i64 {
        return root.nvim_win_get_height(self.nvim, arena, win);
    }

    pub fn nvim_win_set_height(self: Api, arena: std.mem.Allocator, win: Window, height: i64) !void {
        return root.nvim_win_set_height(self.nvim, arena, win, height);
    }

    pub fn nvim_win_get_width(self: Api, arena: std.mem.Allocator, win: Window) !i64 {
        return root.nvim_win_get_width(self.nvim, arena, win);
    }

    pub fn nvim_win_set_width(self: Api, arena: std.mem.Allocator, win: Window, width: i64) !void {
        return root.nvim_win_set_width(self.nvim, arena, win, width);
    }

    pub fn nvim_win_get_var(self: Api, arena: std.mem.Allocator, win: Window, name: []const u8) !msgpack.MsgPackObject {
        return root.nvim_win_get_var(self.nvim, arena, win, name);
    }

    pub fn nvim_win_set_var(self: Api, arena: std.mem.Allocator, win: Window, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.nvim_win_set_var(self.nvim, arena, win, name, value);
    }

    pub fn nvim_win_del_var(self: Api, arena: std.mem.Allocator, win: Window, name: []const u8) !void {
        return root.nvim_win_del_var(self.nvim, arena, win, name);
    }

    pub fn nvim_win_get_position(self: Api, arena: std.mem.Allocator, win: Window) ![]msgpack.MsgPackObject {
        return root.nvim_win_get_position(self.nvim, arena, win);
    }

    pub fn nvim_win_get_tabpage(self: Api, arena: std.mem.Allocator, win: Window) !Tabpage {
        return root.nvim_win_get_tabpage(self.nvim, arena, win);
    }

    pub fn nvim_win_get_number(self: Api, arena: std.mem.Allocator, win: Window) !i64 {
        return root.nvim_win_get_number(self.nvim, arena, win);
    }

    pub fn nvim_win_is_valid(self: Api, arena: std.mem.Allocator, win: Window) !bool {
        return root.nvim_win_is_valid(self.nvim, arena, win);
    }

    pub fn nvim_win_hide(self: Api, arena: std.mem.Allocator, win: Window) !void {
        return root.nvim_win_hide(self.nvim, arena, win);
    }

    pub fn nvim_win_close(self: Api, arena: std.mem.Allocator, win: Window, force: bool) !void {
        return root.nvim_win_close(self.nvim, arena, win, force);
    }

    pub fn nvim_win_call(self: Api, arena: std.mem.Allocator, win: Window, fun: i64) !msgpack.MsgPackObject {
        return root.nvim_win_call(self.nvim, arena, win, fun);
    }

    pub fn nvim_win_set_hl_ns(self: Api, arena: std.mem.Allocator, win: Window, ns_id: i64) !void {
        return root.nvim_win_set_hl_ns(self.nvim, arena, win, ns_id);
    }

    pub fn nvim_win_text_height(self: Api, arena: std.mem.Allocator, win: Window, opts: []const msgpack.MsgPackMapEntry) ![]msgpack.MsgPackMapEntry {
        return root.nvim_win_text_height(self.nvim, arena, win, opts);
    }

    pub fn buffer_line_count(self: Api, arena: std.mem.Allocator, buf: Buffer) !i64 {
        return root.buffer_line_count(self.nvim, arena, buf);
    }

    pub fn buffer_get_lines(self: Api, arena: std.mem.Allocator, buf: Buffer, start: i64, end: i64, strict_indexing: bool) ![]msgpack.MsgPackObject {
        return root.buffer_get_lines(self.nvim, arena, buf, start, end, strict_indexing);
    }

    pub fn buffer_set_lines(self: Api, arena: std.mem.Allocator, buf: Buffer, start: i64, end: i64, strict_indexing: bool, replacement: []const msgpack.MsgPackObject) !void {
        return root.buffer_set_lines(self.nvim, arena, buf, start, end, strict_indexing, replacement);
    }

    pub fn buffer_get_var(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !msgpack.MsgPackObject {
        return root.buffer_get_var(self.nvim, arena, buf, name);
    }

    pub fn buffer_get_name(self: Api, arena: std.mem.Allocator, buf: Buffer) ![]u8 {
        return root.buffer_get_name(self.nvim, arena, buf);
    }

    pub fn buffer_set_name(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8) !void {
        return root.buffer_set_name(self.nvim, arena, buf, name);
    }

    pub fn buffer_is_valid(self: Api, arena: std.mem.Allocator, buf: Buffer) !bool {
        return root.buffer_is_valid(self.nvim, arena, buf);
    }

    pub fn buffer_get_mark(self: Api, arena: std.mem.Allocator, buf: Buffer, name: []const u8) ![]msgpack.MsgPackObject {
        return root.buffer_get_mark(self.nvim, arena, buf, name);
    }

    pub fn vim_command_output(self: Api, arena: std.mem.Allocator, command: []const u8) ![]u8 {
        return root.vim_command_output(self.nvim, arena, command);
    }

    pub fn buffer_get_number(self: Api, arena: std.mem.Allocator, buffer: Buffer) !i64 {
        return root.buffer_get_number(self.nvim, arena, buffer);
    }

    pub fn buffer_clear_highlight(self: Api, arena: std.mem.Allocator, buffer: Buffer, ns_id: i64, line_start: i64, line_end: i64) !void {
        return root.buffer_clear_highlight(self.nvim, arena, buffer, ns_id, line_start, line_end);
    }

    pub fn buffer_add_highlight(self: Api, arena: std.mem.Allocator, buffer: Buffer, ns_id: i64, hl_group: []const u8, line: i64, col_start: i64, col_end: i64) !i64 {
        return root.buffer_add_highlight(self.nvim, arena, buffer, ns_id, hl_group, line, col_start, col_end);
    }

    pub fn vim_set_option(self: Api, arena: std.mem.Allocator, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.vim_set_option(self.nvim, arena, name, value);
    }

    pub fn vim_get_option(self: Api, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return root.vim_get_option(self.nvim, arena, name);
    }

    pub fn buffer_get_option(self: Api, arena: std.mem.Allocator, buffer: Buffer, name: []const u8) !msgpack.MsgPackObject {
        return root.buffer_get_option(self.nvim, arena, buffer, name);
    }

    pub fn buffer_set_option(self: Api, arena: std.mem.Allocator, buffer: Buffer, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.buffer_set_option(self.nvim, arena, buffer, name, value);
    }

    pub fn window_get_option(self: Api, arena: std.mem.Allocator, window: Window, name: []const u8) !msgpack.MsgPackObject {
        return root.window_get_option(self.nvim, arena, window, name);
    }

    pub fn window_set_option(self: Api, arena: std.mem.Allocator, window: Window, name: []const u8, value: msgpack.MsgPackObject) !void {
        return root.window_set_option(self.nvim, arena, window, name, value);
    }

    pub fn vim_subscribe(self: Api, arena: std.mem.Allocator, event: []const u8) !void {
        return root.vim_subscribe(self.nvim, arena, event);
    }

    pub fn vim_unsubscribe(self: Api, arena: std.mem.Allocator, event: []const u8) !void {
        return root.vim_unsubscribe(self.nvim, arena, event);
    }

    pub fn vim_out_write(self: Api, arena: std.mem.Allocator, str: []const u8) !void {
        return root.vim_out_write(self.nvim, arena, str);
    }

    pub fn vim_err_write(self: Api, arena: std.mem.Allocator, str: []const u8) !void {
        return root.vim_err_write(self.nvim, arena, str);
    }

    pub fn vim_report_error(self: Api, arena: std.mem.Allocator, str: []const u8) !void {
        return root.vim_report_error(self.nvim, arena, str);
    }

    pub fn tabpage_get_windows(self: Api, arena: std.mem.Allocator, tabpage: Tabpage) ![]msgpack.MsgPackObject {
        return root.tabpage_get_windows(self.nvim, arena, tabpage);
    }

    pub fn tabpage_get_var(self: Api, arena: std.mem.Allocator, tabpage: Tabpage, name: []const u8) !msgpack.MsgPackObject {
        return root.tabpage_get_var(self.nvim, arena, tabpage, name);
    }

    pub fn tabpage_get_window(self: Api, arena: std.mem.Allocator, tabpage: Tabpage) !Window {
        return root.tabpage_get_window(self.nvim, arena, tabpage);
    }

    pub fn tabpage_is_valid(self: Api, arena: std.mem.Allocator, tabpage: Tabpage) !bool {
        return root.tabpage_is_valid(self.nvim, arena, tabpage);
    }

    pub fn ui_detach(self: Api, arena: std.mem.Allocator) !void {
        return root.ui_detach(self.nvim, arena);
    }

    pub fn ui_try_resize(self: Api, arena: std.mem.Allocator, width: i64, height: i64) !msgpack.MsgPackObject {
        return root.ui_try_resize(self.nvim, arena, width, height);
    }

    pub fn vim_feedkeys(self: Api, arena: std.mem.Allocator, keys: []const u8, mode: []const u8, escape_ks: bool) !void {
        return root.vim_feedkeys(self.nvim, arena, keys, mode, escape_ks);
    }

    pub fn vim_input(self: Api, arena: std.mem.Allocator, keys: []const u8) !i64 {
        return root.vim_input(self.nvim, arena, keys);
    }

    pub fn vim_replace_termcodes(self: Api, arena: std.mem.Allocator, str: []const u8, from_part: bool, do_lt: bool, special: bool) ![]u8 {
        return root.vim_replace_termcodes(self.nvim, arena, str, from_part, do_lt, special);
    }

    pub fn vim_strwidth(self: Api, arena: std.mem.Allocator, text: []const u8) !i64 {
        return root.vim_strwidth(self.nvim, arena, text);
    }

    pub fn vim_list_runtime_paths(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.vim_list_runtime_paths(self.nvim, arena);
    }

    pub fn vim_change_directory(self: Api, arena: std.mem.Allocator, dir: []const u8) !void {
        return root.vim_change_directory(self.nvim, arena, dir);
    }

    pub fn vim_get_current_line(self: Api, arena: std.mem.Allocator) ![]u8 {
        return root.vim_get_current_line(self.nvim, arena);
    }

    pub fn vim_set_current_line(self: Api, arena: std.mem.Allocator, line: []const u8) !void {
        return root.vim_set_current_line(self.nvim, arena, line);
    }

    pub fn vim_del_current_line(self: Api, arena: std.mem.Allocator) !void {
        return root.vim_del_current_line(self.nvim, arena);
    }

    pub fn vim_get_var(self: Api, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return root.vim_get_var(self.nvim, arena, name);
    }

    pub fn vim_get_vvar(self: Api, arena: std.mem.Allocator, name: []const u8) !msgpack.MsgPackObject {
        return root.vim_get_vvar(self.nvim, arena, name);
    }

    pub fn vim_get_buffers(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.vim_get_buffers(self.nvim, arena);
    }

    pub fn vim_get_current_buffer(self: Api, arena: std.mem.Allocator) !Buffer {
        return root.vim_get_current_buffer(self.nvim, arena);
    }

    pub fn vim_set_current_buffer(self: Api, arena: std.mem.Allocator, buf: Buffer) !void {
        return root.vim_set_current_buffer(self.nvim, arena, buf);
    }

    pub fn vim_get_windows(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.vim_get_windows(self.nvim, arena);
    }

    pub fn vim_get_current_window(self: Api, arena: std.mem.Allocator) !Window {
        return root.vim_get_current_window(self.nvim, arena);
    }

    pub fn vim_set_current_window(self: Api, arena: std.mem.Allocator, win: Window) !void {
        return root.vim_set_current_window(self.nvim, arena, win);
    }

    pub fn vim_get_tabpages(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.vim_get_tabpages(self.nvim, arena);
    }

    pub fn vim_get_current_tabpage(self: Api, arena: std.mem.Allocator) !Tabpage {
        return root.vim_get_current_tabpage(self.nvim, arena);
    }

    pub fn vim_set_current_tabpage(self: Api, arena: std.mem.Allocator, tabpage: Tabpage) !void {
        return root.vim_set_current_tabpage(self.nvim, arena, tabpage);
    }

    pub fn vim_name_to_color(self: Api, arena: std.mem.Allocator, name: []const u8) !i64 {
        return root.vim_name_to_color(self.nvim, arena, name);
    }

    pub fn vim_get_color_map(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackMapEntry {
        return root.vim_get_color_map(self.nvim, arena);
    }

    pub fn vim_get_api_info(self: Api, arena: std.mem.Allocator) ![]msgpack.MsgPackObject {
        return root.vim_get_api_info(self.nvim, arena);
    }

    pub fn vim_command(self: Api, arena: std.mem.Allocator, cmd: []const u8) !void {
        return root.vim_command(self.nvim, arena, cmd);
    }

    pub fn vim_eval(self: Api, arena: std.mem.Allocator, expr: []const u8) !msgpack.MsgPackObject {
        return root.vim_eval(self.nvim, arena, expr);
    }

    pub fn vim_call_function(self: Api, arena: std.mem.Allocator, @"fn": []const u8, args: []const msgpack.MsgPackObject) !msgpack.MsgPackObject {
        return root.vim_call_function(self.nvim, arena, @"fn", args);
    }

    pub fn window_get_buffer(self: Api, arena: std.mem.Allocator, win: Window) !Buffer {
        return root.window_get_buffer(self.nvim, arena, win);
    }

    pub fn window_get_cursor(self: Api, arena: std.mem.Allocator, win: Window) ![]msgpack.MsgPackObject {
        return root.window_get_cursor(self.nvim, arena, win);
    }

    pub fn window_set_cursor(self: Api, arena: std.mem.Allocator, win: Window, pos: []const msgpack.MsgPackObject) !void {
        return root.window_set_cursor(self.nvim, arena, win, pos);
    }

    pub fn window_get_height(self: Api, arena: std.mem.Allocator, win: Window) !i64 {
        return root.window_get_height(self.nvim, arena, win);
    }

    pub fn window_set_height(self: Api, arena: std.mem.Allocator, win: Window, height: i64) !void {
        return root.window_set_height(self.nvim, arena, win, height);
    }

    pub fn window_get_width(self: Api, arena: std.mem.Allocator, win: Window) !i64 {
        return root.window_get_width(self.nvim, arena, win);
    }

    pub fn window_set_width(self: Api, arena: std.mem.Allocator, win: Window, width: i64) !void {
        return root.window_set_width(self.nvim, arena, win, width);
    }

    pub fn window_get_var(self: Api, arena: std.mem.Allocator, win: Window, name: []const u8) !msgpack.MsgPackObject {
        return root.window_get_var(self.nvim, arena, win, name);
    }

    pub fn window_get_position(self: Api, arena: std.mem.Allocator, win: Window) ![]msgpack.MsgPackObject {
        return root.window_get_position(self.nvim, arena, win);
    }

    pub fn window_get_tabpage(self: Api, arena: std.mem.Allocator, win: Window) !Tabpage {
        return root.window_get_tabpage(self.nvim, arena, win);
    }

    pub fn window_is_valid(self: Api, arena: std.mem.Allocator, win: Window) !bool {
        return root.window_is_valid(self.nvim, arena, win);
    }

};
