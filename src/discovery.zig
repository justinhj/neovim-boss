const std = @import("std");
const builtin = @import("builtin");
const Io = std.Io;
const File = Io.File;
const Allocator = std.mem.Allocator;

const transport = @import("transport.zig");
const Transport = transport.Transport;
const nvim_mod = @import("nvim.zig");
const Nvim = nvim_mod.Nvim;
const object_util = @import("object_util.zig");

pub const MatchScore = enum(u8) {
    exact_cwd = 1,
    inside_project = 2,
    inside_nvim_dir = 3,
    git_root_match = 4,
    none = 255,

    pub fn isMatch(self: MatchScore) bool {
        return self != .none;
    }

    pub fn label(self: MatchScore) []const u8 {
        return switch (self) {
            .exact_cwd => "exact match",
            .inside_project => "inside project workspace",
            .inside_nvim_dir => "nvim in subdirectory",
            .git_root_match => "same git repository",
            .none => "no match",
        };
    }
};

pub const NvimInstance = struct {
    socket_path: []const u8,
    pid: i64,
    cwd: []const u8,
    current_file: []const u8,
    server_name: []const u8,
    git_root: ?[]const u8 = null,
    match_score: MatchScore = .none,

    pub fn deinit(self: NvimInstance, allocator: Allocator) void {
        allocator.free(self.socket_path);
        allocator.free(self.cwd);
        allocator.free(self.current_file);
        allocator.free(self.server_name);
        if (self.git_root) |gr| allocator.free(gr);
    }

    pub fn clone(self: NvimInstance, allocator: Allocator) !NvimInstance {
        return NvimInstance{
            .socket_path = try allocator.dupe(u8, self.socket_path),
            .pid = self.pid,
            .cwd = try allocator.dupe(u8, self.cwd),
            .current_file = try allocator.dupe(u8, self.current_file),
            .server_name = try allocator.dupe(u8, self.server_name),
            .git_root = if (self.git_root) |gr| try allocator.dupe(u8, gr) else null,
            .match_score = self.match_score,
        };
    }
};

/// Traverses up directory ancestors looking for a `.git` entry (directory or worktree file).
pub fn findGitRoot(io: Io, allocator: Allocator, start_path: []const u8) ?[]const u8 {
    var current = allocator.dupe(u8, start_path) catch return null;
    defer allocator.free(current);

    while (true) {
        // Strip trailing slash
        const trimmed = std.mem.trimEnd(u8, current, "/");
        if (trimmed.len == 0) return null;

        const git_path = std.fs.path.join(allocator, &.{ trimmed, ".git" }) catch return null;
        defer allocator.free(git_path);

        if (Io.Dir.accessAbsolute(io, git_path, .{})) |_| {
            return allocator.dupe(u8, trimmed) catch null;
        } else |_| {}

        const parent = std.fs.path.dirname(trimmed) orelse return null;
        if (std.mem.eql(u8, parent, trimmed)) return null;

        const next = allocator.dupe(u8, parent) catch return null;
        allocator.free(current);
        current = next;
    }
}

/// Normalizes and resolves symlinks for an absolute path when possible.
pub fn canonicalizePath(allocator: Allocator, io: Io, raw_path: []const u8) []const u8 {
    const trimmed = std.mem.trimEnd(u8, raw_path, "/");
    if (trimmed.len == 0) return "/";

    if (std.fs.path.isAbsolute(trimmed)) {
        var buffer: [std.posix.PATH_MAX]u8 = undefined;
        if (Io.Dir.realPathFileAbsolute(io, trimmed, &buffer)) |len| {
            const real_trimmed = std.mem.trimEnd(u8, buffer[0..len], "/");
            return allocator.dupe(u8, real_trimmed) catch trimmed;
        } else |_| {}
    }

    return allocator.dupe(u8, trimmed) catch trimmed;
}

