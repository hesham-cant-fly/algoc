const std = @import("std");
const root = @import("root").root;

const Self = root.Parser;
const AST = root.AST;
const ParserError = root.ParserError;
const Token = root.Token;
const TokenKind = root.TokenKind;

pub fn parse_program(self: *Self) root.ParserError!void {
    self.program.algorithme_id = try parse_algorithm_id(self);
    while (self.match(TokenKind.Var)) |_| {
        self.program.variables.append(try parse_var(self)) catch @panic("Ouf Of Memory");
    }
    try parse_program_block(self, &self.program.program);
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
                const ident = try self.consume(TokenKind.Identifier, "Expected an idetifier after the comma `,`");
                dec.idents.append(ident) catch @panic("Out Of Memory.");
                if (self.match(TokenKind.Comma) == null) {
                    break;
                }
            }
        }
        _ = try self.consume(TokenKind.Colon, "Expected a colon `:` after variable(s) identifier(s)");
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
        TokenKind.Bool => AST.TypeNode.create_bool(self.allocator),
        TokenKind.Identifier => AST.TypeNode.create_id(self.allocator, self.prevous()),
        else => return ParserError.UnexpectedToken,
    };

    const end = self.prevous();
    const tp = AST.Type.create(self.allocator, start, end, node);
    return tp;
}

pub fn parse_program_block(self: *Self, out: *AST.Block) ParserError!void {
    if (self.match(TokenKind.Begin) == null)
        return ParserError.UnexpectedToken;

    while (true) {
        const stmt = try parse_statement(self);
        out.append(self.allocator, stmt) catch @panic("Out Of Memory.");
        if (self.match(TokenKind.EOF)) |_| {
            return ParserError.UnexpectedToken;
        }
        if (self.match(TokenKind.End)) |_| {
            return;
        }
    }
}

pub fn parse_statement(self: *Self) ParserError!*AST.Stmt {
    return switch (self.advance().kind) {
        TokenKind.Dbg => try parse_dbg(self),
        TokenKind.If => try parse_if(self),
        else => res: {
            self.current -= 1;
            break :res parse_assign(self) catch try parse_expr_stmt(self);
        },
    };
}

pub fn parse_assign(self: *Self) ParserError!*AST.Stmt {
    const start = self.peek();
    const expr = try self.parse_assignment();
    const end = self.prevous();
    const node = AST.StmtNode.create_expr(self.allocator, expr);
    const stmt = AST.Stmt.create(self.allocator, start, end, node);
    return stmt;
}

pub fn parse_expr_stmt(self: *Self) ParserError!*AST.Stmt {
    const start = self.peek();
    const expr = try self.parse_expression();
    const end = self.prevous();
    const node = AST.StmtNode.create_expr(self.allocator, expr);
    const stmt = AST.Stmt.create(self.allocator, start, end, node);
    return stmt;
}

pub fn parse_dbg(self: *Self) ParserError!*AST.Stmt {
    const start = self.prevous();
    const expr = try self.parse_expression();
    const end = self.prevous();
    const node = AST.StmtNode.create_dbg(self.allocator, expr);
    const stmt = AST.Stmt.create(self.allocator, start, end, node);
    return stmt;
}

pub fn parse_if(self: *Self) ParserError!*AST.Stmt {
    const start = self.prevous();
    const condition = try self.parse_expression();
    _ = try self.consume(.Then, "Expected 'alors' after si condition");
    var then_cluase = AST.Block.initCapacity(self.allocator, 0) catch @panic("Out Of Memory.");
    while ((!self.is_at_end()) and (self.peek().kind != .EndIf) and (self.peek().kind != .Else) and (self.peek().kind != .ElseIf)) {
        const stmt = try self.parse_statement();
        then_cluase.append(self.allocator, stmt) catch @panic("Ouf Of Memory.");
    }

    var else_if: ?AST.ElseIfNode = null;
    if (self.match(TokenKind.ElseIf)) |_| {
        else_if = AST.ElseIfNode{
            .condition = undefined,
            .body = AST.Block.initCapacity(self.allocator, 1) catch @panic("Out Of Memory."),
            .next = null,
        };
        var current = &else_if.?;
        while (true) {
            current.condition = try self.parse_expression();
            _ = try self.consume(.Then, "Expected `alors` after the condition.");
            while (!(self.check(.Else) or self.check(.EndIf) or self.check(.ElseIf))) {
                current.body.append(self.allocator, try self.parse_statement()) catch @panic("Out Of Memory.");
            }
            if (self.match(TokenKind.ElseIf) == null) {
                break;
            } else {
                current.next = self.allocator.create(AST.ElseIfNode) catch @panic("Out Of Memory.");
                current.next.?.* = AST.ElseIfNode{
                    .condition = undefined,
                    .body = AST.Block.initCapacity(self.allocator, 1) catch @panic("Out Of Memory."),
                    .next = null,
                };
                current = current.next.?;
            }
        }
    }
    var else_: ?AST.Block = null;
    if (self.match(TokenKind.Else)) |_| {
        else_ = AST.Block.initCapacity(self.allocator, 1) catch @panic("Out Of Memory.");
        while (!self.check(TokenKind.EndIf)) {
            else_.?.append(self.allocator, try self.parse_statement()) catch @panic("Out Of Memory.");
        }
    }
    _ = try self.consume(.EndIf, "Expected 'finsi' as closing of a if statement.");

    const end = self.prevous();
    const node = AST.StmtNode.create_if(self.allocator, condition, then_cluase, else_if, else_);
    const res = AST.Stmt.create(self.allocator, start, end, node);
    return res;
}
