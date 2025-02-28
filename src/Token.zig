const std = @import("std");
const mem = std.mem;

pub const TokenKind = enum(i8) {
    EOF = -1,

    Plus, // '+'
    Minus, // '-'
    Star, // '*'
    Hat, // '^'
    FSlash, // '/'

    Assign, // '<-'

    OpenParen, // '('
    CloseParen, // ')'

    Colon, // ':'
    Comma, // ','

    StringLit,
    IntLit,
    FloatLit,
    Identifier,

    // Data types
    Int,
    Float,

    // Keywords
    Algorithm,
    Var,
    Begin,
    End,
    Dbg,
};

pub const Token = struct {
    const Self = Token;

    kind: TokenKind,
    lexem: []const u8,
    start: usize,
    end: usize,
    line: usize,
    column: usize,

    pub fn init(kind: TokenKind, lexem: []const u8, line: usize, column: usize, start: usize, end: usize) Self {
        return Token{ .kind = kind, .lexem = lexem, .line = line, .column = column, .start = start, .end = end };
    }

    pub fn get_len(self: *const Self) usize {
        return self.end - self.start;
    }

    pub fn dbg(self: *const Self) void {
        std.debug.print("Token(\"{s}\", {}, line: {}, column: {})\n", .{ self.lexem, self.kind, self.line, self.column });
    }

    /// compare this token to other object where:
    ///   - if `other` is `TokenKind` then it compares if the kinds are the same
    ///   - if `other` is `[]const u8` then it compares if the lexems matches
    pub fn is(self: *const Self, other: anytype) bool {
        if (comptime @TypeOf(other) == TokenKind) {
            return self.kind == other;
        } else if (comptime is_string_type(@TypeOf(other))) {
            return mem.eql(u8, self.lexem, other);
        } else {
            @compileError("Expected the `other` to be `TokenKind` or `[]const u8` got `" ++ @typeName(@TypeOf(other)) ++ "`.");
        }
    }
};

pub const TokenList = std.ArrayListUnmanaged(Token);

fn is_string_type(comptime T: type) bool {
    if (T == []const u8) return true;

    const info = @typeInfo(T);
    if (info != .Pointer) return false;

    const ptr_info = info.Pointer;
    if (!ptr_info.is_const) return false;

    const child_info = @typeInfo(ptr_info.child);
    if (child_info != .Array) return false;

    return child_info.Array.child == u8;
}
