const std = @import("std");
pub const Element = @import("element.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap([]const u8);
const assert = std.debug.assert;
const panic = std.debug.panic;

fn trim(s: []const u8) []const u8 {
    return std.mem.trim(u8, s, " ");
}

pub const TokenType = enum {
    blockquote,
    bracket,
    code,
    code_block,
    colon,
    exclaim,
    frontmatter,
    heading,
    paren,
    star,
    ul,
    number,
    plain,
    nl,
    eof
};

const delimiters = [_]u8{
    '>',
    '-',
    '#',
    ':',
    '!',
    '[',
    ']',
    '(',
    ')',
    '`',
    '*',
    '\n'
};

const Token = struct {
    kind: TokenType,
    start: usize,
    length: usize
};

pub const Lexer = struct {
    raw: []const u8,
    start: usize,
    current: usize,
    col: usize,
    tokens: ArrayList(Token),

    fn init(allocator: Allocator, raw: []const u8) Lexer {
        return .{
            .raw = raw,
            .start = 0,
            .current = 0,
            .col = 0,
            .tokens = ArrayList(Token).init(allocator)
        };
    }

    fn deinit(self: *Lexer) void {
        self.tokens.deinit();
    }

    fn tokenize(self: *Lexer) !ArrayList(Token) {
        while (!self.isAtEnd()) {
        }
    }
};

const Self = @This();

allocator: Allocator,
raw: []const u8,
frontmatter: StringHashMap,
tokens: *ArrayList(Token) = undefined,
ast: *Element,
output: []const u8 = "",

start: usize,
current: usize,

temp_strings: ArrayList([]u8),