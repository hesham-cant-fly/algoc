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
    if (self.match(TokenKind.Identifier)) |id| {
        if (self.match(.{ TokenKind.Assign, TokenKind.Eq })) |op| {
            const rhs = try parse_or(self);
            const end = self.prevous();
            const node = AST.ExprNode.create_assign(self.allocator, op, id, rhs);
            const expr = AST.Expr.create(self.allocator, start, end, node);
            return expr;
        }
        self.current -= 1;
    }
    return parse_or(self);
}

fn parse_or(self: *Self) Result {
    const start = self.peek();
    var left = try parse_and(self);

    while (self.match(.{TokenKind.Or})) |op| {
        const right = try parse_and(self);
        const node = ExprNode.create_binary(self.allocator, op, left, right);
        const end = self.prevous();
        left = Expr.create(self.allocator, start, end, node);
    }

    return left;
}

fn parse_and(self: *Self) Result {
    const start = self.peek();
    var left = try parse_equality(self);

    while (self.match(.{TokenKind.And})) |op| {
        const right = try parse_equality(self);
        const node = ExprNode.create_binary(self.allocator, op, left, right);
        const end = self.prevous();
        left = Expr.create(self.allocator, start, end, node);
    }

    return left;
}

fn parse_equality(self: *Self) Result {
    const start = self.peek();
    var left = try parse_comparation(self);

    while (self.match(.{ TokenKind.Eq, TokenKind.NotEq })) |op| {
        const right = try parse_comparation(self);
        const node = ExprNode.create_binary(self.allocator, op, left, right);
        const end = self.prevous();
        left = Expr.create(self.allocator, start, end, node);
    }

    return left;
}

fn parse_comparation(self: *Self) Result {
    const start = self.peek();
    var left = try parse_term(self);

    while (self.match(.{ TokenKind.Less, TokenKind.LessEq, TokenKind.Greater, TokenKind.GreaterEq })) |op| {
        const right = try parse_term(self);
        const node = ExprNode.create_binary(self.allocator, op, left, right);
        const end = self.prevous();
        left = Expr.create(self.allocator, start, end, node);
    }

    return left;
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
    var left = try parse_unary(self);

    while (self.match(TokenKind.Hat)) |op| {
        const right = try parse_unary(self);
        const node = ExprNode.create_binary(self.allocator, op, left, right);
        const end = self.prevous();
        left = Expr.create(self.allocator, start, end, node);
    }

    return left;
}

fn parse_unary(self: *Self) Result {
    if (self.match(.{ TokenKind.Not, TokenKind.Minus, TokenKind.Plus })) |op| {
        const start = self.prevous();
        const expr = try parse_grouping(self);
        const end = self.prevous();

        const node = ExprNode.create_unary(self.allocator, op, expr);
        const res = Expr.create(self.allocator, start, end, node);
        return res;
    }
    return parse_grouping(self);
}

fn parse_grouping(self: *Self) Result {
    if (self.match(TokenKind.OpenParen)) |_| {
        const start = self.prevous();
        const expr = try parse_expression(self);
        const end = try self.consume(.CloseParen, "Expected ')'.");
        const node = ExprNode.create_grouping(self.allocator, expr);
        return Expr.create(self.allocator, start, end, node);
    }

    return parse_primary(self);
}

fn parse_primary(self: *Self) Result {
    const start = self.peek();
    if (self.match(.{ TokenKind.StringLit, TokenKind.IntLit, TokenKind.FloatLit, TokenKind.Identifier, TokenKind.True, TokenKind.False })) |tok| {
        const node = ExprNode.create_primary(self.allocator, tok);
        const end = self.prevous();
        return Expr.create(self.allocator, start, end, node);
    }

    return root.ParserError.UnexpectedToken;
}
