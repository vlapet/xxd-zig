const std = @import("std");
const flags = @import("flags.zig");
const hm = std.HashMap(flags.Flags, ?u32, flags.UnionHashContext, std.hash_map.default_max_load_percentage);

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var argsIter = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIter.deinit();

    _ = argsIter.next();

    // std.debug.print("{any}", .{argsIter.next().?});

    // var is_flag = false;

    // var args = std.ArrayList(flags.Flags).init(allocator);
    // var args = std.AutoHashMap(flags.Flags, void).init(allocator);

    // var args = std.HashMap(flags.Flags, void, std.hash_map.AutoContext(flags.Flags), std.hash_map.default_max_load_percentage).init(allocator);
    var args = hm.init(allocator);
    // var args = std.HashMap(flags.Flags, void).init(allocator);
    // var args = std.hash_map.AutoHashMap(flags.Flags, null).init(allocator);

    var file: []u8 = undefined;
    while (argsIter.next()) |arg| {
        std.debug.print("arg: {s}\n", .{arg});
        // is_flag = true;
        // const flag = try match_arg(arg, &argsIter, allocator);
        const flag = try match_arg(arg, &argsIter, &args, allocator);
        std.debug.print("flag: {}\t-(flag): {}\n", .{ flag, @intFromEnum(flag) });
        //        if (@intFromEnum(flag) != @intFromEnum(flags.Flags.FILE)) {
        //          try args.put(flag, {});
        //    } else if (@as(flags.Flags.FILE, @bitCast(flag))) |f| {
        //      file = f;
        //    std.debug.print("file: {any}", .{file});
        //}

        switch (flag) {
            .FILE => |f| {
                file = @constCast(f);
                std.debug.print("file: {s}\n", .{file});
            },
            // else => try args.put(flag, {}),
            else => continue,
        }
    }

    std.debug.print("args:{any}\n", .{args});

    try process(args, file);
}

fn match_arg(arg: []const u8, argsIter: *std.process.ArgIterator, args: *hm, allocator: std.mem.Allocator) anyerror!flags.Flags {
    if (arg[0] == '-') {
        const flag = arg[1..];

        if (std.mem.eql(u8, flag, "a")) {
            try args.put(flag, null);
            return .AUTOSKIP;
        } else if (std.mem.eql(u8, flag, "b")) {
            try args.put(flag, null);

            return .BINARY;
        } else if (std.mem.eql(u8, flag, "C")) {
            try args.put(flag, null);
            return .CAPITALIZE;
        } else if (std.mem.eql(u8, flag, "c")) {
            if (argsIter.next()) |a| {
                try args.put(flag, a);
                return .{ .COLS = try std.fmt.parseInt(u32, a, 10) };
            } else {
                return error.NullValue;
            }
        } else if (std.mem.eql(u8, flag, "l")) {
            const val = try std.fmt.parseInt(u32, try try_get_next_arg(argsIter), 10);
            try args.put(flag, val);

            return .{ .LEN = val };
        }

        const param = argsIter.next().?;

        _ = .{ .f = flag, .p = param }; // Stop the compiler from complaining
    } else {
        _ = allocator;
        return .{ .FILE = arg };
        // const s = .{ .FILE = undefined }; // DANGLING POINTER FIX MEEEE!
        // std.mem.copyBackwards(u8, s.FILE, arg);
        // return s;
        // return .{ .FILE = try allocator.dupe(u8, arg) }; // DANGLING POINTER FIX MEEEE!
    }

    return error.s;
}

// fn match_arg(arg: []const u8, argsIter: *std.process.ArgIterator, allocator: std.mem.Allocator) anyerror!flags.Flags {
//     if (arg[0] == '-') {
//         const flag = arg[1..];

