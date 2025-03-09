const std = @import("std");
const root = @import("root.zig");

const fmt = std.fmt;
const mem = std.mem;
const debug = std.debug;
const Token = root.Token;
const Vm = root.Vm;
const OpCode = root.OpCode;
const Value = root.Value;
const ArrayList = std.ArrayList;

const indent_buf = "                                                                                                                                                                                                                                                                       ";

pub const Block = std.ArrayListUnmanaged(*Stmt);

pub fn free_block(block: *Block, allocator: mem.Allocator) void {
    for (block.items) |stmt| {
        stmt.free(allocator);
    }
    block.deinit(allocator);
}

pub fn dbg_block(block: *Block, ind: usize) void {
    const indent = get_indent(ind);
    debug.print("{s}Block:\n", .{indent});
    for (block.items, 0..) |stmt, i| {
        debug.print("{s}  {d}:\n", .{ indent, i });
        stmt.dbg(ind + 4);
    }
}

pub const Program = struct {
    const Self = Program;

    allocator: mem.Allocator,
    algorithme_id: *const Token = undefined,
    // constants: ??,
    // types: ??,
    variables: ArrayList(VarDec),
    // functions: ??,
    program: Block,

    pub fn init(allocator: mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .variables = ArrayList(VarDec).init(allocator),
            .program = Block.initCapacity(allocator, 0) catch @panic("Out Of Memory."),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.variables.items) |item| {
            item.deinit();
        }
        for (self.program.items) |item| {
            item.free(self.allocator);
        }
        self.variables.deinit();
        self.program.deinit(self.allocator);
    }

    pub fn set_algo_id(self: *Self, id: *const Token) void {
        self.algorithme_id = id;
    }

    pub fn dbg(self: *const Self) void {
        debug.print("Algorithm: {s}\n", .{self.algorithme_id.lexem});

        // TODO: Implement dbg for other fields

        debug.print("\n", .{});
        for (self.variables.items) |item| {
            item.dbg();
        }
        debug.print("\n", .{});

        debug.print("Begin Program:\n", .{});
        for (self.program.items) |stmt| {
            stmt.dbg(0);
        }
        debug.print("End Program.\n", .{});
    }
};

pub const VarDec = struct {
    const Self = VarDec;
    pub const Dec = struct {
        idents: ArrayList(*const Token),
        tp: *Type,

        pub fn init(allocator: mem.Allocator) Dec {
            return .{
                .idents = ArrayList(*const Token).init(allocator),
                .tp = undefined,
            };
        }

        pub fn deinit(self: *const Dec, allocator: mem.Allocator) void {
            self.idents.deinit();
            self.tp.free(allocator);
        }

        pub fn dbg(self: *const Dec) void {
            debug.print("  ids: ", .{});
            for (self.idents.items, 0..self.idents.items.len) |item, index| {
                if (index == self.idents.items.len - 1) {
                    debug.print("`{s}`\n", .{item.lexem});
                } else {
                    debug.print("`{s}`, ", .{item.lexem});
                }
            }
            self.tp.dbg(4);
        }
    };

    allocator: mem.Allocator,
    declarations: std.ArrayList(Dec),

    pub fn init(allocator: mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .declarations = ArrayList(Dec).init(allocator),
        };
    }

    pub fn deinit(self: *const Self) void {
        for (self.declarations.items) |item| {
            item.deinit(self.allocator);
        }
        self.declarations.deinit();
    }

    pub fn dbg(self: *const Self) void {
        debug.print("Variable:\n", .{});
        for (self.declarations.items) |item| {
            // debug.print("  ", .{});
            item.dbg();
        }
    }
};

pub const Stmt = struct {
    const Self = Stmt;

    start: *const Token,
    end: *const Token,
    node: *StmtNode,

    pub fn init(start: *const Token, end: *const Token, node: *StmtNode) Self {
        return .{ .start = start, .end = end, .node = node };
    }

    pub fn create(allocator: mem.Allocator, start: *const Token, end: *const Token, node: *StmtNode) *Self {
        const stmt = allocator.create(Self) catch @panic("Ouf Of Memory.");
        stmt.start = start;
        stmt.end = end;
        stmt.node = node;
        return stmt;
    }

    pub fn free(self: *const Self, allocator: mem.Allocator) void {
        self.node.free(allocator);
        allocator.destroy(self);
    }

    pub fn dbg(self: *const Self, ind: usize) void {
        debug.print("{s}Stmt (start: '{s}', end: '{s}'):\n", .{ get_indent(ind), self.start.lexem, self.end.lexem });
        self.node.dbg(ind + 2);
    }
};

