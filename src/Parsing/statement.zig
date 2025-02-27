const std = @import("std");
const root = @import("root").root;

const Self = root.Parser;
const AST = root.AST;
const ParserError = root.ParserError;
const Token = root.Token;
const TokenKind = root.TokenKind;

pub fn parse_program(self: *Self) root.ParserError!AST.Program {
    var result_program = AST.Program.init(self.allocator);

    result_program.algorithme_id = try parse_algorithm_id(self);
    while (self.match(TokenKind.Var)) |_| {
        result_program.variables.append(try parse_var(self)) catch @panic("Ouf Of Memory");
    }
    try parse_program_block(self, &result_program.program);

    return result_program;
}

pub fn parse_algorithm_id(self: *Self) root.ParserError!*const Token {
    if (self.match(TokenKind.Algorithm) == null) return ParserError.UnexpectedToken;
    if (self.match(TokenKind.Identifier)) |tok| {
        return tok;
    }
    return ParserError.UnexpectedToken;
}

pub fn parse_var(self: *Self) ParserError!AST.VarDec {
    var result = AST.VarDec.init(self.allocator);

    while (self.match(TokenKind.Identifier)) |id| {
        var dec = AST.VarDec.Dec.init(self.allocator);
        dec.idents.append(id) catch @panic("Ouf Of Memory.");

        if (self.match(TokenKind.Comma)) |_| {
            while (true) {
                const ident = try self.consume(TokenKind.Identifier);
                dec.idents.append(ident) catch @panic("Out Of Memory.");
                if (self.match(TokenKind.Comma) == null) {
                    break;
                }
            }
        }
        _ = try self.consume(TokenKind.Colon);
        dec.tp = try parse_type(self);
        result.declarations.append(dec) catch @panic("Ouf Of Memory.");
    }

    return result;
}

pub fn parse_type(self: *Self) ParserError!*AST.Type {
    const start = self.peek();
    const node = switch (self.advance().kind) {
        TokenKind.Int => AST.TypeNode.create_int(self.allocator),
        TokenKind.Float => AST.TypeNode.create_float(self.allocator),
        TokenKind.Identifier => AST.TypeNode.create_id(self.allocator, self.prevous()),
        else => return ParserError.UnexpectedToken,
    };
    const end = self.prevous();
    const tp = AST.Type.create(self.allocator, start, end, node);
    return tp;
}

pub fn parse_program_block(self: *Self, out: *std.ArrayList(*AST.Stmt)) ParserError!void {
    if (self.match(TokenKind.Begin) == null)
        return ParserError.UnexpectedToken;

    while (true) {
        const stmt = try parse_expr_stmt(self);
        out.append(stmt) catch @panic("Out Of Memory.");
        if (self.match(TokenKind.EOF)) |_| {
            return ParserError.UnexpectedToken;
        }
        if (self.match(TokenKind.End)) |_| {
            return;
        }
    }
}

pub fn parse_expr_stmt(self: *Self) ParserError!*AST.Stmt {
    const start = self.peek();
    const expr = try self.parse_expression();
    const end = self.prevous();
    const node = AST.StmtNode.create_expr(self.allocator, expr);
    const stmt = AST.Stmt.create(self.allocator, start, end, node);
    return stmt;
}
