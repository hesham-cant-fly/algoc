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
const Primitive = root.Primitive;
const Type = root.Type;

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

    fn compile_constants(self: *Self, chunk: *Chunk, constant: *const ContextIR.Constant) void {
        switch (constant.*) {
            .Int => |value| {
                chunk.write_op_code(.OpPushLong);
                chunk.write_long(@as(u64, @bitCast(value)));
            },
            .Float => |value| {
                chunk.write_op_code(.OpPushLong);
                chunk.write_long(@as(u64, @bitCast(value)));
            },
            .Bool => |value| {
                chunk.write_op_code(.OpPushByte);
                chunk.write_bool(value);
            },
            .Variable => |id| {
                const variable = self.ctx.get_variable(id) orelse unreachable;
                switch (variable.tp) {
                    .Primitive => |prim| {
                        switch (prim) {
                            .Int, .Float => {
                                chunk.write_op_code(.OpLoadLong);
                            },
                            .Bool => {
                                chunk.write_op_code(.OpLoadByte);
                            },
                        }
                    },
                }
                chunk.write_long(variable.alignment);
            },
        }
    }

    fn set_up(self: *Self, chunk: *Chunk) void {
        const size = self.ctx.get_global_stack_size();
        chunk.write_op_code(.SetupStack);
        chunk.write_long(size);
    }

    fn cast_to(self: *Self, source_type: Type, target_type: Type, chunk: *Chunk) void {
        _ = self;
        switch (target_type) {
            Type.Primitive => |prim| {
                const source_prim = source_type.Primitive;
                switch (prim) {
                    Primitive.Int => {
                        if (source_prim == .Float) {
                            chunk.write_op_code(.FloatToInt);
                        }
                    },
                    Primitive.Float => {
                        if (source_prim == .Int) {
                            chunk.write_op_code(.IntToFloat);
                        }
                    },
                    else => unreachable,
                    //Primitive.Bool => chunk.write_op_code(.ToBool),
                }
            },
        }
    }

    fn instKind_to_opCodeF(kind: ContextIR.InstructionKind) OpCode {
        return switch (kind) {
            .Add => OpCode.OpAddF,
            .Sub => OpCode.OpSubtractF,
            .Mul => OpCode.OpMultiplyF,
            .Div => OpCode.OpDivideF,
            .Pow => OpCode.OpPowerF,
            else => unreachable,
        };
    }

    fn instKind_to_opCodeI(kind: ContextIR.InstructionKind) OpCode {
        return switch (kind) {
            .Add => OpCode.OpAddI,
            .Sub => OpCode.OpSubtractI,
            .Mul => OpCode.OpMultiplyI,
            .Div => OpCode.OpDivideI,
            .Pow => OpCode.OpPowerI,
            else => unreachable,
        };
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

                root.assert(instruction.result_type != null);
                root.assert(instruction.result_type.? == .Primitive);

                const prim = instruction.result_type.?.get_primitive().?;
                chunk.write_op_code(switch (prim) {
                    Primitive.Int => instKind_to_opCodeI(instruction.op),
                    Primitive.Float => instKind_to_opCodeF(instruction.op),
                    else => unreachable,
                });
            },
            .Assign => {
                root.assert(instruction.operand1 != null);
                root.assert(instruction.operand1.? == .Variable);
                root.assert(instruction.source_type != null);

                const source_type = instruction.source_type.?;

                const variable = self.ctx.get_variable(instruction.operand1.?.Variable) orelse unreachable;

                if (instruction.operand2) |op| {
                    self.compile_constants(chunk, &op);
                }
                if (!source_type.is(variable.tp)) {
                    self.cast_to(source_type, variable.tp, chunk);
                }
                switch (variable.tp) {
                    .Primitive => |prim| {
                        switch (prim) {
                            .Int, .Float => {
                                chunk.write_op_code(.OpStoreLong);
                            },
                            .Bool => {
                                chunk.write_op_code(.OpStoreByte);
                            },
                        }
                    },
                }
                chunk.write_long(variable.alignment);
            },
            .Dbg => {
                if (instruction.operand1) |op| {
                    self.compile_constants(chunk, &op);
                }
                root.assert(instruction.result_type != null);
                switch (instruction.result_type.?) {
                    .Primitive => |prim| {
                        switch (prim) {
                            Primitive.Int => chunk.write_op_code(.OpDbgI),
                            Primitive.Float => chunk.write_op_code(.OpDbgF),
                            Primitive.Bool => chunk.write_op_code(.OpDbgB),
                        }
                    },
                }
            },
        }
    }
};
