const std = @import("std");
const root = @import("root").root;

const TokenKind = root.TokenKind;

const AST = root.AST;
const Expr = AST.Expr;
const ExprNode = AST.ExprNode;

const Self = root.Parser;
const Result = root.ParserError!*AST.Expr;

pub fn parse_expression(self: *Self) Result {
    return parse_assignment(self);
}

fn parse_assignment(self: *Self) Result {
    const start = self.peek();
    const lhs = try self.consume(TokenKind.Identifier);
    if (self.match(TokenKind.Assign)) |op| {
        const rhs = try parse_term(self);
        const end = self.prevous();
        const node = AST.ExprNode.create_assign(self.allocator, op, lhs, rhs);
        const expr = AST.Expr.create(self.allocator, start, end, node);
        return expr;
    }
    return parse_term(self);
}

fn parse_term(self: *Self) Result {
    const start = self.peek();
    var left = try parse_factor(self);

    while (self.match(.{ TokenKind.Plus, TokenKind.Minus })) |op| {
        const right = try parse_factor(self);
        const node = ExprNode.create_binary(self.allocator, op, left, right);
        const end = self.prevous();
        left = Expr.create(self.allocator, start, end, node);
    }

    return left;
}

fn parse_factor(self: *Self) Result {
    const start = self.peek();
    var left = try parse_power(self);

    while (self.match(.{ TokenKind.Star, TokenKind.FSlash })) |op| {
        const right = try parse_power(self);
        const node = ExprNode.create_binary(self.allocator, op, left, right);
        const end = self.prevous();
        left = Expr.create(self.allocator, start, end, node);
    }

    return left;
}

fn parse_power(self: *Self) Result {
    const start = self.peek();
    var left = try parse_primary(self);

    while (self.match(TokenKind.Hat)) |op| {
        const right = try parse_primary(self);
        const node = ExprNode.create_binary(self.allocator, op, left, right);
        const end = self.prevous();
        left = Expr.create(self.allocator, start, end, node);
    }

    return left;
}

fn parse_primary(self: *Self) Result {
    const start = self.peek();
    if (self.match(.{ TokenKind.StringLit, TokenKind.IntLit, TokenKind.FloatLit, TokenKind.Identifier })) |tok| {
        const node = ExprNode.create_primary(self.allocator, tok);
        const end = self.prevous();
        return Expr.create(self.allocator, start, end, node);
    }

    if (self.match(TokenKind.OpenParen)) |_| {
        return parse_grouping(self);
    }

    return root.ParserError.UnexpectedToken;
}

fn parse_grouping(self: *Self) Result {
    const start = self.prevous();
    const expr = try parse_expression(self);

    if (self.match(TokenKind.CloseParen)) |end| {
        const node = ExprNode.create_grouping(self.allocator, expr);
        return Expr.create(self.allocator, start, end, node);
    }

    return root.ParserError.UnexpectedToken;
}