/// Evaluates how well an instance's working directory matches the target directory.
pub fn scorePathMatch(
    allocator: Allocator,
    io: Io,
    target_dir: []const u8,
    nvim_cwd: []const u8,
    target_git_root: ?[]const u8,
    nvim_git_root: ?[]const u8,
) MatchScore {
    const target_canon = canonicalizePath(allocator, io, target_dir);
    defer if (target_canon.ptr != target_dir.ptr) allocator.free(target_canon);

    const nvim_canon = canonicalizePath(allocator, io, nvim_cwd);
    defer if (nvim_canon.ptr != nvim_cwd.ptr) allocator.free(nvim_canon);

    // 1. Exact CWD match
    if (std.mem.eql(u8, target_canon, nvim_canon)) {
        return .exact_cwd;
    }

    // 2. Target directory is a subdirectory inside Neovim's workspace
    if (target_canon.len > nvim_canon.len and
        std.mem.startsWith(u8, target_canon, nvim_canon) and
        target_canon[nvim_canon.len] == '/')
    {
        return .inside_project;
    }

    // 3. Neovim was launched in a subdirectory of the target project
    if (nvim_canon.len > target_canon.len and
        std.mem.startsWith(u8, nvim_canon, target_canon) and
        nvim_canon[target_canon.len] == '/')
    {
        return .inside_nvim_dir;
    }

    // 4. Common Git repository root
    if (target_git_root != null and nvim_git_root != null) {
        const tg_canon = canonicalizePath(allocator, io, target_git_root.?);
        defer if (tg_canon.ptr != target_git_root.?.ptr) allocator.free(tg_canon);

        const ng_canon = canonicalizePath(allocator, io, nvim_git_root.?);
        defer if (ng_canon.ptr != nvim_git_root.?.ptr) allocator.free(ng_canon);

        if (std.mem.eql(u8, tg_canon, ng_canon)) {
            return .git_root_match;
        }
    }

    return .none;
}

fn getEnv(key: [*:0]const u8) ?[:0]const u8 {
    if (std.c.getenv(key)) |ptr| {
        return std.mem.sliceTo(ptr, 0);
    }
    return null;
}

fn setSocketTimeout(fd: std.posix.fd_t, timeout_ms: u32) void {
    if (builtin.os.tag != .windows) {
        const tv = std.posix.timeval{
            .sec = @intCast(timeout_ms / 1000),
            .usec = @intCast((timeout_ms % 1000) * 1000),
        };
        _ = std.posix.setsockopt(fd, std.posix.SOL.SOCKET, std.posix.SO.RCVTIMEO, std.mem.asBytes(&tv)) catch {};
        _ = std.posix.setsockopt(fd, std.posix.SOL.SOCKET, std.posix.SO.SNDTIMEO, std.mem.asBytes(&tv)) catch {};
    }
}

fn connectUnixProbe(socket_path: []const u8) ?Transport {
    if (builtin.os.tag == .windows) return null;
    if (socket_path.len >= 104) return null;

    const socket_rc = std.posix.system.socket(std.posix.AF.UNIX, std.posix.SOCK.STREAM, 0);
    if (std.posix.errno(socket_rc) != .SUCCESS) return null;
    const fd: std.posix.fd_t = @intCast(socket_rc);
    errdefer _ = std.c.close(fd);

    var addr: std.posix.sockaddr.un = .{
        .family = std.posix.AF.UNIX,
        .path = undefined,
    };
    @memcpy(addr.path[0..socket_path.len], socket_path);
    addr.path[socket_path.len] = 0;
    const addr_len: std.posix.socklen_t = @intCast(@offsetOf(std.posix.sockaddr.un, "path") + socket_path.len + 1);

    const rc = std.posix.system.connect(fd, @ptrCast(&addr), addr_len);
    if (std.posix.errno(rc) != .SUCCESS) {
        return null;
    }

    setSocketTimeout(fd, 250);
    return Transport.fromFd(fd);
}

/// Connects to a candidate Unix domain socket and queries its state via MessagePack-RPC.
/// Returns null if the socket is unreachable, unresponsive, dead, or not Neovim.
pub fn probeSocket(
    allocator: Allocator,
    io: Io,
    socket_path: []const u8,
) ?NvimInstance {
    var trans = connectUnixProbe(socket_path) orelse return null;
    errdefer trans.close();

    var n = Nvim.init(allocator, trans) catch {
        trans.close();
        return null;
    };
    defer n.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // Query in a single round-trip: [getcwd(), getpid(), expand('%:p'), v:servername]
    const res = n.eval(alloc, "[getcwd(), getpid(), expand('%:p'), v:servername]") catch return null;
    if (res != .array or res.array.len < 4) return null;

    const cwd_str = switch (res.array[0]) {
        .string => |s| s,
        .binary => |b| b,
        else => return null,
    };
    const pid_val = switch (res.array[1]) {
        .integer => |i| i,
        else => return null,
    };
    const file_str = switch (res.array[2]) {
        .string => |s| s,
        .binary => |b| b,
        else => "",
    };
    const server_str = switch (res.array[3]) {
        .string => |s| s,
        .binary => |b| b,
        else => "",
    };

    const git_root = findGitRoot(io, allocator, cwd_str);

    return NvimInstance{
        .socket_path = allocator.dupe(u8, socket_path) catch return null,
        .pid = pid_val,
        .cwd = allocator.dupe(u8, cwd_str) catch return null,
        .current_file = allocator.dupe(u8, file_str) catch return null,
        .server_name = allocator.dupe(u8, server_str) catch return null,
        .git_root = git_root,
        .match_score = .none,
    };
}

