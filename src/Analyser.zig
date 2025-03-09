const std = @import("std");
const root = @import("root").root;

const Type = root.Type;
const TokenKind = root.TokenKind;
const Primitive = root.Primitive;
const Token = root.Token;
const AST = root.AST;
const OpReg = root.OpReg;

const fmt = std.fmt;
const mem = std.mem;
const debug = std.debug;
const StringHashMap = std.StringHashMap;

pub const VarSymbol = struct {
    const Self = VarSymbol;

    alignment: usize = 0,
    identifier: *const Token,
    tp: Type,

    pub fn get_size(self: *const Self) usize {
        return self.tp.get_size();
    }

    pub fn dbg(self: *Self) void {
        debug.print("  id: {s}, tp: ", .{self.identifier.lexem});
        self.tp.dbg();
    }
};

pub const ExprTypeInfo = struct {
    tp: Type,
    symbol: ?VarSymbol = null,
    constant: ?ContextIR.Constant = null,
};

pub const ContextIR = struct {
    const Self = ContextIR;
    const Error = error{SymbolAlreadyExists};

    pub const InstructionKind = enum {
        Add, // +
        Sub, // -
        Mul, // *
        Div, // /
        Pow, // ^
        Assign,
        Dbg,

        pub fn from_token_kind(kind: root.TokenKind) InstructionKind {
            return switch (kind) {
                .Plus => InstructionKind.Add,
                .Minus => InstructionKind.Sub,
                .Star => InstructionKind.Mul,
                .FSlash => InstructionKind.Div,
                .Hat => InstructionKind.Pow,
                else => unreachable,
            };
        }
    };

    pub const Constant = union(enum) {
        Int: i64,
        Float: f64,
        Bool: bool,
        Variable: []const u8,
    };

    pub const Instruction = struct {
        op: InstructionKind = undefined,
        operand1: ?Constant = null,
        operand2: ?Constant = null,
        next: ?*Instruction = null,
        source_type: ?Type = null,
        result_type: ?Type = null,

        pub fn create(allocator: mem.Allocator) *Instruction {
            const result = allocator.create(Instruction) catch @panic("Out Of Memory.");
            result.* = Instruction{};
            return result;
        }

        pub fn deinit(self: *Instruction, allocator: mem.Allocator) void {
            var current: ?*Instruction = self.next;
            while (current) |node| {
                const next = node.next; // Capture next before destruction
                allocator.destroy(node);
                current = next;
            }
        }
    };

    algorithm: []const u8 = "",
    allocator: mem.Allocator,
    variables: StringHashMap(VarSymbol),
    last_index: usize = 0,
    program: Instruction = undefined,
    last_instruction: ?*Instruction = null,

    pub fn init(allocator: mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .variables = StringHashMap(VarSymbol).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.variables.deinit();
        self.program.deinit(self.allocator);
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
        const symbol = VarSymbol{ .identifier = token, .tp = tp, .alignment = self.last_index };
        self.last_index += symbol.get_size();
        self.variables.put(
            token.lexem,
            symbol,
        ) catch @panic("Ouf Of Memory.");
    }

    pub fn get_variable(self: *const Self, id: []const u8) ?VarSymbol {
        return self.variables.get(id);
    }

    pub fn get_global_stack_size(self: *const Self) usize {
        var size: usize = 0;
        var var_iter = self.variables.iterator();

        while (var_iter.next()) |entity| {
            size += entity.value_ptr.get_size();
        }

        return size;
    }

    pub fn add_instruction(self: *Self, instruction: *Instruction) void {
        if (self.last_instruction == null) {
            self.program = instruction.*;
            self.last_instruction = &self.program;
            self.allocator.destroy(instruction);
            return;
        }
        self.last_instruction.?.next = instruction;
        self.last_instruction = self.last_instruction.?.next;
        self.last_instruction.?.next = null;
    }
};

