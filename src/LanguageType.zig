const std = @import("std");

const debug = std.debug;

pub const Primitive = enum(u8) {
    const Self = Primitive;

    Int,
    Float,

    pub fn get_size(self: Self) usize {
        return switch (self) {
            .Int => 8,
            .Float => 8,
        };
    }

    pub fn can_assign(self: Self, other: *const Type) bool {
        if (other.* != .Primitive) {
            return false;
        }
        const other_primitive = other.Primitive;
        return switch (self) {
            .Int => other_primitive == .Int,
            .Float => other_primitive == .Int or other_primitive == .Float,
        };
    }

    pub fn dbg(self: Self) void {
        switch (self) {
            .Int => debug.print("Int", .{}),
            .Float => debug.print("Float", .{}),
        }
    }
};

pub const Type = union(enum) {
    const Self = Type;

    Primitive: Primitive,

    pub fn get_size(self: *Self) usize {
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
};
