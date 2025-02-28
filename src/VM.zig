const std = @import("std");
const root = @import("root").root;

const mem = std.mem;
const math = std.math;
const ArrayList = std.ArrayList;
const print = root.common.print;

const Op = enum(i8) {
    add,
    mul,
    div,
    sub,
    pow,
};

pub const OpCode = enum(u8) {
    SetupStack,

    OpMov,
    OpSet,
    OpLoad,

    OpAdd,
    OpSubtract,
    OpMultiply,
    OpDivide,
    OpPower,

    OpDbg,

    OpHalt,
};

pub const OpReg = enum(u8) { RegA, RegB, RegC, RegD };

pub const Chunk = struct {
    const Self = Chunk;

    code: ArrayList(u8),

    pub fn init(allocator: mem.Allocator) Self {
        return Self{
            .code = ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.code.deinit();
    }

    pub fn write_op_code(self: *Self, op: OpCode) void {
        self.code.append(@as(u8, @intFromEnum(op))) catch @panic("Ouf Of Memory.");
    }

    pub fn write_op_reg(self: *Self, reg: OpReg) void {
        self.code.append(@as(u8, @intFromEnum(reg))) catch @panic("Out Of Memory.");
    }

    pub fn write(self: *Self, byte: u8) void {
        self.code.append(byte) catch @panic("Out Of Memory.");
    }

    pub fn write_long(self: *Self, long: u64) void {
        self.code.append(@as(u8, @truncate(long))) catch @panic("Out Of Memory.");
        self.code.append(@as(u8, @truncate(long >> 8))) catch @panic("Out Of Memory.");
        self.code.append(@as(u8, @truncate(long >> 16))) catch @panic("Out Of Memory.");
        self.code.append(@as(u8, @truncate(long >> 24))) catch @panic("Out Of Memory.");
        self.code.append(@as(u8, @truncate(long >> 32))) catch @panic("Out Of Memory.");
        self.code.append(@as(u8, @truncate(long >> 40))) catch @panic("Out Of Memory.");
        self.code.append(@as(u8, @truncate(long >> 48))) catch @panic("Out Of Memory.");
        self.code.append(@as(u8, @truncate(long >> 56))) catch @panic("Out Of Memory.");
    }

    pub fn get_op_code(self: *Self, at: usize) u8 {
        return self.code.items[at];
    }
};

pub const VM = struct {
    const Self = VM;
    const MAX_STACK_SIZE = 100;
    const Error = error{ StackOverflow, StackUnderflow, OutOfBounds };

    const Regesters = struct {
        A: u64 = 0,
        B: u64 = 0,
        C: u64 = 0,
        D: u64 = 0,
    };

    allocator: mem.Allocator,
    chunk: *Chunk,
    stack: []u8 = undefined,
    regs: Regesters = .{},
    ip: usize = 0,

    pub fn init(allocator: mem.Allocator, chunk: *Chunk) Self {
        // const chunk = allocator.create(Chunk) catch @panic("Out Of Memory");
        // chunk.* = Chunk.init(allocator);
        return .{
            .allocator = allocator,
            .chunk = chunk,
        };
    }

    pub fn deinit(self: *Self) void {
        self.ip = 0;
        self.allocator.free(self.stack);
    }

    pub fn stack_get_u64(self: *Self, index: usize) u64 {
        const b1 = self.stack[index];
        const b2 = self.stack[index + 1];
        const b3 = self.stack[index + 2];
        const b4 = self.stack[index + 3];
        const b5 = self.stack[index + 4];
        const b6 = self.stack[index + 5];
        const b7 = self.stack[index + 6];
        const b8 = self.stack[index + 7];

        return (@as(u64, b8) << 56) |
            (@as(u64, b7) << 48) |
            (@as(u64, b6) << 40) |
            (@as(u64, b5) << 32) |
            (@as(u64, b4) << 24) |
            (@as(u64, b3) << 16) |
            (@as(u64, b2) << 8) |
            (@as(u64, b1));
    }

    pub fn stack_set_u64(self: *Self, index: usize, value: u64) void {
        self.stack[index] = @as(u8, @truncate(value));
        self.stack[index + 1] = @as(u8, @truncate(value >> 8));
        self.stack[index + 2] = @as(u8, @truncate(value >> 16));
        self.stack[index + 3] = @as(u8, @truncate(value >> 24));
        self.stack[index + 4] = @as(u8, @truncate(value >> 32));
        self.stack[index + 5] = @as(u8, @truncate(value >> 40));
        self.stack[index + 6] = @as(u8, @truncate(value >> 48));
        self.stack[index + 7] = @as(u8, @truncate(value >> 56));
    }

    pub fn read_reg(self: *Self) OpReg {
        const c = self.chunk.get_op_code(self.ip);
        self.ip += 1;
        return @as(OpReg, @enumFromInt(c));
    }

    pub fn read_long(self: *Self) u64 {
        const b1 = self.chunk.get_op_code(self.ip);
        self.ip += 1;
        const b2 = self.chunk.get_op_code(self.ip);
        self.ip += 1;
        const b3 = self.chunk.get_op_code(self.ip);
        self.ip += 1;
        const b4 = self.chunk.get_op_code(self.ip);
        self.ip += 1;
        const b5 = self.chunk.get_op_code(self.ip);
        self.ip += 1;
        const b6 = self.chunk.get_op_code(self.ip);
        self.ip += 1;
        const b7 = self.chunk.get_op_code(self.ip);
        self.ip += 1;
        const b8 = self.chunk.get_op_code(self.ip);
        self.ip += 1;

        return (@as(u64, b8) << 56) |
            (@as(u64, b7) << 48) |
            (@as(u64, b6) << 40) |
            (@as(u64, b5) << 32) |
            (@as(u64, b4) << 24) |
            (@as(u64, b3) << 16) |
            (@as(u64, b2) << 8) |
            (@as(u64, b1));
    }

    // fn dbg(self: *Self) void {
    // }

    pub fn run(self: *Self) Error!void {
        while (true) {
            if (self.ip >= self.chunk.code.items.len) return Error.OutOfBounds;

            // self.dbg();

            const opcode = @as(OpCode, @enumFromInt(self.chunk.get_op_code(self.ip)));
            self.ip += 1;
            switch (opcode) {
                OpCode.SetupStack => {
                    const size = self.read_long();
                    self.stack = self.allocator.alloc(u8, size) catch @panic("Out Of Memory.");
                },
                OpCode.OpMov => {
                    const value = self.read_long();
                    const reg = self.read_reg();
                    self.set_regester(reg, value);
                },
                OpCode.OpLoad => {
                    const at = self.read_long();
                    const reg = self.read_reg();

                    const val = self.stack_get_u64(at);

                    switch (reg) {
                        OpReg.RegA => self.regs.A = val,
                        OpReg.RegB => self.regs.B = val,
                        OpReg.RegC => self.regs.C = val,
                        OpReg.RegD => self.regs.D = val,
                    }
                },
                OpCode.OpSet => {
                    const at = self.read_long();
                    const reg = self.read_reg();
                    self.stack_set_u64(at, switch (reg) {
                        OpReg.RegA => self.regs.A,
                        OpReg.RegB => self.regs.B,
                        OpReg.RegC => self.regs.C,
                        OpReg.RegD => self.regs.D,
                    });
                },
                OpCode.OpAdd => self.do_binary(.add),
                OpCode.OpSubtract => self.do_binary(.sub),
                OpCode.OpMultiply => self.do_binary(.mul),
                OpCode.OpDivide => self.do_binary(.div),
                OpCode.OpPower => self.do_binary(.pow),

                OpCode.OpDbg => {
                    print("{d}\n", .{self.get_regester(.RegA)});
                },

                OpCode.OpHalt => {
                    return;
                },
            }
        }
    }

    fn do_binary(self: *Self, op: Op) void {
        const dist = self.read_reg();
        const rhs = self.read_reg();

        switch (op) {
            Op.add => self.set_regester(dist, self.get_regester(dist) + self.get_regester(rhs)),
            Op.sub => self.set_regester(dist, self.get_regester(dist) - self.get_regester(rhs)),
            Op.mul => self.set_regester(dist, self.get_regester(dist) * self.get_regester(rhs)),
            Op.div => self.set_regester(dist, self.get_regester(dist) / self.get_regester(rhs)),
            Op.pow => self.set_regester(dist, math.pow(u64, self.get_regester(dist), self.get_regester(rhs))),
        }
    }

    fn get_regester(self: *Self, reg: OpReg) u64 {
        return switch (reg) {
            OpReg.RegA => self.regs.A,
            OpReg.RegB => self.regs.B,
            OpReg.RegC => self.regs.C,
            OpReg.RegD => self.regs.D,
        };
    }

    fn set_regester(self: *Self, reg: OpReg, value: u64) void {
        switch (reg) {
            OpReg.RegA => self.regs.A = value,
            OpReg.RegB => self.regs.B = value,
            OpReg.RegC => self.regs.C = value,
            OpReg.RegD => self.regs.D = value,
        }
    }
};
