const std = @import("std");
const root = @import("root").root;

const Type = root.Type;
const Token = root.Token;
const AST = root.AST;

const mem = std.mem;
const debug = std.debug;
const StringHashMap = std.StringHashMap;

pub const VarSymbol = struct {
    const Self = VarSymbol;

    identifier: *const Token,
    tp: Type,

    pub fn get_size(self: *Self) usize {
        return self.tp.get_size();
    }

    pub fn dbg(self: *Self) void {
        debug.print("  id: {s}, tp: ", .{self.identifier.lexem});
        self.tp.dbg();
    }
};

pub const ExprTypeInfo = Type;

pub const Context = struct {
    const Self = Context;
    const Error = error{SymbolAlreadyExists};

    algorithm: []const u8 = "",
    variables: StringHashMap(VarSymbol),

    pub fn init(allocator: mem.Allocator) Self {
        return .{
            .variables = StringHashMap(VarSymbol).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.variables.deinit();
    }

    pub fn dbg(self: *Self) void {
        debug.print("Algorithm id: {s}\n", .{self.algorithm});
        debug.print("vars (allocated: {d} bytes):\n", .{self.get_global_stack_size()});
        var vars_iter = self.variables.iterator();
        while (vars_iter.next()) |entry| {
            entry.value_ptr.dbg();
            debug.print("\n", .{});
        }
    }

    pub fn add_variable(self: *Self, token: *const Token, tp: Type) Error!void {
        if (self.variables.contains(token.lexem)) {
            return Error.SymbolAlreadyExists;
        }
        self.variables.put(token.lexem, VarSymbol{ .identifier = token, .tp = tp }) catch @panic("Ouf Of Memory.");
    }

    pub fn get_variable(self: *Self, id: []const u8) ?VarSymbol {
        return self.variables.get(id);
    }

    pub fn get_global_stack_size(self: *Self) usize {
        var size: usize = 0;
        var var_iter = self.variables.iterator();

        while (var_iter.next()) |entity| {
            size += entity.value_ptr.get_size();
        }

        return size;
    }
};

pub const Analyser = struct {
    const Self = Analyser;
    const Error = error{
        VariableAlreadyDeclared,
        UndeclaredVariable,
        MismatchType,
    };

    ctx: Context,
    program: *AST.Program = undefined,

    pub fn init(allocator: mem.Allocator) Self {
        return .{
            .ctx = Context.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.ctx.deinit();
    }

    pub fn dbg(self: *Self) void {
        self.ctx.dbg();
    }

    pub fn analyse(self: *Self, program: *AST.Program) Error!void {
        self.program = program;

        self.ctx.algorithm = self.program.algorithme_id.lexem;

        for (self.program.variables.items) |node| {
            try self.analyse_variable_declaration(&node);
        }

        try self.analyse_program_main_block(self.program.program.items);
    }

    fn analyse_variable_declaration(self: *Self, node: *const AST.VarDec) Error!void {
        for (node.declarations.items) |dec| {
            const tp = to_type(dec.tp);
            for (dec.idents.items) |id| {
                self.ctx.add_variable(id, tp) catch return Error.VariableAlreadyDeclared;
            }
        }
    }

    fn analyse_program_main_block(self: *Self, nodes: []*AST.Stmt) Error!void {
        for (nodes) |node| {
            switch (node.node.*) {
                .Expr => |expr| _ = try self.analyse_expression(expr),
            }
        }
    }

    fn analyse_expression(self: *Self, expr: *AST.Expr) Error!ExprTypeInfo {
        return self.analyse_expression_node(expr.node);
    }

    fn analyse_expression_node(self: *Self, expr: *AST.ExprNode) Error!ExprTypeInfo {
        return switch (expr.*) {
            .Primary => |node| self.analyse_primary(node),
            .Grouping => |node| self.analyse_expression(node),
            .Assign => |*node| self.analyse_assignment(node),
            .Binary => |*node| self.analyse_binary_expression(node),
            else => unreachable,
        };
    }

    fn analyse_primary(self: *Self, tok: *const Token) Error!ExprTypeInfo {
        return switch (tok.kind) {
            .IntLit => Type{ .Primitive = .Int },
            .FloatLit => Type{ .Primitive = .Float },
            .Identifier => res: {
                if (self.ctx.get_variable(tok.lexem)) |symbol| {
                    break :res symbol.tp;
                } else {
                    return Error.UndeclaredVariable;
                }
            },
            else => unreachable,
        };
    }

    fn analyse_assignment(self: *Self, node: *AST.ExprNodeAssign) Error!ExprTypeInfo {
        const symbol = self.ctx.get_variable(node.lhs.lexem) orelse return Error.UndeclaredVariable;
        const rhs_tp = try self.analyse_expression(node.rhs);
        const can_assign = symbol.tp.can_assign(&rhs_tp);
        if (!can_assign) {
            return Error.MismatchType;
        }
        return symbol.tp;
    }

    fn analyse_binary_expression(self: *Self, node: *AST.ExprNodeBinary) Error!ExprTypeInfo {
        // TODO:
        _ = self;
        _ = node;
        unreachable;
    }
};

fn to_type(type_node: *const AST.Type) Type {
    return switch (type_node.node.*) {
        .Int => Type{ .Primitive = .Int },
        .Float => Type{ .Primitive = .Float },
        else => @panic("Unimplemented."),
    };
}