fn scanDirRecursive(
    allocator: Allocator,
    io: Io,
    dir_path: []const u8,
    depth: usize,
    max_depth: usize,
    candidates: *std.ArrayList([]const u8),
    seen: *std.StringHashMapUnmanaged(void),
) void {
    if (depth > max_depth) return;

    var dir = Io.Dir.openDirAbsolute(io, dir_path, .{ .iterate = true }) catch return;
    defer dir.close(io);

    var it = dir.iterate();
    while (it.next(io) catch null) |entry| {
        // Skip hidden dotfiles, except .git or explicit .sock
        if (entry.name.len > 0 and entry.name[0] == '.' and !std.mem.endsWith(u8, entry.name, ".sock")) continue;

        const is_socket = entry.kind == .unix_domain_socket;

        if (is_socket) {
            const is_nvim_candidate = std.mem.startsWith(u8, entry.name, "nvim") or
                std.mem.endsWith(u8, entry.name, ".sock") or
                std.mem.indexOf(u8, dir_path, "nvim") != null;

            if (is_nvim_candidate) {
                const full_path = std.fs.path.join(allocator, &.{ dir_path, entry.name }) catch continue;
                const canon = canonicalizePath(allocator, io, full_path);
                if (!seen.contains(canon)) {
                    const saved = allocator.dupe(u8, canon) catch continue;
                    seen.put(allocator, saved, {}) catch continue;
                    candidates.append(allocator, saved) catch continue;
                }
                if (canon.ptr != full_path.ptr) allocator.free(canon);
                allocator.free(full_path);
            }
        } else if (entry.kind == .directory) {
            if (depth < max_depth) {
                // At top level of search dir, only enter directories containing "nvim"
                // to avoid expensive scanning of giant unrelated cache/temp directories.
                const should_enter = if (depth == 0)
                    std.mem.indexOf(u8, entry.name, "nvim") != null
                else
                    true;

                if (should_enter) {
                    const sub_path = std.fs.path.join(allocator, &.{ dir_path, entry.name }) catch continue;
                    defer allocator.free(sub_path);
                    scanDirRecursive(allocator, io, sub_path, depth + 1, max_depth, candidates, seen);
                }
            }
        }
    }
}

/// Collects all candidate Neovim socket file paths across standard locations.
pub fn findCandidateSockets(
    allocator: Allocator,
    io: Io,
    project_dir: ?[]const u8,
) ![][]const u8 {
    var candidates: std.ArrayList([]const u8) = .empty;
    defer candidates.deinit(allocator);
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    defer seen.deinit(allocator);

    // 1. Check project folder for local socket overrides (e.g. ./nvim.sock, ./.nvim.sock)
    if (project_dir) |pdir| {
        const local_names = [_][]const u8{ "nvim.sock", ".nvim.sock" };
        for (local_names) |name| {
            const full = std.fs.path.join(allocator, &.{ pdir, name }) catch continue;
            const canon = canonicalizePath(allocator, io, full);
            if (Io.Dir.accessAbsolute(io, canon, .{})) |_| {
                if (!seen.contains(canon)) {
                    const saved = try allocator.dupe(u8, canon);
                    try seen.put(allocator, saved, {});
                    try candidates.append(allocator, saved);
                }
            } else |_| {}
            if (canon.ptr != full.ptr) allocator.free(canon);
            allocator.free(full);
        }
    }

    // 2. Check environment variable overrides
    const env_vars = [_][*:0]const u8{ "NVIM", "NVIM_SOCKET_PATH", "NVIM_ADDRESS" };
    for (env_vars) |var_name| {
        if (getEnv(var_name)) |val| {
            if (val.len > 0 and (val[0] == '/' or val[0] == '.')) {
                const canon = canonicalizePath(allocator, io, val);
                if (Io.Dir.accessAbsolute(io, canon, .{})) |_| {
                    if (!seen.contains(canon)) {
                        const duped = try allocator.dupe(u8, canon);
                        try seen.put(allocator, duped, {});
                        try candidates.append(allocator, duped);
                    }
                } else |_| {}
                if (canon.ptr != val.ptr) allocator.free(canon);
            }
        }
    }

    // 3. Search default system runtime / temp directories
    var search_dirs: std.ArrayList([]const u8) = .empty;
    defer search_dirs.deinit(allocator);

    if (getEnv("TMPDIR")) |tmp| {
        try search_dirs.append(allocator, tmp);
    }
    if (getEnv("XDG_RUNTIME_DIR")) |xdg| {
        try search_dirs.append(allocator, xdg);
    }
    try search_dirs.append(allocator, "/tmp");
    if (builtin.os.tag == .macos) {
        try search_dirs.append(allocator, "/private/tmp");
    }

    for (search_dirs.items) |sdir| {
        scanDirRecursive(allocator, io, sdir, 0, 3, &candidates, &seen);
    }

    return try candidates.toOwnedSlice(allocator);
}

