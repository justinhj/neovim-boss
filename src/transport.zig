const std = @import("std");
const Io = std.Io;

pub const TransportError = error{
    ReadFailed,
    WriteFailed,
    EndOfStream,
    InvalidPath,
    InvalidHost,
    ConnectionFailed,
    ProcessSpawnFailed,
};

/// Layer 1: Transport abstraction over a byte stream.
/// Supports Unix domain sockets, TCP network sockets, stdio, child process pipes,
/// and existing file descriptors.
pub const Transport = struct {
    read_fd: std.posix.fd_t,
    write_fd: std.posix.fd_t,
    stream: ?Io.net.Stream = null,
    io: ?Io = null,
    child: ?std.process.Child = null,

    /// Connect to a Neovim instance listening on a Unix domain socket.
    pub fn connectUnix(io: Io, socket_path: []const u8) TransportError!Transport {
        const addr = Io.net.UnixAddress.init(socket_path) catch {
            return TransportError.InvalidPath;
        };

        const stream = addr.connect(io) catch {
            return TransportError.ConnectionFailed;
        };

        return .{
            .read_fd = stream.socket.handle,
            .write_fd = stream.socket.handle,
            .stream = stream,
            .io = io,
        };
    }

    /// Connect to a Neovim instance listening on a TCP host and port.
    pub fn connectTcp(io: Io, host: []const u8, port: u16) TransportError!Transport {
        const target_host = if (std.mem.eql(u8, host, "localhost")) "127.0.0.1" else host;

        if (Io.net.IpAddress.parse(target_host, port)) |ip| {
            const stream = ip.connect(io, .{ .mode = .stream }) catch {
                return TransportError.ConnectionFailed;
            };
            return .{
                .read_fd = stream.socket.handle,
                .write_fd = stream.socket.handle,
                .stream = stream,
                .io = io,
            };
        } else |_| {
            const h = Io.net.HostName.init(target_host) catch {
                return TransportError.InvalidHost;
            };
            const stream = h.connect(io, port, .{ .mode = .stream }) catch {
                return TransportError.ConnectionFailed;
            };
            return .{
                .read_fd = stream.socket.handle,
                .write_fd = stream.socket.handle,
                .stream = stream,
                .io = io,
            };
        }
    }

    /// Connect to standard input and standard output (for plugins/jobs run by Neovim).
    pub fn connectStdio(io: Io) Transport {
        return .{
            .read_fd = std.posix.STDIN_FILENO,
            .write_fd = std.posix.STDOUT_FILENO,
            .stream = null,
            .io = io,
            .child = null,
        };
    }

    /// Spawn Neovim as an embedded child process (`nvim --embed --headless`).
    pub fn spawnChild(io: Io, argv: ?[]const []const u8) TransportError!Transport {
        const default_argv = [_][]const u8{ "nvim", "--embed", "--headless" };
        const actual_argv = argv orelse &default_argv;

        const child = std.process.spawn(io, .{
            .argv = actual_argv,
            .stdin = .pipe,
            .stdout = .pipe,
            .stderr = .ignore,
        }) catch {
            return TransportError.ProcessSpawnFailed;
        };

        const read_fd = if (child.stdout) |f| f.handle else return TransportError.ProcessSpawnFailed;
        const write_fd = if (child.stdin) |f| f.handle else return TransportError.ProcessSpawnFailed;

        return .{
            .read_fd = read_fd,
            .write_fd = write_fd,
            .stream = null,
            .io = io,
            .child = child,
        };
    }

    /// Wrap a single existing file descriptor for both reading and writing (e.g. socketpair).
    pub fn fromFd(fd: std.posix.fd_t) Transport {
        return .{
            .read_fd = fd,
            .write_fd = fd,
            .stream = null,
            .io = null,
            .child = null,
        };
    }

    /// Wrap separate file descriptors for reading and writing (e.g. anonymous pipes).
    pub fn fromFds(read_fd: std.posix.fd_t, write_fd: std.posix.fd_t) Transport {
        return .{
            .read_fd = read_fd,
            .write_fd = write_fd,
            .stream = null,
            .io = null,
            .child = null,
        };
    }

    /// Read available bytes into the provided buffer.
    /// Returns the number of bytes read (0 indicates EOF/closed peer).
    pub fn read(self: *Transport, buffer: []u8) TransportError!usize {
        if (self.read_fd < 0) return TransportError.ReadFailed;
        if (buffer.len == 0) return 0;

        const n = std.c.read(self.read_fd, buffer.ptr, buffer.len);
        if (n < 0) return TransportError.ReadFailed;
        return @intCast(n);
    }

    /// Write all bytes to the transport, looping on partial writes.
    pub fn writeAll(self: *Transport, bytes: []const u8) TransportError!void {
        if (self.write_fd < 0) return TransportError.WriteFailed;
        var index: usize = 0;
        while (index < bytes.len) {
            const n = std.c.write(self.write_fd, bytes[index..].ptr, bytes.len - index);
            if (n <= 0) return TransportError.WriteFailed;
            index += @intCast(n);
        }
    }

    /// Close the transport connection, releasing sockets, pipes, or child processes.
    pub fn close(self: *Transport) void {
        if (self.child) |*c| {
            if (self.io) |io| {
                c.kill(io);
            }
            self.child = null;
            self.read_fd = -1;
            self.write_fd = -1;
            return;
        }

        if (self.stream) |s| {
            if (self.io) |io| {
                s.close(io);
                self.stream = null;
                self.io = null;
                self.read_fd = -1;
                self.write_fd = -1;
                return;
            }
        }

        // Only close if not standard streams (0, 1, 2)
        if (self.read_fd > 2) {
            _ = std.c.close(self.read_fd);
        }
        if (self.write_fd > 2 and self.write_fd != self.read_fd) {
            _ = std.c.close(self.write_fd);
        }
        self.read_fd = -1;
        self.write_fd = -1;
    }
};

// --------------------------------------------------------------------------
// Unit Tests
// --------------------------------------------------------------------------

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

test "transport: stdio descriptors" {
    const io = std.testing.io;
    var t = Transport.connectStdio(io);
    try std.testing.expectEqual(@as(std.posix.fd_t, 0), t.read_fd);
    try std.testing.expectEqual(@as(std.posix.fd_t, 1), t.write_fd);
    t.close(); // Should not close stdin/stdout (0 or 1)
}

test "transport: spawnChild embedded nvim" {
    const io = std.testing.io;
    var t = try Transport.spawnChild(io, null);
    defer t.close();

    try std.testing.expect(t.read_fd >= 0);
    try std.testing.expect(t.write_fd >= 0);
    try std.testing.expect(t.child != null);
}
