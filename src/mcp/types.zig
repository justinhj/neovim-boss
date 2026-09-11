const std = @import("std");

pub const JSONRPC_VERSION = "2.0";
pub const MCP_PROTOCOL_VERSION = "2024-11-05";

pub const ErrorCode = struct {
    pub const parse_error: i64 = -32700;
    pub const invalid_request: i64 = -32600;
    pub const method_not_found: i64 = -32601;
    pub const invalid_params: i64 = -32602;
    pub const internal_error: i64 = -32603;
};

pub const ServerInfo = struct {
    name: []const u8 = "neovim-boss",
    version: []const u8,
};

pub const Tool = struct {
    name: []const u8,
    description: []const u8,
    inputSchema: std.json.Value,
};

pub const Resource = struct {
    uri: []const u8,
    name: []const u8,
    description: ?[]const u8 = null,
    mimeType: ?[]const u8 = null,
};

pub const TextContent = struct {
    type: []const u8 = "text",
    text: []const u8,
};

pub const ResourceContent = struct {
    uri: []const u8,
    mimeType: ?[]const u8 = null,
    text: []const u8,
};
