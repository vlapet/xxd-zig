const std = @import("std");

// This file contains the tasks that xxd will need to do
pub const Flags = union(enum) {
    AUTOSKIP,
    BINARY,
    CAPITALIZE,
    COLS: u32,
    FILE: []const u8,
    LEN: u32,
};

pub const UnionHashContext = struct {
    pub fn hash(_: UnionHashContext, key: Flags) u64 {
        var h = std.hash.Fnv1a_64.init(); // <- change the hash algo according to your needs... (WyHash...)
        var buf: [32]u8 = undefined;
        const result = std.fmt.bufPrintZ(buf[0..], "{d}", .{@intFromEnum(key)}) catch unreachable;
        h.update(result);

        return h.final();
    }

    pub fn eql(_: UnionHashContext, a: Flags, b: Flags) bool {
        // return std.mem.eql(u8, a.part_one, b.part_one) and std.mem.eql(u8, a.part_two, b.part_two);
        return @intFromEnum(a) == @intFromEnum(b);
    }
};
