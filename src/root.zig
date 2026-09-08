const std = @import("std");

pub const msgpack = @import("zig_msgpack");

pub const transport = @import("transport.zig");
pub const Transport = transport.Transport;
pub const TransportError = transport.TransportError;

pub const client = @import("client.zig");
pub const Client = client.Client;
pub const ClientError = client.ClientError;
pub const NotificationHandler = client.NotificationHandler;

pub const nvim_types = @import("nvim_types.zig");
pub const Buffer = nvim_types.Buffer;
pub const Window = nvim_types.Window;
pub const Tabpage = nvim_types.Tabpage;
pub const ExtTypes = nvim_types.ExtTypes;
pub const RemoteObject = nvim_types.RemoteObject;

pub const object_util = @import("object_util.zig");
pub const asString = object_util.asString;
pub const asInt = object_util.asInt;
pub const asBool = object_util.asBool;
pub const asArray = object_util.asArray;
pub const asMap = object_util.asMap;
pub const mapGet = object_util.mapGet;
pub const walkObject = object_util.walkObject;

pub const nvim = @import("nvim.zig");
pub const Nvim = nvim.Nvim;
pub const NvimError = nvim.NvimError;

test {
    std.testing.refAllDecls(@This());
    _ = transport;
    _ = client;
    _ = nvim_types;
    _ = object_util;
    _ = nvim;
}
