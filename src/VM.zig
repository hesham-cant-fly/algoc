const std = @import("std");
const root = @import("root").root;

const mem = std.mem;
const math = std.math;
const debug = std.debug;
const ArrayList = std.ArrayList;
const print = root.common.print;

pub const Op = enum(i8) {
    add,
    mul,
    div,
    sub,
    pow,
};

pub const OpCode = enum(u8) {
    SetupStack, // setup_stack <size>

    OpStoreLong, // store_long <alignment>
    OpLoadLong, // load_long <alignment>

    OpStoreByte, // store_byte <alignment>
    OpLoadByte, // load_byte <alignment>

    OpPushLong, // push_long <value>
    OpPopLong, // pop_long

    OpPushByte, // push_byte <value>
    OpPopByte, // pop_byte

    OpAddF, // addf
    OpSubtractF, // subf
    OpMultiplyF, // mulf
    OpDivideF, // divf
    OpPowerF, // powf

    OpAddI, // addi
    OpSubtractI, // subi
    OpMultiplyI, // muli
    OpDivideI, // divi
    OpPowerI, // powi

    OpNegateI, // negatei
    OpNegateF, // negatef
    OpNot, // not

    FloatToInt, // to_int
    IntToFloat, // to_float

    OpDbgF, // dbgf
    OpDbgI, // dbgi
    OpDbgB, // dbgb

    OpHalt, // halt
};

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

    pub fn write(self: *Self, byte: u8) void {
        self.code.append(byte) catch @panic("Out Of Memory.");
    }

    pub fn write_bool(self: *Self, b: bool) void {
        self.code.append(@as(u8, @intFromBool(b))) catch @panic("Out Of Memory.");
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

    pub fn get_long(self: *Self, at: usize) u64 {
        const b1 = self.code.items[at];
        const b2 = self.code.items[at + 1];
        const b3 = self.code.items[at + 2];
        const b4 = self.code.items[at + 3];
        const b5 = self.code.items[at + 4];
        const b6 = self.code.items[at + 5];
        const b7 = self.code.items[at + 6];
        const b8 = self.code.items[at + 7];

        return (@as(u64, b8) << 56) |
            (@as(u64, b7) << 48) |
            (@as(u64, b6) << 40) |
            (@as(u64, b5) << 32) |
            (@as(u64, b4) << 24) |
            (@as(u64, b3) << 16) |
            (@as(u64, b2) << 8) |
            (@as(u64, b1));
    }

    pub fn dbg(self: *Self) void {
        var i: usize = 0;
        while (i < self.code.items.len) : (i += 1) {
            const opcode = self.code.items[i];
            switch (@as(OpCode, @enumFromInt(opcode))) {
                .SetupStack => { // setup_stack <size>
                    debug.print("<setup_stack> {d} byte\n", .{
                        self.get_long(i + 1),
                    });
                    i += 8;
                },

                .OpStoreLong => {
                    debug.print("<store_long_at> {d}\n", .{
                        self.get_long(i + 1),
                    });
                    i += 8;
                },
                .OpLoadLong => { // load_long <alignment>
                    debug.print("<load_long_from> {d}\n", .{
                        self.get_long(i + 1),
                    });
                    i += 8;
                },
                .OpStoreByte => { // store_byte <alignment>
                    debug.print("<store_byte_at> {d}\n", .{
                        self.get_long(i + 1),
                    });
                    i += 8;
                },
                .OpLoadByte => { // load_byte <alignment>
                    debug.print("<load_byte_from> {d}\n", .{
                        self.get_long(i + 1),
                    });
                    i += 8;
                },

                .OpPushLong => { // push_long <u64>
                    debug.print("<push_long> {d}\n", .{
                        self.get_long(i + 1),
                    });
                    i += 8;
                },
                .OpPopLong => { // pop_long
                    debug.print("<pop_long>\n", .{});
                },
                .OpPushByte => { // push_byte <u8>
                    debug.print("<push_byte> {d}\n", .{
                        self.get_op_code(i + 1),
                    });
                    i += 1;
                },
                .OpPopByte => { // pop_byte
                    debug.print("<pop_byte>\n", .{});
                },

                .OpAddF => { // addf
                    debug.print("<addf>\n", .{});
                },
                .OpSubtractF => { // subf
                    debug.print("<subf>\n", .{});
                },
                .OpMultiplyF => { // mul
                    debug.print("<mulf>\n", .{});
                },
                .OpDivideF => { // div
                    debug.print("<divf>\n", .{});
                },
                .OpPowerF => { // pow
                    debug.print("<powf>\n", .{});
                },

                .OpAddI => { // addi
                    debug.print("<addi>\n", .{});
                },
                .OpSubtractI => { // subi
                    debug.print("<subi>\n", .{});
                },
                .OpMultiplyI => { // muli
                    debug.print("<muli>\n", .{});
                },
                .OpDivideI => { // divi
                    debug.print("<divi>\n", .{});
                },
                .OpPowerI => { // powi
                    debug.print("<powi>\n", .{});
                },

                .OpNegateF => { // negatef
                    debug.print("<negatef>\n", .{});
                },
                .OpNegateI => { // negatei
                    debug.print("<negatei>\n", .{});
                },
                .OpNot => { // not
                    debug.print("<not>\n", .{});
                },

                .IntToFloat => { // to_float
                    debug.print("<int_to_float>\n", .{});
                },
                .FloatToInt => { // to_int
                    debug.print("<flaot_to_int>\n", .{});
                },

                .OpDbgI => { // dbgi
                    debug.print("<dbgi>\n", .{});
                },
                .OpDbgF => { // dbgf
                    debug.print("<dbgf>\n", .{});
                },
                .OpDbgB => { // dbgb
                    debug.print("<dbgb>\n", .{});
                },

                .OpHalt => { // halt
                    debug.print("<halt>\n", .{});
                },
            }
        }
    }
};

