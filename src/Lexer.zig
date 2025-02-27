const std = @import("std");
const TokenMod = @import("./Token.zig");

const mem = std.mem;
const math = std.math;
const unicode = std.unicode;
const Token = TokenMod.Token;
const TokenKind = TokenMod.TokenKind;
const TokenList = TokenMod.TokenList;

const keywords = std.StaticStringMap(TokenKind).initComptime(.{
    // Data Types
    .{ "entier", TokenKind.Int },
    .{ "réel", TokenKind.Float },

    .{ "algorithme", TokenKind.Algorithm },
    .{ "var", TokenKind.Var },
    .{ "début", TokenKind.Begin },
    .{ "fin", TokenKind.End },
});

pub const LexerError = error{};

pub const Lexer = struct {
    const Self = Lexer;

    allocator: mem.Allocator,
    tokens: *TokenList,
    content: unicode.Utf8Iterator,
    start: usize = 0,
    current: usize = 0,
    line: usize = 1,
    column: usize = 1,
    current_ch: u21 = 0x0,
    previous_ch: u21 = 0x0,
    chars_passed: usize = 0,

    pub fn init(allocator: mem.Allocator, tokens: *TokenList, content: []const u8) !Self {
        return .{ .allocator = allocator, .tokens = tokens, .content = (try unicode.Utf8View.init(content)).iterator() };
    }

    fn dbg(self: *const Self) void {
        std.debug.print("Lexer {{\n  current: {},\n  len: {},\n  curr_ch: `{u}` - `{2}`,\n  prev_ch: `{u}` - `{3}`\n}}\n", .{ self.get_index(), self.content.bytes.len, self.current_ch, self.previous_ch });
    }

    pub fn scan(self: *Self) void {
        _ = self.advance();
        self.current = 0;
        while (!self.is_at_end()) {
            self.start = self.get_index();
            self.chars_passed = 0;
            self.scan_lexem();
            self.column += self.chars_passed;
        }

        const token = Token.init(.EOF, "", self.line, self.column, self.start, self.get_index());
        self.tokens.append(self.allocator, token) catch @panic("Out Of Memory");
    }

    fn scan_lexem(self: *Self) void {
        const ch: u21 = self.advance();
        switch (ch) {
            '+' => self.add_token(.Plus),
            '-' => self.add_token(.Minus),
            '*' => self.add_token(.Star),
            '^' => self.add_token(.Hat),
            '/' => {
                if (self.match('/')) {
                    while (self.peek() != '\n') {
                        _ = self.advance();
                    }
                } else {
                    self.add_token(.FSlash);
                }
            },
            '<' => {
                if (self.match('-')) {
                    self.add_token(.Assign);
                } else {
                    @panic("Unimplemented.");
                }
            },

            ':' => self.add_token(.Colon),
            ',' => self.add_token(.Comma),

            '(' => self.add_token(.OpenParen),
            ')' => self.add_token(.CloseParen),

            ' ', '\r', '\t' => {}, // Skip White spaces

            '\n' => {
                self.line += 1;
                self.column = 0;
            },

            '"', '\'' => self.scan_string(ch),

            else => {
                if (is_digit(ch)) {
                    self.scan_number();
                } else if (is_alpha(ch)) {
                    self.scan_ident();
                } else {
                    std.debug.panic("Unexpected character: `{u}`\n", .{ch});
                }
            },
        }
    }

    fn scan_string(self: *Self, pair: u21) void {
        while (self.peek() != pair) {
            _ = self.advance();
        }

        _ = self.advance(); // Consumes the second pair

        self.add_token(.StringLit);
    }

    fn scan_number(self: *Self) void {
        var kind = TokenKind.IntLit;
        while (is_digit(self.peek())) {
            _ = self.advance();
        }

        if (self.peek() == '.') {
            _ = self.advance();
            while (is_digit(self.peek())) {
                _ = self.advance();
            }
            kind = .FloatLit;
        }

        self.add_token(kind);
    }

    fn scan_ident(self: *Self) void {
        while (is_alphanum(self.peek())) {
            _ = self.advance();
        }

        self.add_token(keywords.get(self.get_lexem()) orelse TokenKind.Identifier);
    }

    fn is_alphanum(ch: u21) bool {
        return is_digit(ch) or is_alpha(ch);
    }

    fn is_digit(ch: u21) bool {
        return ch >= '0' and ch <= '9';
    }

    fn is_alpha(ch: u21) bool {
        if ((ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z') or ch == '_') {
            return true;
        }

        return switch (ch) {
            // Uppercase accented characters and ligatures
            0xC0, // À
            0xC2, // Â
            0xC4, // Ä
            0xC6, // Æ
            0xC7, // Ç
            0xC8, // È
            0xC9, // É
            0xCA, // Ê
            0xCB, // Ë
            0xCE, // Î
            0xCF, // Ï
            0xD4, // Ô
            0xD9, // Ù
            0xDB, // Û
            0xDC, // Ü
            0x152, // Œ
            0x178, // Ÿ

            // Lowercase accented characters and ligatures
            0xE0, // à
            0xE2, // â
            0xE4, // ä
            0xE6, // æ
            0xE7, // ç
            0xE8, // è
            0xE9, // é
            0xEA, // ê
            0xEB, // ë
            0xEE, // î
            0xEF, // ï
            0xF4, // ô
            0xF9, // ù
            0xFB, // û
            0xFC, // ü
            0xFF, // ÿ
            0x153, // œ
            => true,
            else => false,
        };
    }

    fn add_token(self: *Self, kind: TokenKind) void {
        const lexem = self.get_lexem();
        const token = Token.init(kind, lexem, self.line, self.column, self.start, self.get_index());
        self.tokens.append(self.allocator, token) catch @panic("Out Of Memory.");
    }

    fn get_lexem(self: *const Self) []const u8 {
        return self.content.bytes[self.start - 1 .. self.get_index() - 1];
    }

    inline fn peek(self: *const Self) u21 {
        return self.current_ch;
    }

    fn match(self: *Self, ch: u21) bool {
        if (self.peek() == ch) {
            _ = self.advance();
            return true;
        }
        return false;
    }

    fn advance(self: *Self) u21 {
        self.previous_ch = self.current_ch;
        self.current_ch = self.content.nextCodepoint() orelse curr_ch: {
            self.content.i += 1;
            break :curr_ch 0x0;
        };

        self.chars_passed += 1;

        return self.previous_ch;
    }

    fn is_at_end(self: *const Self) bool {
        return self.get_index() > self.get_content_length();
    }

    inline fn get_index(self: *const Self) usize {
        return self.content.i;
    }

    inline fn get_content_length(self: *const Self) usize {
        return self.content.bytes.len;
    }
};