/// Discovers all responsive Neovim instances currently listening on local sockets.
pub fn discoverAllInstances(allocator: Allocator, io: Io) ![]NvimInstance {
    const socket_paths = try findCandidateSockets(allocator, io, null);
    defer {
        for (socket_paths) |p| allocator.free(p);
        allocator.free(socket_paths);
    }

    var instances: std.ArrayList(NvimInstance) = .empty;
    defer instances.deinit(allocator);
    var seen_pids: std.AutoHashMapUnmanaged(i64, void) = .empty;
    defer seen_pids.deinit(allocator);

    for (socket_paths) |sock| {
        if (probeSocket(allocator, io, sock)) |inst| {
            if (seen_pids.contains(inst.pid)) {
                inst.deinit(allocator);
                continue;
            }
            try seen_pids.put(allocator, inst.pid, {});
            try instances.append(allocator, inst);
        }
    }

    return try instances.toOwnedSlice(allocator);
}

pub const DiscoveryResult = struct {
    best_match: ?NvimInstance,
    all_instances: []NvimInstance,

    pub fn deinit(self: DiscoveryResult, allocator: Allocator) void {
        if (self.best_match) |bm| {
            bm.deinit(allocator);
        }
        for (self.all_instances) |inst| {
            inst.deinit(allocator);
        }
        allocator.free(self.all_instances);
    }
};

fn compareInstances(target_canon: []const u8, a: NvimInstance, b: NvimInstance) bool {
    // 1. Lower match score is better
    const sa = @intFromEnum(a.match_score);
    const sb = @intFromEnum(b.match_score);
    if (sa != sb) return sa < sb;

    // 2. Active file in target project
    const a_in_file = a.current_file.len > 0 and std.mem.startsWith(u8, a.current_file, target_canon);
    const b_in_file = b.current_file.len > 0 and std.mem.startsWith(u8, b.current_file, target_canon);
    if (a_in_file != b_in_file) return a_in_file;

    // 3. Higher PID (more recently launched)
    return a.pid > b.pid;
}