pub const VM = struct {
    const Self = VM;
    const MAX_STACK_SIZE = 100;
    const Error = error{ StackOverflow, StackUnderflow, OutOfBounds };

    allocator: mem.Allocator,
    chunk: *Chunk,
    memory_layout: []u8 = undefined,
    stack: [255]u8 = undefined,
    ip: usize = 0,
    sp: usize = 0,

    pub fn init(allocator: mem.Allocator, chunk: *Chunk) Self {
        // const chunk = allocator.create(Chunk) catch @panic("Out Of Memory");
        // chunk.* = Chunk.init(allocator);
        var res = Self{
            .allocator = allocator,
            .chunk = chunk,
        };
        @memset(&res.stack, 0);
        return res;
    }

    pub fn deinit(self: *Self) void {
        self.ip = 0;
        self.sp = 0;
        self.allocator.free(self.memory_layout);
    }

    pub fn mem_get_u8(self: *Self, index: usize) u8 {
        return self.memory_layout[index];
    }

    pub fn mem_get_u64(self: *Self, index: usize) u64 {
        const b1 = self.memory_layout[index];
        const b2 = self.memory_layout[index + 1];
        const b3 = self.memory_layout[index + 2];
        const b4 = self.memory_layout[index + 3];
        const b5 = self.memory_layout[index + 4];
        const b6 = self.memory_layout[index + 5];
        const b7 = self.memory_layout[index + 6];
        const b8 = self.memory_layout[index + 7];

        return (@as(u64, b8) << 56) |
            (@as(u64, b7) << 48) |
            (@as(u64, b6) << 40) |
            (@as(u64, b5) << 32) |
            (@as(u64, b4) << 24) |
            (@as(u64, b3) << 16) |
            (@as(u64, b2) << 8) |
            (@as(u64, b1));
    }

    pub fn mem_set_u8(self: *Self, index: usize, value: u8) void {
        self.memory_layout[index] = value;
    }
    pub fn mem_set_u64(self: *Self, index: usize, value: u64) void {
        self.memory_layout[index] = @as(u8, @truncate(value));
        self.memory_layout[index + 1] = @as(u8, @truncate(value >> 8));
        self.memory_layout[index + 2] = @as(u8, @truncate(value >> 16));
        self.memory_layout[index + 3] = @as(u8, @truncate(value >> 24));
        self.memory_layout[index + 4] = @as(u8, @truncate(value >> 32));
        self.memory_layout[index + 5] = @as(u8, @truncate(value >> 40));
        self.memory_layout[index + 6] = @as(u8, @truncate(value >> 48));
        self.memory_layout[index + 7] = @as(u8, @truncate(value >> 56));
    }

    pub fn read_byte(self: *Self) u8 {
        self.ip += 1;
        return self.chunk.get_op_code(self.ip - 1);
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

    fn do_binaryi(self: *Self, op: Op) void {
        const b = @as(i64, @bitCast(self.pop_u64()));
        const a = @as(i64, @bitCast(self.pop_u64()));

        self.push_u64(@as(u64, @bitCast(switch (op) {
            Op.add => a + b,
            Op.sub => a - b,
            Op.mul => a * b,
            Op.div => @divTrunc(a, b),
            Op.pow => math.pow(i64, a, b),
        })));
    }

    fn do_binaryf(self: *Self, op: Op) void {
        const b = @as(f64, @bitCast(self.pop_u64()));
        const a = @as(f64, @bitCast(self.pop_u64()));

        self.push_u64(@as(u64, @bitCast(switch (op) {
            Op.add => a + b,
            Op.sub => a - b,
            Op.mul => a * b,
            Op.div => a / b,
            Op.pow => math.pow(f64, a, b),
        })));
    }

    fn push_u8(self: *Self, value: u8) void {
        self.stack[self.sp] = value;
        self.sp += 1;
    }

    fn push_u64(self: *Self, value: u64) void {
        // Store in little-endian (LSB first)
        self.stack[self.sp] = @as(u8, @truncate(value));
        self.stack[self.sp + 1] = @as(u8, @truncate(value >> 8));
        self.stack[self.sp + 2] = @as(u8, @truncate(value >> 16));
        self.stack[self.sp + 3] = @as(u8, @truncate(value >> 24));
        self.stack[self.sp + 4] = @as(u8, @truncate(value >> 32));
        self.stack[self.sp + 5] = @as(u8, @truncate(value >> 40));
        self.stack[self.sp + 6] = @as(u8, @truncate(value >> 48));
        self.stack[self.sp + 7] = @as(u8, @truncate(value >> 56));
        self.sp += 8;
    }

    fn pop_u8(self: *Self) u8 {
        self.sp -= 1;
        return self.stack[self.sp];
    }

    fn pop_u64(self: *Self) u64 {
        self.sp -= 8; // Decrement first
        // Read bytes in little-endian order (LSB first)
        const b1 = self.stack[self.sp];
        const b2 = self.stack[self.sp + 1];
        const b3 = self.stack[self.sp + 2];
        const b4 = self.stack[self.sp + 3];
        const b5 = self.stack[self.sp + 4];
        const b6 = self.stack[self.sp + 5];
        const b7 = self.stack[self.sp + 6];
        const b8 = self.stack[self.sp + 7];

        return (@as(u64, b1) << 0) |
            (@as(u64, b2) << 8) |
            (@as(u64, b3) << 16) |
            (@as(u64, b4) << 24) |
            (@as(u64, b5) << 32) |
            (@as(u64, b6) << 40) |
            (@as(u64, b7) << 48) |
            (@as(u64, b8) << 56);
    }

    fn peek_u8(self: *Self) u8 {
        return self.stack[self.sp - 1]; // Top element is at sp - 1
    }

    fn peek_u64(self: *Self) u64 {
        const sp = self.sp;
        // Peek the last pushed u64 (sp - 8 to sp - 1)
        const b1 = self.stack[sp - 8];
        const b2 = self.stack[sp - 7];
        const b3 = self.stack[sp - 6];
        const b4 = self.stack[sp - 5];
        const b5 = self.stack[sp - 4];
        const b6 = self.stack[sp - 3];
        const b7 = self.stack[sp - 2];
        const b8 = self.stack[sp - 1];

        return (@as(u64, b1) << 0) |
            (@as(u64, b2) << 8) |
            (@as(u64, b3) << 16) |
            (@as(u64, b4) << 24) |
            (@as(u64, b5) << 32) |
            (@as(u64, b6) << 40) |
            (@as(u64, b7) << 48) |
            (@as(u64, b8) << 56);
    }

    pub fn run(self: *Self) Error!void {
        while (true) {
            if (self.ip >= self.chunk.code.items.len) return Error.OutOfBounds;

            // self.dbg();

            const opcode = @as(OpCode, @enumFromInt(self.chunk.get_op_code(self.ip)));
            self.ip += 1;

            switch (opcode) {
                OpCode.SetupStack => {
                    const size = self.read_long();
                    self.memory_layout = self.allocator.alloc(u8, size) catch @panic("Out Of Memory.");
                },
                OpCode.OpLoadLong => {
                    const at = self.read_long();
                    const val = self.mem_get_u64(at);
                    self.push_u64(val);
                },
                OpCode.OpStoreLong => {
                    const at = self.read_long();
                    const val = self.pop_u64();
                    self.mem_set_u64(at, val);
                },
                OpCode.OpLoadByte => {
                    const at = self.read_long();
                    const val = self.mem_get_u8(at);
                    self.push_u8(val);
                },
                OpCode.OpStoreByte => {
                    const at = self.read_long();
                    const val = self.pop_u8();
                    self.mem_set_u8(at, val);
                },

                OpCode.OpPushLong => {
                    const value = self.read_long();
                    self.push_u64(value);
                },
                OpCode.OpPopLong => _ = self.pop_u64(),
                OpCode.OpPushByte => {
                    const value = self.read_byte();
                    self.push_u8(value);
                },
                OpCode.OpPopByte => _ = self.pop_u8(),

                OpCode.IntToFloat => {
                    const v: i64 = @bitCast(self.pop_u64());
                    const target: f64 = @floatFromInt(v);
                    self.push_u64(@bitCast(target));
                },
                OpCode.FloatToInt => {
                    const v: f64 = @bitCast(self.pop_u64());
                    const target: i64 = @intFromFloat(v);
                    self.push_u64(@bitCast(target));
                },
                // OpCode.ToBool => unreachable,

                OpCode.OpAddI => self.do_binaryi(.add),
                OpCode.OpSubtractI => self.do_binaryi(.sub),
                OpCode.OpMultiplyI => self.do_binaryi(.mul),
                OpCode.OpDivideI => self.do_binaryi(.div),
                OpCode.OpPowerI => self.do_binaryi(.pow),

                OpCode.OpNegateF => {
                    const v: f64 = @bitCast(self.pop_u64());
                    const target = -v;
                    self.push_u64(@bitCast(target));
                },
                OpCode.OpNegateI => {
                    const v: i64 = @bitCast(self.pop_u64());
                    const target = -v;
                    self.push_u64(@bitCast(target));
                },
                OpCode.OpNot => {
                    self.push_u8(@intFromBool(self.pop_u8() == 0));
                },

                OpCode.OpAddF => self.do_binaryf(.add),
                OpCode.OpSubtractF => self.do_binaryf(.sub),
                OpCode.OpMultiplyF => self.do_binaryf(.mul),
                OpCode.OpDivideF => self.do_binaryf(.div),
                OpCode.OpPowerF => self.do_binaryf(.pow),

                OpCode.OpDbgI => {
                    print("int: {d}\n", .{@as(i64, @bitCast(self.pop_u64()))});
                },
                OpCode.OpDbgF => {
                    print("float: {d}\n", .{@as(f64, @bitCast(self.pop_u64()))});
                },
                OpCode.OpDbgB => {
                    print("bool: {s}\n", .{if (self.pop_u8() != 0) "vrai" else "faux"});
                },

                OpCode.OpHalt => {
                    return;
                },
            }
        }
    }
};
