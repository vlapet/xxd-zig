const std = @import("std");

// This file contains the tasks that xxd will need to do
// pub const Flags = enum {
// AUTOSKIP,
// BINARY,
// CAPITALIZE,
// COLS,
// DEBUG,
// FILE,
// GROUPSIZE,
// HELP,
// INCLUDE,
// LEN,
// PLAIN,
// REVERSED,
// SEEK,
// };

pub const Flags = struct {
    autoskip: bool = false,
    binary: bool = false,

    capitalize: bool = false,
    cols: u32 = 16,
    debug: bool = false,
    decimal: bool = false,
    // file: []const u8,
    groupsize: u32 = 2,
    help: bool = false,
    include: bool = false,
    len: u32 = @constCast(&std.math.maxInt(i32)).*,
    plain: bool = false,
    reversed: bool = false,
    seek: i32 = 0,
};
