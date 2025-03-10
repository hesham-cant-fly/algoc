const std = @import("std");
const root = @import("root").root;

const Token = root.Token;
const TokenKind = root.TokenKind;

const debug = std.debug;

pub const Primitive = enum(u8) {
    const Self = Primitive;

    Int,
    Float,
    Bool,

    pub fn get_size(self: Self) usize {
        return switch (self) {
            .Int => 8,
            .Float => 8,
            .Bool => 1,
        };
    }

    pub fn can_assign(self: Self, other: *const Type) bool {
        if (other.* != .Primitive) {
            return false;
        }
        const other_primitive = other.Primitive;
        return switch (self) {
            .Int, .Float => other_primitive == .Int or other_primitive == .Float,
            .Bool => other_primitive == .Bool,
        };
    }

    pub fn is(self: Self, other: Self) bool {
        return self == other;
    }

    pub fn is_number(self: Self) bool {
        return self == .Int or self == .Float;
    }

    pub fn dbg(self: Self) void {
        switch (self) {
            .Int => debug.print("Int", .{}),
            .Float => debug.print("Float", .{}),
        }
    }

    pub fn binary(self: *const Self, other: *const Self, op: *const Token) ?Primitive {
        switch (op.kind) {
            TokenKind.Plus, TokenKind.Minus, TokenKind.Star, TokenKind.FSlash, TokenKind.Hat => {
                if (self.* == .Int and other.* == .Int) return .Int;

                if ((self.* == .Float or other.* == .Int) and (self.* == .Int or other.* == .Float))
                    return Primitive.Float;

                return null;
            },
            TokenKind.Or, TokenKind.And => {
                if (self.* == .Bool and other.* == .Bool) return Primitive.Bool;
                return null;
            },
            TokenKind.Eq, TokenKind.NotEq => {
                if (self.is_number() and other.is_number())
                    return Primitive.Bool;
                if (self.* == .Bool and other.* == .Bool)
                    return Primitive.Bool;

                return null;
            },
            TokenKind.Less, TokenKind.Greater, TokenKind.LessEq, TokenKind.GreaterEq => {
                return Primitive.Bool;
            },
            else => unreachable,
        }
    }

    pub fn unary(self: Self, op: *const Token) ?Primitive {
        switch (op.kind) {
            TokenKind.Plus, TokenKind.Minus => {
                if (self.is_number()) return self;
                return null;
            },
            TokenKind.Not => {
                if (self == .Bool) return self;
                return null;
            },
            else => unreachable,
        }
    }
};

pub const Type = union(enum) {
    const Self = Type;

    Primitive: Primitive,

    pub fn get_size(self: *const Self) usize {
        return switch (self.*) {
            .Primitive => |tp| tp.get_size(),
        };
    }

    pub fn dbg(self: *const Self) void {
        switch (self.*) {
            .Primitive => |tp| tp.dbg(),
        }
    }

    pub fn can_assign(self: *const Self, other: *const Self) bool {
        return switch (self.*) {
            .Primitive => |tp| tp.can_assign(other),
        };
    }

    pub fn get_primitive(self: *const Self) ?Primitive {
        return switch (self.*) {
            .Primitive => |pri| pri,
        };
    }

    pub fn is_bool(self: *const Self) bool {
        return self.* == .Primitive and self.Primitive == .Bool;
    }

    pub fn binary(self: *const Self, other: *const Type, op: *const Token) ?Type {
        switch (self.*) {
            .Primitive => |self_pri| {
                const other_pri = other.get_primitive() orelse return null;
                const res_prim = self_pri.binary(&other_pri, op) orelse return null;
                return Type{ .Primitive = res_prim };
            },
        }
    }

    pub fn unary(self: *const Self, op: *const Token) ?Type {
        switch (self.*) {
            .Primitive => |self_pri| {
                const res_prim = self_pri.unary(op) orelse return null;
                return Type{ .Primitive = res_prim };
            },
        }
    }

    pub fn is(self: Self, other: Self) bool {
        switch (self) {
            .Primitive => |prim| {
                if (other != .Primitive) return false;
                return other.Primitive.is(prim);
            },
        }
    }
};
