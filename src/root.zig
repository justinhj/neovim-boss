const std = @import("std");

pub const msgpack = @import("zig_msgpack");

pub const transport = @import("transport.zig");
pub const Transport = transport.Transport;
pub const TransportError = transport.TransportError;

pub const client = @import("client.zig");
pub const Client = client.Client;
pub const ClientError = client.ClientError;
pub const NotificationHandler = client.NotificationHandler;

test {
    std.testing.refAllDecls(@This());
    _ = transport;
    _ = client;
}
