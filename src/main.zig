const std = @import("std");
const flags = @import("flags.zig");
const hm = std.AutoHashMap(flags.Flags, ?i32);

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var argsIter = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIter.deinit();

    _ = argsIter.next();

    var args = flags.Flags{};

    var infile: ?[]u8 = null;
    var outfile: ?[]u8 = null;
    while (argsIter.next()) |arg| {
        std.debug.print("arg: {s}\n", .{arg});
        _ = try match_arg(arg, &argsIter, &args, &infile, &outfile);
    }

    // std.debug.print("args:{any}\n", .{args});
    if (infile == null or args.help) {
        try print_help();
        return;
    }

    if (args.binary) {
        args.groupsize = 1;
    }

    if (args.debug) std.debug.print("Finished processing args - begin processing\n\n", .{});

    try process(args, infile.?, outfile, allocator);
}

fn match_arg(arg: []const u8, argsIter: *std.process.ArgIterator, args: *flags.Flags, infile: *?[]u8, outfile: *?[]u8) anyerror!void {
    std.debug.print("==> arg:{s}\n", .{arg});
    std.debug.print("==> file:{s}\n", .{infile});

    if (infile.* == null and arg[0] == '-') {
        std.debug.print("in if ==> {s}\n", .{arg[1..]});

        const flag = arg[1..];

        if (std.mem.eql(u8, flag, "a")) {
            args.autoskip = true;
        } else if (std.mem.eql(u8, flag, "b")) {
            args.binary = true;
        } else if (std.mem.eql(u8, flag, "C")) {
            args.capitalize = true;
        } else if (std.mem.eql(u8, flag[0..1], "c")) {
            args.cols = try std.fmt.parseInt(u32, try try_get_next_arg(argsIter), 10);
        } else if (std.mem.eql(u8, flag, "l")) {
            // const val = try std.fmt.parseInt(u32, try try_get_next_arg(argsIter), 10);
            args.len = try std.fmt.parseInt(u32, try try_get_next_arg(argsIter), 10);
        } else if (std.mem.eql(u8, flag, "h")) {
            args.help = true;
        } else if (std.mem.eql(u8, flag, "r")) {
            args.reversed = true;
        } else if (std.mem.eql(u8, flag, "s")) {
            args.seek = try std.fmt.parseInt(i32, try try_get_next_arg(argsIter), 10);
        } else if (std.mem.eql(u8, flag, "de")) {
            args.debug = true;
        } else if (std.mem.eql(u8, flag, "g")) {
            args.groupsize = try std.fmt.parseInt(u32, try try_get_next_arg(argsIter), 10);
        } else if (std.mem.eql(u8, flag, "p") or std.mem.eql(u8, flag, "ps") or std.mem.eql(u8, flag, "postscript") or std.mem.eql(u8, flag, "plain")) {
            args.plain = true;
        } else if (std.mem.eql(u8, flag, "i")) {
            args.include = true;
        } else if (std.mem.eql(u8, flag, "d")) {
            args.decimal = true;
        } else {
            std.debug.print("unmatched arg\n", .{});
        }

        return;
    } else if (infile.* == null) {
        std.debug.print("else if :==> {s}\n", .{arg});
        infile.* = @constCast(arg);
        return;
    } else if (outfile.* == null) {
        outfile.* = @constCast(arg);
        return;
    }

    try print_help();

    return error.ONE;
}

fn try_get_next_arg(argsIter: *std.process.ArgIterator) anyerror![]const u8 {
    if (argsIter.next()) |a| {
        return a;
    } else {
        return error.NullValue;
    }
}

