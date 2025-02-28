const std = @import("std");
const root = @import("root").root;

const mem = std.mem;
const fmt = std.fmt;

const Token = root.Token;
const TokenKind = root.TokenKind;
const AST = root.AST;
const ContextIR = root.ContextIR;
const Chunk = root.Chunk;
const OpCode = root.OpCode;
const OpReg = root.OpReg;

pub const Compiler = struct {
    const Self = Compiler;

    allocator: mem.Allocator,
    ctx: *ContextIR,

    pub fn init(allocator: mem.Allocator, ctx: *ContextIR) Self {
        return .{
            .allocator = allocator,
            .ctx = ctx,
        };
    }

    pub fn compile(self: *Self) Chunk {
        var chunk = Chunk.init(self.allocator);

        self.set_up(&chunk);

        self.compile_instruction(&chunk, &self.ctx.program);
        var current = self.ctx.program.next;
        while (current) |inst| {
            self.compile_instruction(&chunk, inst);
            current = inst.next;
        }

        chunk.write_op_code(.OpHalt);

        return chunk;
    }

    fn compile_instruction(self: *Self, chunk: *Chunk, instruction: *const ContextIR.Instruction) void {
        switch (instruction.op) {
            .Add, .Sub, .Mul, .Div, .Pow => {
                if (instruction.operand1) |op| {
                    self.compile_constants(chunk, &op);
                }
                if (instruction.operand2) |op| {
                    self.compile_constants(chunk, &op);
                }
                chunk.write_op_code(instKind_to_opCode(instruction.op));
            },
            .Assign => {
                if (instruction.operand2) |op| {
                    self.compile_constants(chunk, &op);
                }
                chunk.write_op_code(.OpStore);
                const alignment = self.ctx.get_variable(instruction.operand1.?.Variable) orelse unreachable;
                chunk.write_long(alignment.alignment);
            },
            .Dbg => {
                if (instruction.operand1) |op| {
                    self.compile_constants(chunk, &op);
                }
                chunk.write_op_code(.OpDbg);
            },
        }
    }

    fn compile_constants(self: *Self, chunk: *Chunk, constant: *const ContextIR.Constant) void {
        switch (constant.*) {
            .Int => |value| {
                chunk.write_op_code(.OpPush);
                chunk.write_long(@as(u64, @bitCast(value)));
            },
            .Float => |value| {
                chunk.write_op_code(.OpPush);
                chunk.write_long(@as(u64, @bitCast(value)));
            },
            .Variable => |id| {
                const alignment = self.ctx.get_variable(id) orelse unreachable;
                chunk.write_op_code(.OpLoad);
                chunk.write_long(alignment.alignment);
            },
        }
    }

    fn set_up(self: *Self, chunk: *Chunk) void {
        const size = self.ctx.get_global_stack_size();
        chunk.write_op_code(.SetupStack);
        chunk.write_long(size);
    }

    fn instKind_to_opCode(kind: ContextIR.InstructionKind) OpCode {
        return switch (kind) {
            .Add => OpCode.OpAdd,
            .Sub => OpCode.OpSubtract,
            .Mul => OpCode.OpMultiply,
            .Div => OpCode.OpDivide,
            .Pow => OpCode.OpPower,
            else => unreachable,
        };
    }
};
