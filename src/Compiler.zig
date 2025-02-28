const std = @import("std");
const root = @import("root").root;

const mem = std.mem;
const fmt = std.fmt;

const Token = root.Token;
const TokenKind = root.TokenKind;
const AST = root.AST;
const Context = root.Context;
const Chunk = root.Chunk;
const OpCode = root.OpCode;
const OpReg = root.OpReg;

pub const Compiler = struct {
    const Self = Compiler;

    allocator: mem.Allocator,
    ctx: *const Context,
    program: *const AST.Program,

    pub fn init(allocator: mem.Allocator, ctx: *Context, program: *AST.Program) Self {
        return .{
            .allocator = allocator,
            .ctx = ctx,
            .program = program,
        };
    }

    pub fn compile(self: *Self) Chunk {
        var chunk = Chunk.init(self.allocator);

        self.set_up(&chunk);

        self.compile_program_block(self.program.program.items, &chunk);

        chunk.write_op_code(.OpHalt);

        return chunk;
    }

    fn compile_program_block(self: *Self, block: []*AST.Stmt, chunk: *Chunk) void {
        for (block) |stmt| {
            self.compile_statment(stmt, chunk);
        }
    }

    fn compile_statment(self: *Self, stmt: *AST.Stmt, chunk: *Chunk) void {
        switch (stmt.node.*) {
            .Expr => |expr| self.compile_expr(expr, chunk, .RegA),
            .Dbg => |expr| {
                self.compile_expr(expr, chunk, .RegA);
                chunk.write_op_code(.OpDbg);
            },
        }
    }

    fn compile_expr(self: *Self, expr: *AST.Expr, chunk: *Chunk, reg: OpReg) void {
        switch (expr.node.*) {
            .Grouping => |node| self.compile_expr(node, chunk, .RegA),
            .Primary => |tok| {
                switch (tok.kind) {
                    TokenKind.Identifier => {
                        const symbol = self.ctx.get_variable(tok.lexem) orelse unreachable;
                        chunk.write_op_code(.OpLoad);
                        chunk.write_long(symbol.index);
                    },
                    TokenKind.IntLit => {
                        const num = fmt.parseInt(i64, tok.lexem, 10) catch @panic("Solve your things");
                        chunk.write_op_code(.OpMov);
                        chunk.write_long(@as(u64, @bitCast(num)));
                    },
                    TokenKind.FloatLit => {
                        const num = fmt.parseFloat(f64, tok.lexem) catch @panic("Solve your things");
                        chunk.write_op_code(.OpMov);
                        chunk.write_long(@as(u64, @bitCast(num)));
                    },
                    else => unreachable,
                }
                chunk.write_op_reg(reg);
            },
            .Binary => |node| {
                self.compile_expr(node.lhs, chunk, .RegA);
                self.compile_expr(node.rhs, chunk, .RegB);
                chunk.write_op_code(token_to_opCode(node.op));
                chunk.write_op_reg(.RegA);
                chunk.write_op_reg(.RegB);
            },
            .Assign => |node| {
                const symbol = self.ctx.get_variable(node.lhs.lexem) orelse unreachable;
                self.compile_expr(node.rhs, chunk, .RegA);
                chunk.write_op_code(.OpSet);
                chunk.write_long(symbol.index);
                chunk.write_op_reg(.RegA);
            },
            else => unreachable,
        }
    }

    fn set_up(self: *Self, chunk: *Chunk) void {
        const size = self.ctx.get_global_stack_size();
        chunk.write_op_code(.SetupStack);
        chunk.write_long(size);
    }

    fn token_to_opCode(token: *const Token) OpCode {
        return switch (token.kind) {
            .Plus => OpCode.OpAdd,
            .Minus => OpCode.OpSubtract,
            .Star => OpCode.OpMultiply,
            .FSlash => OpCode.OpDivide,
            .Hat => OpCode.OpPower,
            else => unreachable,
        };
    }
};