fn process(args: flags.Flags, infile: []const u8, outfile: ?[]const u8, allocator: std.mem.Allocator) !void {
    _ = allocator; // autofix

    const handle = try std.fs.cwd().openFile(infile, .{});
    defer handle.close();
    var bytes_per_line: u32 = args.cols;
    bytes_per_line = bytes_per_line;
    if (args.binary) {
        bytes_per_line = 6;
    } else if (args.plain) {
        bytes_per_line = 30;
    }

    const lines = if (args.len == @constCast(&std.math.maxInt(i32)).*) @constCast(&std.math.maxInt(i32)).* else @divTrunc(args.len, bytes_per_line) + 1;
    if (args.debug) {
        std.debug.print("lines: {d}\n", .{lines});
        std.debug.print("len: {d}\n", .{args.len});
        std.debug.print("bytes_per_line: {d}\n", .{bytes_per_line});
    }

    const writer = std.io.getStdOut().writer();
    const file_writer = if (outfile) |o| std.fs.cwd().createFile(o, .{}) catch null else null;

    const out_writer = if (file_writer) |f| f.writer() else writer;

    const reader = handle.reader();

    var buffered_reader = std.io.bufferedReader(reader);
    var total_bytes_read: u32 = 0;
    total_bytes_read += 0;

    if (args.seek > 0) {
        try buffered_reader.reader().skipBytes(@abs(args.seek), .{});
    } else if (args.seek < 0) {
        const file_len = (try handle.stat()).size;
        try buffered_reader.reader().skipBytes(file_len - @abs(args.seek), .{});
    }

    // const c_include = if (args.include and !args.binary) true else false;
    const c_include = if (args.include and !args.reversed) true else false;
    const plain = if (args.plain or c_include) true else false;

    if (args.debug) std.debug.print("c_include: {}\tplain: {}\n", .{ c_include, plain });

    var i: u32 = 0;
    // var arr = std.ArrayList(u8).init(allocator);
    var total_buf: [1024]u8 = std.mem.zeroes([1024]u8);

    if (c_include) {
        try out_writer.print("unsigned char ", .{});

        for (infile) |*c| {
            try out_writer.print("{c}", .{if (std.ascii.isAlphanumeric(c.*)) c.* else '_'});
        }

        try out_writer.print("[] = {{\n", .{});
    }

    // Work in progress
    if (args.reversed) {
        if (!args.binary and !args.decimal) {
            // Hexadecimal case
            var buf_t: [2]u8 = std.mem.zeroes([2]u8);
            while (try buffered_reader.read(&buf_t) > 0) {
                var sum: u16 = 0;

                for (buf_t[0..]) |*b| {
                    sum = sum * 16 + @as(u8, (@intCast(std.fmt.charToDigit(b.*, 16) catch 0)));
                }
                try out_writer.print("{c}", .{@as(u8, @intCast(sum))});
            }
        }
        return;
    }

    while (i < args.len) {
        const to_read = @as(usize, if (total_bytes_read + bytes_per_line < args.len) @intCast(bytes_per_line) else @intCast(args.len - total_bytes_read));

        var buf_to_read = total_buf[0..to_read];

        if (args.debug) {
            std.debug.print("to_read: {d}\n", .{to_read});
            std.debug.print("total_bytes_read before: {d}\n", .{total_bytes_read});
        }

        const bytes_read = buffered_reader.read(buf_to_read) catch break;

        if (bytes_read == 0) {
            break;
        }
        total_bytes_read += @intCast(bytes_read);
        // const buf = buf_to_read[0..bytes_read];
        const buf = buf_to_read[0..bytes_read];

        // if (args.reversed) {
        //     // for (buf) |*x| {
        //     //     x.* = std.fmt.format(writer: anytype, comptime fmt: []const u8, args: anytype);
        //     // }
        //     _ = try std.fmt.hexToBytes(buf, buf);
        // }

        if (args.debug) {
            std.debug.print("total_bytes_read after: {d}\n", .{total_bytes_read});
        }
        // std.debug.print("!!!\n", .{});

        // replace_newline(buf);

        if (!plain and !args.decimal) {
            try out_writer.print("{x:0>8}: ", .{i * bytes_per_line});
        } else if (!plain) {
            try out_writer.print("{d:0>8}: ", .{i * bytes_per_line});
        }
        if (c_include) {
            try out_writer.print("  ", .{});
        }
        const window = std.mem.window(u8, buf, 1, 1);
        var count: u8 = 0;
        while (@constCast(&window).*.next()) |w| {
            count += 1;
            if (!args.binary) {
                if (c_include) {
                    try out_writer.print("0x", .{});
                }
                try out_writer.print("{x:0>2}", .{w[0]});

                // if (@mod(count, 2) == 0) {
                if (c_include) {
                    try out_writer.print(", ", .{});
                } else if (args.groupsize > 0 and @mod(count, args.groupsize) == 0 and !args.plain) {
                    try out_writer.print(" ", .{});
                }
            } else {
                if (c_include) {
                    try out_writer.print("0b", .{});
                }
                try out_writer.print("{b:0>8}", .{w[0]});
                if (args.groupsize > 0 and @mod(count, args.groupsize) == 0) {
                    try out_writer.print(" ", .{});
                }
            }
        }

        for (bytes_read..@abs(bytes_per_line)) |_| {
            count += 1;
            if (!args.binary) {
                try out_writer.print("{s: >2}", .{" "});

                // if (@mod(count, 2) == 0) {
                if (args.groupsize > 0 and @mod(count, args.groupsize) == 0) {
                    try out_writer.print(" ", .{});
                }
            } else {
                try out_writer.print("{s: >8}", .{" "});
                if (args.groupsize > 0 and @mod(count, args.groupsize) == 0) {
                    try out_writer.print(" ", .{});
                }
            }
        }
        // replace_newline(buf);
        _ = std.mem.replace(u8, buf, "\r\n", "..", buf);
        _ = std.mem.replace(u8, buf, "\r", ".", buf);
        _ = std.mem.replace(u8, buf, "\n", ".", buf);

        if (std.mem.indexOf(u8, buf, "\n")) |_| @panic("CONTAINS \n!!!");
        if (std.mem.indexOf(u8, buf, "\r\n")) |_| @panic("CONTAINS \\r\\n!!!");
        if (std.mem.indexOf(u8, buf, "\r")) |pos| {
            std.debug.panic("CONTAINS \\r at: {d}\tbuf: {s}!!!", .{ pos, buf });
        }

        if (!plain) {
            try out_writer.print(" {s}", .{buf});
        }

        try out_writer.print("\n", .{});

        i = i + 1;

        // if (i == 2) break;
    }

    if (c_include) {
        try out_writer.print("}};\n", .{});

        try out_writer.print("unsigned int ", .{});
        for (infile) |*c| {
            try out_writer.print("{c}", .{if (std.ascii.isAlphanumeric(c.*)) c.* else '_'});
        }

        // try out_writer.print("_len = {d};\n", .{args.len});
        try out_writer.print("_len = {d};\n", .{total_bytes_read});
    }
}

