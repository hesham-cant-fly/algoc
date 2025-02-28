const std = @import("std");
const root = @import("root").root;

const print = root.common.print;
const Token = root.Token;

pub fn report_error(content: []const u8, message: []const u8, at: *const Token) void {
    const line = get_lines(content, at.start, 1);
    print("Error [{}:{}] at '{s}': {s}\n", .{ at.line, at.column, at.lexem, message });
    print("{} | {s}\n", .{ at.line, line });
}

fn get_lines(content: []const u8, index: usize, padding: usize) []const u8 {
    if (index >= content.len)
        return "";

    var start: usize = index;
    var end: usize = index;
    var lines: usize = 0;

    while (start > 0) : (start -= 1) {
        if (content[start - 1] == '\n') {
            lines += 1;
        }

        if (lines == padding) {
            lines = 0;
            break;
        }
    }

    while (end < content.len) : (end += 1) {
        if (content[end] == '\n') {
            lines += 1;
        }

        if (lines == padding) {
            break;
        }
    }

    return content[start..end];
}
