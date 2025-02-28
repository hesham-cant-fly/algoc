const std = @import("std");
const root = @import("root.zig");
const expressions = @import("./Parsing/expression.zig");
const statement = @import("./Parsing/statement.zig");

const mem = std.mem;
const AST = root.AST;
const Token = root.Token;
const TokenList = root.TokenList;
const TokenKind = root.TokenKind;

pub const ParserError = error{UnexpectedToken};

pub const Parser = struct {
    const Self = Parser;

    allocator: mem.Allocator,
    content: []const u8,
    tokens: TokenList,
    program: AST.Program,
    current: usize = 0,

    pub const parse_expression = expressions.parse_expression;
    pub const parse_program = statement.parse_program;

    pub fn init(allocator: mem.Allocator, content: []const u8, tokens: TokenList) Self {
        return Parser{
            .allocator = allocator,
            .content = content,
            .tokens = tokens,
            .program = AST.Program.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.program.deinit();
    }

    pub fn parse(self: *Parser) ParserError!AST.Program {
        try self.parse_program();
        return self.program;
    }

    pub fn peek(self: *const Self) *const Token {
        return &self.tokens.items[self.current];
    }

    pub fn check(self: *const Self, kind: TokenKind) bool {
        if (self.is_at_end()) return false;
        return self.peek().kind == kind;
    }

    pub fn match(self: *Parser, comptime kinds: anytype) ?*const Token {
        const kinds_type = @TypeOf(kinds);
        if (comptime kinds_type == TokenKind) {
            const kind = @as(TokenKind, kinds);
            if (self.check(kind)) {
                return self.advance();
            }
            return null;
        } else {
            var entries: [kinds.len]TokenKind = undefined;
            inline for (kinds, 0..) |value, i| {
                const v = @as(TokenKind, value);
                entries[i] = v;
            }
            for (entries) |value| {
                if (self.check(value)) {
                    return self.advance();
                }
            }
            return null;
        }
    }

    pub fn consume(self: *Self, kind: TokenKind, message: []const u8) ParserError!*const Token {
        if (!self.check(kind)) {
            root.report_error(self.content, message, self.peek());
            return ParserError.UnexpectedToken;
        }
        return self.advance();
    }

    pub fn advance(self: *Self) *const Token {
        if (!self.is_at_end()) self.current += 1;
        return self.prevous();
    }

    pub fn prevous(self: *const Self) *const Token {
        return &self.tokens.items[self.current - 1];
    }

    pub fn is_at_end(self: *const Self) bool {
        return self.peek().is(TokenKind.EOF);
    }
};