fn print_help() !void {
    const writer = std.io.getStdOut().writer();
    try writer.print("{s}\n", .{
        \\Usage:
        \\       xxd [options] [infile [outfile]]
        \\    or
        \\       xxd -r [-s [-]offset] [-c cols] [-ps] [infile [outfile]]
        \\Options:
        \\    -a          toggle autoskip: A single '*' replaces nul-lines. Default off.
        \\    -b          binary digit dump (incompatible with -ps,-i,-r). Default hex.
        \\    -C          capitalize variable names in C include file style (-i).
        \\    -c cols     format <cols> octets per line. Default 16 (-i: 12, -ps: 30).
        \\    -E          show characters in EBCDIC. Default ASCII.
        \\    -e          little-endian dump (incompatible with -ps,-i,-r).
        \\    -g bytes    number of octets per group in normal output. Default 2 (-e: 4).
        \\    -h          print this summary.
        \\    -i          output in C include file style.
        \\    -l len      stop after <len> octets.
        \\    -o off      add <off> to the displayed file position.
        \\    -ps         output in postscript plain hexdump style.
        \\    -r          reverse operation: convert (or patch) hexdump into binary.
        \\    -r -s off   revert with <off> added to file positions found in hexdump.
        \\    -d          show offset in decimal instead of hex.
        \\    -s [+][-]seek  start at <seek> bytes abs. (or +: rel.) infile offset.
        \\    -u          use upper case hex letters.
        \\    -v          show version: "xxd 2021-10-22 by Juergen Weigert et al.".
    });
}

fn replace_newline(buf: []u8) void {
    for (buf) |*b| {
        b.* = switch (b.*) {
            '\n' => '.',
            else => |z| z,
        };
    }
}
