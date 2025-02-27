const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

/// prints formated string and panics if it fails
pub fn print(comptime format: []const u8, args: anytype) void {
    stdout.print(format, args) catch @panic("");
}

pub fn deinit() void {
    bw.flush() catch @panic("");
}
