pub const common = @import("./common.zig");
pub const AST = @import("./AST.zig");
const ReporterMod = @import("./reporter.zig");
const ParserMod = @import("./Parser.zig");
const TokenMod = @import("./Token.zig");
const LanguageType = @import("./LanguageType.zig");
const AnalyserMod = @import("./Analyser.zig");
const CompilerMod = @import("./Compiler.zig");
const VM = @import("./VM.zig");

pub const report_error = ReporterMod.report_error;

pub const Token = TokenMod.Token;
pub const TokenKind = TokenMod.TokenKind;
pub const TokenList = TokenMod.TokenList;

pub const Parser = ParserMod.Parser;
pub const ParserError = ParserMod.ParserError;

pub const Type = LanguageType.Type;
pub const Primitive = LanguageType.Primitive;

pub const VarSymbol = AnalyserMod.VarSymbol;
pub const ContextIR = AnalyserMod.ContextIR;
pub const Analyser = AnalyserMod.Analyser;

pub const Compiler = CompilerMod.Compiler;

pub const Op = VM.Op;
pub const OpCode = VM.OpCode;
pub const OpReg = VM.OpReg;
pub const Chunk = VM.Chunk;
pub const Vm = VM.VM;

pub fn assert(b: bool) void {
    if (!b) @panic("assertion failed");
}