pub const StmtNode = union(enum) {
    const Self = StmtNode;

    Expr: *Expr,
    Dbg: *Expr,
    If: IfStmtNode,

    pub fn create(allocator: mem.Allocator) *Self {
        return allocator.create(Self) catch @panic("Ouf Of Memory.");
    }

    pub fn create_expr(allocator: mem.Allocator, expr: *Expr) *Self {
        const node = create(allocator);
        node.* = StmtNode{ .Expr = expr };
        return node;
    }

    pub fn create_dbg(allocator: mem.Allocator, expr: *Expr) *Self {
        const node = create(allocator);
        node.* = StmtNode{ .Dbg = expr };
        return node;
    }

    pub fn create_if(allocator: mem.Allocator, condition: *Expr, then: Block, else_if: ?ElseIfNode, _else: ?Block) *Self {
        const node = create(allocator);
        node.* = StmtNode{
            .If = .{
                .condition = condition,
                .then = then,
                .else_if = else_if,
                ._else = _else,
            },
        };
        return node;
    }

    pub fn free(self: *Self, allocator: mem.Allocator) void {
        switch (self.*) {
            .Expr => |expr| expr.free(allocator),
            .Dbg => |expr| expr.free(allocator),
            .If => |*node| {
                node.condition.free(allocator);
                for (node.then.items) |stmt| {
                    stmt.free(allocator);
                }
                if (node.else_if) |*else_if| {
                    var current: ?*ElseIfNode = else_if;
                    while (current) |else_if_node| {
                        current = else_if_node.next;
                        else_if_node.condition.free(allocator);
                        free_block(&else_if_node.body, allocator);
                        allocator.destroy(else_if_node);
                    }
                }
                if (node._else) |*else_node| {
                    free_block(else_node, allocator);
                }
            },
        }
        allocator.destroy(self);
    }

    pub fn dbg(self: *Self, ind: usize) void {
        const indent = get_indent(ind);
        switch (self.*) {
            .Expr => |expr| {
                expr.dbg(ind + 2);
            },
            .Dbg => |expr| {
                debug.print("{s}dbg:\n", .{indent});
                expr.dbg(ind + 2);
            },
            .If => |*node| {
                debug.print("{s}If:\n", .{indent});
                debug.print("{s}  condition:\n", .{indent});
                node.condition.dbg(ind + 2);

                debug.print("{s}  then:\n", .{indent});
                dbg_block(&node.then, ind + 4);

                if (node.else_if) |*else_if| {
                    else_if.dbg(ind + 2);
                }
                if (node._else) |*_else| {
                    debug.print("{s}  else:\n", .{indent});
                    dbg_block(_else, ind + 2);
                }
            },
        }
    }
};

pub const ElseIfNode = struct {
    condition: *Expr,
    body: Block,
    next: ?*ElseIfNode = null,

    pub fn dbg(self: *ElseIfNode, ind: usize) void {
        const indent = get_indent(ind);
        var current: ?*ElseIfNode = self;
        var i: usize = 0;
        while (current) |node| : (i += 1) {
            const next = node.next;
            debug.print("{s}else_if({d}):\n", .{ indent, i });
            dbg_block(&node.body, ind + 2);
            current = next;
        }
    }
};

pub const IfStmtNode = struct {
    condition: *Expr,
    then: Block,
    else_if: ?ElseIfNode,
    _else: ?Block,
};

pub const Type = struct {
    const Self = Type;

    start: *const Token,
    end: *const Token,
    node: *TypeNode,

    pub fn create(allocator: mem.Allocator, start: *const Token, end: *const Token, node: *TypeNode) *Self {
        const result = allocator.create(Type) catch @panic("Out Of Memory.");
        result.start = start;
        result.end = end;
        result.node = node;
        return result;
    }

    pub fn free(self: *const Self, allocator: mem.Allocator) void {
        self.node.free(allocator);
        allocator.destroy(self);
    }

    pub fn dbg(self: *const Self, ind: usize) void {
        debug.print("{s}Type (start: '{s}', end: '{s}'):\n", .{ get_indent(ind), self.start.lexem, self.end.lexem });
        self.node.dbg(ind + 2);
    }
};

pub const TypeNode = union(enum) {
    const Self = TypeNode;

    Int,
    Float,
    Bool,
    Id: *const Token,

    pub fn create(allocator: mem.Allocator) *Self {
        return allocator.create(TypeNode) catch @panic("Out Of Memory.");
    }

    pub fn create_int(allocator: mem.Allocator) *Self {
        const node = create(allocator);
        node.* = .Int;
        return node;
    }

    pub fn create_float(allocator: mem.Allocator) *Self {
        const node = create(allocator);
        node.* = .Float;
        return node;
    }

    pub fn create_bool(allocator: mem.Allocator) *Self {
        const node = create(allocator);
        node.* = .Bool;
        return node;
    }

    pub fn create_id(allocator: mem.Allocator, id: *const Token) *Self {
        const node = create(allocator);
        node.* = .{ .Id = id };
        return node;
    }

    pub fn free(self: *Self, allocator: mem.Allocator) void {
        allocator.destroy(self);
    }

    pub fn dbg(self: *Self, ind: usize) void {
        const indent = get_indent(ind);
        switch (self.*) {
            .Int => debug.print("{s}Int\n", .{indent}),
            .Float => debug.print("{s}Float\n", .{indent}),
            .Bool => debug.print("{s}Bool\n", .{indent}),
            .Id => |id| debug.print("{s}Id: '{s}'\n", .{ indent, id.lexem }),
        }
    }
};

