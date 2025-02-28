const std = @import("std");

const stdout = std.io.getStdOut().writer();

/// prints formated string and panics if it fails
pub fn print(comptime format: []const u8, args: anytype) void {
    stdout.print(format, args) catch @panic("");
}

pub fn deinit() void {}
