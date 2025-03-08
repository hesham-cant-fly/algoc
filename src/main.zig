const std = @import("std");
const Lexer = @import("./Lexer.zig");
const Parser = @import("./Parser.zig");
pub const root = @import("root.zig");

const TokenList = root.TokenList;
const common = root.common;
const heap = std.heap;
const mem = std.mem;

var gpa = heap.GeneralPurposeAllocator(.{}){};

pub fn main() !void {
    std.debug.print("Started\n", .{});

    const alloc = gpa.allocator();
    defer {
        const status = gpa.deinit();

        if (status == .leak) @panic("Memory Leak Detected!!");
    }

    // const text: []const u8 = "5 + \"5584\" - '44' / 12 * (5) - abc";
    const text = read_file("./main.algo", alloc);
    defer alloc.free(text);

    var tokens = TokenList{};
    defer tokens.deinit(alloc);

    var lexer = try Lexer.Lexer.init(alloc, &tokens, text);
    lexer.scan();

    var parser = Parser.Parser.init(alloc, text, tokens);
    defer parser.deinit();
    var ast_res = try parser.parse();
    ast_res.dbg();

    var analyser = root.Analyser.init(alloc);
    defer analyser.deinit();
    var ctx = try analyser.analyse(&ast_res);
    // defer ctx.deinit();

    var compiler = root.Compiler.init(alloc, &ctx);
    var chunk = compiler.compile();
    defer chunk.deinit();

    chunk.dbg();

    var vm = root.Vm.init(alloc, &chunk);
    defer vm.deinit();

    try vm.run();
}

fn read_file(path: []const u8, allocator: mem.Allocator) []const u8 {
    var file = std.fs.cwd().openFile(path, .{}) catch @panic("can't open a file.");
    defer file.close();

    const size = file.getEndPos() catch @panic("Can't get the size of a file.");
    const content = allocator.alloc(u8, size) catch @panic("Out Of Memory");

    const byte_read = file.readAll(content) catch @panic("Can't read the file.");
    if (byte_read < size) {
        @panic("Error in reading the file.");
    }

    return content;
}