pub const Expr = struct {
    const Self = Expr;

    start: *const Token,
    end: *const Token,
    node: *ExprNode,

    pub fn create(allocator: mem.Allocator, start: *const Token, end: *const Token, node: *ExprNode) *Expr {
        const result = allocator.create(Expr) catch @panic("Out Of Memory");
        result.start = start;
        result.end = end;
        result.node = node;
        return result;
    }

    pub fn dbg(self: *const Self, indent: usize) void {
        std.debug.print("{s}Expr (start: '{s}', end: '{s}'):\n", .{ get_indent(indent), self.start.lexem, self.end.lexem });
        dbgExprNode(self.node, indent + 2);
    }

    pub fn free(self: *const Self, allocator: mem.Allocator) void {
        self.node.free(allocator);
        allocator.destroy(self);
    }
};

pub const ExprNodeAssign = struct {
    lhs: *const Token,
    op: *const Token,
    rhs: *Expr,
};

pub const ExprNodeBinary = struct {
    lhs: *Expr,
    op: *const Token,
    rhs: *Expr,
};

pub const ExprNode = union(enum) {
    const Self = ExprNode;

    Primary: *const Token,
    Grouping: *Expr,
    Binary: ExprNodeBinary,
    Assign: ExprNodeAssign,
    Unary: struct {
        op: *const Token,
        rhs: *Expr,
    },

    pub fn create(allocator: mem.Allocator) *ExprNode {
        return allocator.create(ExprNode) catch @panic("Out Of Memory");
    }

    pub fn create_primary(allocator: mem.Allocator, lit: *const Token) *ExprNode {
        const node = create(allocator);
        node.* = ExprNode{ .Primary = lit };
        return node;
    }

    pub fn create_binary(allocator: mem.Allocator, op: *const Token, lhs: *Expr, rhs: *Expr) *ExprNode {
        const node = create(allocator);
        node.* = ExprNode{ .Binary = .{ .op = op, .lhs = lhs, .rhs = rhs } };
        return node;
    }

    pub fn create_unary(allocator: mem.Allocator, op: *const Token, rhs: *Expr) *ExprNode {
        const node = create(allocator);
        node.* = ExprNode{ .Unary = .{ .op = op, .rhs = rhs } };
        return node;
    }

    pub fn create_grouping(allocator: mem.Allocator, expr: *Expr) *ExprNode {
        const node = create(allocator);
        node.* = .{ .Grouping = expr };
        return node;
    }

    pub fn create_assign(allocator: mem.Allocator, op: *const Token, lhs: *const Token, rhs: *Expr) *Self {
        const node = create(allocator);
        node.* = Self{ .Assign = .{ .lhs = lhs, .op = op, .rhs = rhs } };
        return node;
    }

    fn dbg(self: *const Self, indent: usize) void {
        const indent_str = get_indent(indent); // Create indentation string
        switch (self.*) {
            .Primary => |lit| {
                std.debug.print("{s}Literal: '{s}'\n", .{ indent_str, lit.lexem });
            },
            .Grouping => |expr| {
                std.debug.print("{s}Grouping:\n", .{indent_str});
                expr.dbg(indent + 2);
            },
            .Binary => |bin| {
                std.debug.print("{s}Binary:\n", .{indent_str});
                std.debug.print("{s}  op: '{s}'\n", .{ indent_str, bin.op.lexem });
                std.debug.print("{s}  lhs:\n", .{indent_str});
                bin.lhs.dbg(indent + 2);
                std.debug.print("{s}  rhs:\n", .{indent_str});
                bin.rhs.dbg(indent + 2);
            },
            .Unary => |un| {
                std.debug.print("{s}Unary:\n", .{indent_str});
                std.debug.print("{s}  op: '{s}'\n", .{ indent_str, un.op.lexem });
                std.debug.print("{s}  rhs:\n", .{indent_str});
                un.rhs.dbg(indent + 2);
            },
            .Assign => |node| {
                std.debug.print("{s}Assign:\n", .{indent_str});
                std.debug.print("{s}  op: '{s}'\n", .{ indent_str, node.op.lexem });
                std.debug.print("{s}  lhs:\n{0s}  ", .{indent_str});
                node.lhs.dbg();
                std.debug.print("{s}  rhs:\n", .{indent_str});
                node.rhs.dbg(indent + 2);
            },
        }
    }

    pub fn free(self: *const Self, allocator: mem.Allocator) void {
        switch (self.*) {
            .Grouping => |expr| expr.free(allocator),
            .Binary => |node| {
                node.lhs.free(allocator);
                node.rhs.free(allocator);
            },
            .Unary => |node| {
                node.rhs.free(allocator);
            },
            .Assign => |node| {
                node.rhs.free(allocator);
            },
            else => {},
        }
        allocator.destroy(self);
    }
};

fn dbgExprNode(node: *const ExprNode, indent: usize) void {
    node.dbg(indent);
}

fn get_indent(len: usize) []const u8 {
    return indent_buf[0..len];
}
