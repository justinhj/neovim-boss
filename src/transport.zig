const std = @import("std");
const Io = std.Io;

pub const TransportError = error{
    ReadFailed,
    WriteFailed,
    EndOfStream,
    InvalidPath,
    ConnectionFailed,
};

/// Layer 1: Transport abstraction over a byte stream.
/// In Phase 1, supports Unix domain sockets and existing file descriptors.
pub const Transport = struct {
    fd: std.posix.fd_t,
    stream: ?Io.net.Stream = null,
    io: ?Io = null,

    /// Connect to a Neovim instance listening on a Unix domain socket.
    pub fn connectUnix(io: Io, socket_path: []const u8) !Transport {
        const addr = Io.net.UnixAddress.init(socket_path) catch {
            return TransportError.InvalidPath;
        };

        const stream = addr.connect(io) catch {
            return TransportError.ConnectionFailed;
        };

        return .{
            .fd = stream.socket.handle,
            .stream = stream,
            .io = io,
        };
    }

    /// Wrap an existing file descriptor (e.g. from socketpair or pipes).
    pub fn fromFd(fd: std.posix.fd_t) Transport {
        return .{
            .fd = fd,
            .stream = null,
            .io = null,
        };
    }

    /// Read available bytes into the provided buffer.
    /// Returns the number of bytes read (0 indicates EOF/closed peer).
    pub fn read(self: *Transport, buffer: []u8) TransportError!usize {
        if (self.fd < 0) return TransportError.ReadFailed;
        if (buffer.len == 0) return 0;

        const n = std.c.read(self.fd, buffer.ptr, buffer.len);
        if (n < 0) return TransportError.ReadFailed;
        return @intCast(n);
    }

    /// Write all bytes to the transport, looping on partial writes.
    pub fn writeAll(self: *Transport, bytes: []const u8) TransportError!void {
        if (self.fd < 0) return TransportError.WriteFailed;
        var index: usize = 0;
        while (index < bytes.len) {
            const n = std.c.write(self.fd, bytes[index..].ptr, bytes.len - index);
            if (n <= 0) return TransportError.WriteFailed;
            index += @intCast(n);
        }
    }

    /// Close the transport connection.
    pub fn close(self: *Transport) void {
        if (self.fd < 0) return;

        if (self.stream) |s| {
            if (self.io) |io| {
                s.close(io);
                self.stream = null;
                self.io = null;
                self.fd = -1;
                return;
            }
        }
        _ = std.c.close(self.fd);
        self.fd = -1;
    }
};

test "transport: socketpair read and writeAll" {
    var fds: [2]std.posix.fd_t = undefined;
    const rc = std.c.socketpair(std.c.AF.UNIX, std.c.SOCK.STREAM, 0, &fds);
    try std.testing.expectEqual(@as(c_int, 0), rc);

    var client_t = Transport.fromFd(fds[0]);
    defer client_t.close();
    var server_t = Transport.fromFd(fds[1]);
    defer server_t.close();

    const msg = "hello neovim transport";
    try client_t.writeAll(msg);

    var buf: [64]u8 = undefined;
    const n = try server_t.read(&buf);
    try std.testing.expectEqual(msg.len, n);
    try std.testing.expectEqualStrings(msg, buf[0..n]);
}