pub const Analyser = struct {
    const Self = Analyser;
    const Error = error{
        VariableAlreadyDeclared,
        UndeclaredVariable,
        MismatchType,
    };

    ctx: ContextIR,
    program: *AST.Program = undefined,

    pub fn init(allocator: mem.Allocator) Self {
        return .{
            .ctx = ContextIR.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.ctx.deinit();
    }

    pub fn dbg(self: *Self) void {
        self.ctx.dbg();
    }

    pub fn analyse(self: *Self, program: *AST.Program) Error!ContextIR {
        self.program = program;

        self.ctx.algorithm = self.program.algorithme_id.lexem;

        for (self.program.variables.items) |node| {
            try self.analyse_variable_declaration(&node);
        }

        try self.analyse_program_main_block(self.program.program.items);

        return self.ctx;
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
                .Dbg => |expr| try self.analyse_dbg(expr),
                .If => {
                    @panic("Unimplemented");
                },
            }
        }
    }

    fn analyse_dbg(self: *Self, expr: *AST.Expr) Error!void {
        const tp = try self.analyse_expression(expr);

        const instruction = ContextIR.Instruction.create(self.ctx.allocator);
        instruction.op = .Dbg;
        instruction.operand1 = tp.constant;
        instruction.result_type = tp.tp;
        self.ctx.add_instruction(instruction);
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
        const result: ExprTypeInfo = switch (tok.kind) {
            .IntLit => ExprTypeInfo{
                .tp = Type{ .Primitive = .Int },
                .constant = ContextIR.Constant{
                    .Int = fmt.parseInt(i64, tok.lexem, 10) catch @panic("Fix your thing."),
                },
            },
            .FloatLit => ExprTypeInfo{
                .tp = Type{ .Primitive = .Float },
                .constant = ContextIR.Constant{
                    .Float = fmt.parseFloat(f64, tok.lexem) catch @panic("Fix your thing."),
                },
            },
            .True => ExprTypeInfo{
                .tp = Type{ .Primitive = .Bool },
                .constant = ContextIR.Constant{
                    .Bool = true,
                },
            },
            .False => ExprTypeInfo{
                .tp = Type{ .Primitive = .Bool },
                .constant = ContextIR.Constant{
                    .Bool = false,
                },
            },
            .Identifier => res: {
                if (self.ctx.get_variable(tok.lexem)) |symbol| {
                    break :res ExprTypeInfo{
                        .tp = symbol.tp,
                        .symbol = symbol,
                        .constant = ContextIR.Constant{
                            .Variable = tok.lexem,
                        },
                    };
                } else {
                    return Error.UndeclaredVariable;
                }
            },
            else => unreachable,
        };
        return result;
    }

    fn analyse_assignment(self: *Self, node: *AST.ExprNodeAssign) Error!ExprTypeInfo {
        const symbol = self.ctx.get_variable(node.lhs.lexem) orelse return Error.UndeclaredVariable;
        const rhs_tp = try self.analyse_expression(node.rhs);
        const can_assign = symbol.tp.can_assign(&rhs_tp.tp);
        if (!can_assign) {
            return Error.MismatchType;
        }

        const instruction = ContextIR.Instruction.create(self.ctx.allocator);
        instruction.op = .Assign;
        instruction.operand1 = .{ .Variable = symbol.identifier.lexem };
        instruction.operand2 = rhs_tp.constant;
        instruction.source_type = rhs_tp.tp;
        instruction.result_type = symbol.tp;
        self.ctx.add_instruction(instruction);

        return rhs_tp;
    }

    fn analyse_binary_expression(self: *Self, node: *AST.ExprNodeBinary) Error!ExprTypeInfo {
        // TODO: Do a better analysing
        const lhs = try self.analyse_expression(node.lhs);
        const rhs = try self.analyse_expression(node.rhs);

        const res_tp = lhs.tp.binary(&rhs.tp, node.op) orelse @panic("something bad happened");

        const instruction = ContextIR.Instruction.create(self.ctx.allocator);
        instruction.op = ContextIR.InstructionKind.from_token_kind(node.op.kind);
        instruction.operand1 = lhs.constant;
        instruction.operand2 = rhs.constant;
        instruction.result_type = res_tp;
        self.ctx.add_instruction(instruction);

        return ExprTypeInfo{
            .constant = null,
            .symbol = null,
            .tp = res_tp,
        };
    }
};

fn to_type(type_node: *const AST.Type) Type {
    return switch (type_node.node.*) {
        .Int => Type{ .Primitive = .Int },
        .Float => Type{ .Primitive = .Float },
        .Bool => Type{ .Primitive = .Bool },
        else => @panic("Unimplemented."),
    };
}
