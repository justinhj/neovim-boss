const std = @import("std");
const nvim_mod = @import("../nvim.zig");
const Nvim = nvim_mod.Nvim;
const types = @import("types.zig");
const tools = @import("tools.zig");
const resources = @import("resources.zig");
const root = @import("../root.zig");

pub const Server = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    nvim: *Nvim,
    stdin_fd: std.posix.fd_t = std.posix.STDIN_FILENO,
    stdout_fd: std.posix.fd_t = std.posix.STDOUT_FILENO,
    is_running: bool = false,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, nvim: *Nvim) Server {
        return .{
            .allocator = allocator,
            .io = io,
            .nvim = nvim,
        };
    }

    /// Run the MCP server over stdio until EOF or an unrecoverable error.
    pub fn run(self: *Server) !void {
        self.is_running = true;

        var read_buffer: std.ArrayList(u8) = .empty;
        defer read_buffer.deinit(self.allocator);

        var chunk: [4096]u8 = undefined;

        while (self.is_running) {
            const n = std.c.read(self.stdin_fd, &chunk, chunk.len);
            if (n == 0) {
                // EOF reached
                break;
            } else if (n < 0) {
                return error.ReadFailed;
            }

            const bytes_read: usize = @intCast(n);
            try read_buffer.appendSlice(self.allocator, chunk[0..bytes_read]);

            // Process all complete lines in read_buffer
            while (true) {
                const newline_pos = std.mem.indexOfScalar(u8, read_buffer.items, '\n') orelse break;
                const line = read_buffer.items[0..newline_pos];

                // Process line with a scoped arena allocator
                {
                    var req_arena = std.heap.ArenaAllocator.init(self.allocator);
                    defer req_arena.deinit();
                    const arena = req_arena.allocator();

                    self.handleLine(arena, line) catch |err| {
                        std.log.err("mcp: error handling line: {s}", .{@errorName(err)});
                    };
                }

                // Remove the processed line and delimiter from buffer
                const remove_count = newline_pos + 1;
                const remaining = read_buffer.items.len - remove_count;
                if (remaining > 0) {
                    std.mem.copyForwards(u8, read_buffer.items[0..remaining], read_buffer.items[remove_count..]);
                }
                read_buffer.items.len = remaining;
            }
        }
    }

    pub fn handleLine(self: *Server, arena: std.mem.Allocator, raw_line: []const u8) !void {
        const line = std.mem.trim(u8, raw_line, " \r\t");
        if (line.len == 0) return;

        const parsed = std.json.parseFromSlice(std.json.Value, arena, line, .{}) catch {
            try self.sendRawError(arena, null, types.ErrorCode.parse_error, "Parse error: invalid JSON");
            return;
        };

        if (parsed.value != .object) {
            try self.sendRawError(arena, null, types.ErrorCode.invalid_request, "Invalid request: expected JSON object");
            return;
        }

        const obj = parsed.value.object;
        const id_val = obj.get("id");
        const method_val = obj.get("method") orelse {
            if (id_val != null) {
                try self.sendError(arena, id_val.?, types.ErrorCode.invalid_request, "Missing method");
            }
            return;
        };

        if (method_val != .string) {
            if (id_val != null) {
                try self.sendError(arena, id_val.?, types.ErrorCode.invalid_request, "Method must be a string");
            }
            return;
        }

        const method = method_val.string;
        const params = obj.get("params");

        if (id_val == null) {
            // Notification: no response sent back
            self.handleNotification(arena, method, params);
            return;
        }

        const id = id_val.?;
        try self.handleRequest(arena, id, method, params);
    }

    fn handleNotification(self: *Server, arena: std.mem.Allocator, method: []const u8, params: ?std.json.Value) void {
        _ = self;
        _ = arena;
        _ = params;
        if (std.mem.eql(u8, method, "notifications/initialized")) {
            // Client initialized acknowledgment
            return;
        }
        // Other notifications can be safely ignored
    }

    fn handleRequest(
        self: *Server,
        arena: std.mem.Allocator,
        id: std.json.Value,
        method: []const u8,
        params: ?std.json.Value,
    ) !void {
        if (std.mem.eql(u8, method, "initialize")) {
            return self.handleInitialize(arena, id);
        } else if (std.mem.eql(u8, method, "ping")) {
            const empty_map: std.json.ObjectMap = .empty;
            return self.sendResult(arena, id, .{ .object = empty_map });
        } else if (std.mem.eql(u8, method, "tools/list")) {
            return self.handleToolsList(arena, id);
        } else if (std.mem.eql(u8, method, "tools/call")) {
            return self.handleToolsCall(arena, id, params);
        } else if (std.mem.eql(u8, method, "resources/list")) {
            return self.handleResourcesList(arena, id);
        } else if (std.mem.eql(u8, method, "resources/read")) {
            return self.handleResourcesRead(arena, id, params);
        } else {
            return self.sendError(arena, id, types.ErrorCode.method_not_found, "Method not found");
        }
    }

    fn handleInitialize(self: *Server, arena: std.mem.Allocator, id: std.json.Value) !void {
        var result_map: std.json.ObjectMap = .empty;
        try result_map.put(arena, "protocolVersion", .{ .string = types.MCP_PROTOCOL_VERSION });

        var caps_map: std.json.ObjectMap = .empty;
        const empty_tools_map: std.json.ObjectMap = .empty;
        const empty_res_map: std.json.ObjectMap = .empty;
        try caps_map.put(arena, "tools", .{ .object = empty_tools_map });
        try caps_map.put(arena, "resources", .{ .object = empty_res_map });
        try result_map.put(arena, "capabilities", .{ .object = caps_map });

        var server_info_map: std.json.ObjectMap = .empty;
        try server_info_map.put(arena, "name", .{ .string = "neovim-boss" });
        try server_info_map.put(arena, "version", .{ .string = root.version });
        try result_map.put(arena, "serverInfo", .{ .object = server_info_map });

        try self.sendResult(arena, id, .{ .object = result_map });
    }

    fn handleToolsList(self: *Server, arena: std.mem.Allocator, id: std.json.Value) !void {
        const tool_list = try tools.listTools(arena);

        var tools_arr = std.json.Array.init(arena);
        for (tool_list) |t| {
            var t_map: std.json.ObjectMap = .empty;
            try t_map.put(arena, "name", .{ .string = t.name });
            try t_map.put(arena, "description", .{ .string = t.description });
            try t_map.put(arena, "inputSchema", t.inputSchema);
            try tools_arr.append(.{ .object = t_map });
        }

        var result_map: std.json.ObjectMap = .empty;
        try result_map.put(arena, "tools", .{ .array = tools_arr });

        try self.sendResult(arena, id, .{ .object = result_map });
    }

    fn handleToolsCall(
        self: *Server,
        arena: std.mem.Allocator,
        id: std.json.Value,
        params: ?std.json.Value,
    ) !void {
        const p = params orelse {
            return self.sendError(arena, id, types.ErrorCode.invalid_params, "Missing params for tools/call");
        };

        if (p != .object) {
            return self.sendError(arena, id, types.ErrorCode.invalid_params, "tools/call params must be an object");
        }

        const name_val = p.object.get("name") orelse {
            return self.sendError(arena, id, types.ErrorCode.invalid_params, "Missing tool name in params");
        };

        if (name_val != .string) {
            return self.sendError(arena, id, types.ErrorCode.invalid_params, "Tool name must be a string");
        }

        const arguments = p.object.get("arguments");
        const call_result = try tools.callTool(self.nvim, arena, name_val.string, arguments);

        var content_arr = std.json.Array.init(arena);
        for (call_result.content) |item| {
            var c_map: std.json.ObjectMap = .empty;
            try c_map.put(arena, "type", .{ .string = item.type });
            try c_map.put(arena, "text", .{ .string = item.text });
            try content_arr.append(.{ .object = c_map });
        }

        var result_map: std.json.ObjectMap = .empty;
        try result_map.put(arena, "content", .{ .array = content_arr });
        try result_map.put(arena, "isError", .{ .bool = call_result.isError });

        try self.sendResult(arena, id, .{ .object = result_map });
    }

    fn handleResourcesList(self: *Server, arena: std.mem.Allocator, id: std.json.Value) !void {
        const res_list = try resources.listResources(arena);

        var res_arr = std.json.Array.init(arena);
        for (res_list) |r| {
            var r_map: std.json.ObjectMap = .empty;
            try r_map.put(arena, "uri", .{ .string = r.uri });
            try r_map.put(arena, "name", .{ .string = r.name });
            if (r.description) |desc| {
                try r_map.put(arena, "description", .{ .string = desc });
            }
            if (r.mimeType) |mt| {
                try r_map.put(arena, "mimeType", .{ .string = mt });
            }
            try res_arr.append(.{ .object = r_map });
        }

        var result_map: std.json.ObjectMap = .empty;
        try result_map.put(arena, "resources", .{ .array = res_arr });

        try self.sendResult(arena, id, .{ .object = result_map });
    }

    fn handleResourcesRead(
        self: *Server,
        arena: std.mem.Allocator,
        id: std.json.Value,
        params: ?std.json.Value,
    ) !void {
        const p = params orelse {
            return self.sendError(arena, id, types.ErrorCode.invalid_params, "Missing params for resources/read");
        };

        if (p != .object) {
            return self.sendError(arena, id, types.ErrorCode.invalid_params, "resources/read params must be an object");
        }

        const uri_val = p.object.get("uri") orelse {
            return self.sendError(arena, id, types.ErrorCode.invalid_params, "Missing uri in resources/read params");
        };

        if (uri_val != .string) {
            return self.sendError(arena, id, types.ErrorCode.invalid_params, "uri must be a string");
        }

        const read_res = resources.readResource(self.nvim, arena, uri_val.string) catch |err| {
            const err_msg = try std.fmt.allocPrint(arena, "Failed to read resource: {s}", .{@errorName(err)});
            return self.sendError(arena, id, types.ErrorCode.internal_error, err_msg);
        };

        var contents_arr = std.json.Array.init(arena);
        for (read_res.contents) |item| {
            var c_map: std.json.ObjectMap = .empty;
            try c_map.put(arena, "uri", .{ .string = item.uri });
            if (item.mimeType) |mt| {
                try c_map.put(arena, "mimeType", .{ .string = mt });
            }
            try c_map.put(arena, "text", .{ .string = item.text });
            try contents_arr.append(.{ .object = c_map });
        }

        var result_map: std.json.ObjectMap = .empty;
        try result_map.put(arena, "contents", .{ .array = contents_arr });

        try self.sendResult(arena, id, .{ .object = result_map });
    }

    fn sendResult(self: *Server, arena: std.mem.Allocator, id: std.json.Value, result: std.json.Value) !void {
        var resp_map: std.json.ObjectMap = .empty;
        try resp_map.put(arena, "jsonrpc", .{ .string = types.JSONRPC_VERSION });
        try resp_map.put(arena, "id", id);
        try resp_map.put(arena, "result", result);

        try self.writeJsonResponse(arena, .{ .object = resp_map });
    }

    fn sendError(self: *Server, arena: std.mem.Allocator, id: std.json.Value, code: i64, message: []const u8) !void {
        var err_map: std.json.ObjectMap = .empty;
        try err_map.put(arena, "code", .{ .integer = code });
        try err_map.put(arena, "message", .{ .string = message });

        var resp_map: std.json.ObjectMap = .empty;
        try resp_map.put(arena, "jsonrpc", .{ .string = types.JSONRPC_VERSION });
        try resp_map.put(arena, "id", id);
        try resp_map.put(arena, "error", .{ .object = err_map });

        try self.writeJsonResponse(arena, .{ .object = resp_map });
    }

    fn sendRawError(self: *Server, arena: std.mem.Allocator, id: ?std.json.Value, code: i64, message: []const u8) !void {
        var err_map: std.json.ObjectMap = .empty;
        try err_map.put(arena, "code", .{ .integer = code });
        try err_map.put(arena, "message", .{ .string = message });

        var resp_map: std.json.ObjectMap = .empty;
        try resp_map.put(arena, "jsonrpc", .{ .string = types.JSONRPC_VERSION });
        try resp_map.put(arena, "id", id orelse .{ .null = {} });
        try resp_map.put(arena, "error", .{ .object = err_map });

        try self.writeJsonResponse(arena, .{ .object = resp_map });
    }

    fn writeJsonResponse(self: *Server, arena: std.mem.Allocator, val: std.json.Value) !void {
        const json_str = try std.fmt.allocPrint(arena, "{f}\n", .{std.json.fmt(val, .{})});
        try self.writeAll(json_str);
    }

    fn writeAll(self: *Server, bytes: []const u8) !void {
        var index: usize = 0;
        while (index < bytes.len) {
            const n = std.c.write(self.stdout_fd, bytes[index..].ptr, bytes.len - index);
            if (n <= 0) return error.WriteFailed;
            index += @intCast(n);
        }
    }
};