/// Searches for the Neovim instance matching `target_dir` (or CWD if null).
pub fn findBestMatch(
    allocator: Allocator,
    io: Io,
    target_dir: []const u8,
) !DiscoveryResult {
    const socket_paths = try findCandidateSockets(allocator, io, target_dir);
    defer {
        for (socket_paths) |p| allocator.free(p);
        allocator.free(socket_paths);
    }

    const target_git_root = findGitRoot(io, allocator, target_dir);
    defer if (target_git_root) |tgr| allocator.free(tgr);

    const target_canon = canonicalizePath(allocator, io, target_dir);
    defer if (target_canon.ptr != target_dir.ptr) allocator.free(target_canon);

    var instances: std.ArrayList(NvimInstance) = .empty;
    errdefer {
        for (instances.items) |inst| inst.deinit(allocator);
        instances.deinit(allocator);
    }
    var seen_pids: std.AutoHashMapUnmanaged(i64, void) = .empty;
    defer seen_pids.deinit(allocator);

    for (socket_paths) |sock| {
        if (probeSocket(allocator, io, sock)) |inst| {
            if (seen_pids.contains(inst.pid)) {
                inst.deinit(allocator);
                continue;
            }
            try seen_pids.put(allocator, inst.pid, {});
            var scored_inst = inst;
            scored_inst.match_score = scorePathMatch(
                allocator,
                io,
                target_dir,
                scored_inst.cwd,
                target_git_root,
                scored_inst.git_root,
            );
            try instances.append(allocator, scored_inst);
        }
    }

    if (instances.items.len == 0) {
        return DiscoveryResult{
            .best_match = null,
            .all_instances = try instances.toOwnedSlice(allocator),
        };
    }

    // Sort instances by match relevance
    var best_idx: ?usize = null;
    for (instances.items, 0..) |inst, i| {
        if (!inst.match_score.isMatch()) continue;
        if (best_idx == null or compareInstances(target_canon, inst, instances.items[best_idx.?])) {
            best_idx = i;
        }
    }

    const best: ?NvimInstance = if (best_idx) |idx|
        try instances.items[idx].clone(allocator)
    else
        null;

    return DiscoveryResult{
        .best_match = best,
        .all_instances = try instances.toOwnedSlice(allocator),
    };
}

test "discovery: findGitRoot" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    const cwd = try std.process.currentPathAlloc(io, allocator);
    defer allocator.free(cwd);

    const root_dir = findGitRoot(io, allocator, cwd);
    try std.testing.expect(root_dir != null);
    defer allocator.free(root_dir.?);

    try std.testing.expect(std.mem.endsWith(u8, root_dir.?, "neovim-boss"));
}

test "discovery: scorePathMatch" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    // 1. Exact match
    const s1 = scorePathMatch(allocator, io, "/a/b/c", "/a/b/c", null, null);
    try std.testing.expectEqual(MatchScore.exact_cwd, s1);

    // 2. Subdirectory inside project
    const s2 = scorePathMatch(allocator, io, "/a/b/c/src", "/a/b/c", null, null);
    try std.testing.expectEqual(MatchScore.inside_project, s2);

    // 3. Nvim in subdirectory
    const s3 = scorePathMatch(allocator, io, "/a/b/c", "/a/b/c/src", null, null);
    try std.testing.expectEqual(MatchScore.inside_nvim_dir, s3);

    // 4. Git root match
    const s4 = scorePathMatch(allocator, io, "/a/b/c/pkg1", "/a/b/c/pkg2", "/a/b/c", "/a/b/c");
    try std.testing.expectEqual(MatchScore.git_root_match, s4);

    // 5. Unrelated directories
    const s5 = scorePathMatch(allocator, io, "/x/y/z", "/a/b/c", null, null);
    try std.testing.expectEqual(MatchScore.none, s5);
}

test "discovery: candidate sockets collection" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    const candidates = try findCandidateSockets(allocator, io, null);
    defer {
        for (candidates) |c| allocator.free(c);
        allocator.free(candidates);
    }
}

test "discovery: live nvim socket probe and detection" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    const test_socket = "/tmp/nb_test_discovery.sock";
    _ = Io.Dir.deleteFileAbsolute(io, test_socket) catch {};

    // Spawn an actual nvim instance listening on test_socket
    var child = try std.process.spawn(io, .{
        .argv = &.{ "nvim", "--headless", "--listen", test_socket },
        .stdin = .ignore,
        .stdout = .ignore,
        .stderr = .ignore,
    });
    defer {
        child.kill(io);
        _ = Io.Dir.deleteFileAbsolute(io, test_socket) catch {};
    }

    // Give Neovim a moment to create the socket
    var probed: ?NvimInstance = null;
    var attempts: usize = 0;
    while (attempts < 20) : (attempts += 1) {
        io.sleep(.{ .nanoseconds = 50 * std.time.ns_per_ms }, .awake) catch {};
        probed = probeSocket(allocator, io, test_socket);
        if (probed != null) break;
    }

    try std.testing.expect(probed != null);
    defer probed.?.deinit(allocator);

    try std.testing.expect(probed.?.pid > 0);
    try std.testing.expect(probed.?.cwd.len > 0);

    // Test findBestMatch with this instance's CWD
    var res = try findBestMatch(allocator, io, probed.?.cwd);
    defer res.deinit(allocator);

    try std.testing.expect(res.best_match != null);
    try std.testing.expect(res.best_match.?.match_score.isMatch());
}
