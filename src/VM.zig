const std = @import("std");
const ValueMod = @import("./value.zig");

const mem = std.mem;
const ArrayList = std.ArrayList;
const Value = ValueMod.Value;

const Op = enum(i8) {
    add,
    mul,
    div,
    sub,
    pow,
};

pub const OpCode = enum(u8) {
    OpSetF64,
    OpSetI64,
    OpSetChar,
    OpAdd,
    OpSubtract,
    OpMultiply,
    OpDivide,
    OpPower,
    OpReturn,
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
        self.constants.deinit();
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
        A: i64,
        B: i64,
        C: i64,
        D: i64,
    };

    allocator: mem.Allocator,
    chunk: *Chunk,
    regs: Regesters,
    ip: usize = 0,

    pub fn init(allocator: mem.Allocator) Self {
        const chunk = allocator.create(Chunk) catch @panic("Out Of Memory");
        chunk.* = Chunk.init(allocator);
        return .{
            .allocator = allocator,
            .chunk = chunk,
        };
    }

    pub fn deinit(self: *Self) void {
        self.ip = 0;
        self.chunk.deinit();
        self.allocator.destroy(self.chunk);
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

    fn dbg(self: *Self) void {
        _ = self;
        @panic("Unimplemented.");
    }

    pub fn run(self: *Self) Error!void {
        while (true) {
            if (self.ip >= self.chunk.code.items.len) return Error.OutOfBounds;

            self.dbg();

            const opcode = @as(OpCode, @enumFromInt(self.chunk.get_op_code(self.ip)));
            self.ip += 1;
            _ = opcode;
        }
    }
};