//         if (std.mem.eql(u8, flag, "a")) {
//             return .AUTOSKIP;
//         } else if (std.mem.eql(u8, flag, "b")) {
//             return .BINARY;
//         } else if (std.mem.eql(u8, flag, "C")) {
//             return .CAPITALIZE;
//         } else if (std.mem.eql(u8, flag, "c")) {
//             if (argsIter.next()) |a| {
//                 return .{ .COLS = try std.fmt.parseInt(u32, a, 10) };
//             } else {
//                 return error.NullValue;
//             }
//         } else if (std.mem.eql(u8, flag, "l")) {
//             return .{ .LEN = try std.fmt.parseInt(u32, try try_get_next_arg(argsIter), 10) };
//         }

//         const param = argsIter.next().?;

//         _ = .{ .f = flag, .p = param }; // Stop the compiler from complaining
//     } else {
//         _ = allocator;
//         return .{ .FILE = arg };
//         // const s = .{ .FILE = undefined }; // DANGLING POINTER FIX MEEEE!
//         // std.mem.copyBackwards(u8, s.FILE, arg);
//         // return s;
//         // return .{ .FILE = try allocator.dupe(u8, arg) }; // DANGLING POINTER FIX MEEEE!
//     }

//     return error.s;
// }

fn try_get_next_arg(argsIter: *std.process.ArgIterator) anyerror![]const u8 {
    if (argsIter.next()) |a| {
        return a;
    } else {
        return error.NullValue;
    }
}

fn process(args: hm, file: []const u8) !void {
    const handle = try std.fs.cwd().openFile(file, .{});
    args.contains(.LEN);
    // args.getEntry(key: K)
    // _ = args;

    const writer = std.io.getStdOut().writer();
    //    const reader_t = std.io.getStdIn();
    const reader = handle.reader();
    var buffered_reader = std.io.bufferedReader(reader);

    try writer.print("test\n", .{});
    // try writer.print("read:{c}\n", .{try reader.readByte()});

    var i: i32 = 0;

    //while (i < 2) {
    //    var buf: [16]u8 = undefined;
    //    const x = reader.read(&buf) catch break;
    //    if (x == 0) break;
    //    try writer.print("{x}:{x}\t{s}\n", .{ i * 16, buf, buf });
    //    i = i + 1;
    // }

    while (i < 3) {
        var buf: [16]u8 = undefined;
        var bufstr: [32]u8 = undefined;

        const bytes_read = buffered_reader.read(&buf) catch break;
        if (bytes_read == 0) break;

        for (buf, 0..) |b, j| {
            // bs.* = std.fmt.parseUnsigned(u8, ([_]u8{b})[0..], 16) catch 0;
            // const parse = std.fmt.parseUnsigned(u64, ([_]u8{b})[0..], 16) catch unreachable;
            var buf2: [2]u8 = undefined;
            _ = try std.fmt.bufPrint(&buf2, "{x}", .{b});
            // bufstr[2 * j] = buf[0];
            // bufstr[2 * j + 1] = buf[1];
            std.mem.copyBackwards(u8, bufstr[2 * j .. 2 * j + 1], buf[0..1]);
            std.mem.copyBackwards(u8, bufstr[2 * j + 1 .. 2 * j + 2], buf[1..2]);

            // std.debug.print("parse: {d}", .{parse});
            std.debug.print("buf2: {s}\n", .{buf2});
            // _ = bs;
            // _ = j;
        }

        for (&buf) |*b| {
            b.* = switch (b.*) {
                '\n' => '.',
                else => |z| z,
            };
        }

        // try writer.print("{x:0>4}:{x}\t{s}\n", .{ i * 16, buf, buf });
        // try writer.print("{x:0>4}:{s}\t{s}\n", .{ i * 16, bufstr, buf });
        // try writer.print("{x:0>4}:{x}\t{s}\n", .{ i * 16, bufstr, buf });
        try writer.print("==========\n", .{});
        try writer.print("{x:0>4}:{s}\t{s}\n", .{ i * 16, std.fmt.fmtSliceHexLower(&buf), buf });
        // try writer.print("{x:0>4}:{s}\t{s}\n", .{ i * 16, std.fmt.fmtSliceHexLower(&bufstr), buf });
        // try writer.print("{x:0>4}:{x}\t{s}\n", .{ i * 16, std.fmt.fmtSliceHexLower(&bufstr), buf });
        i = i + 1;
    }
}
