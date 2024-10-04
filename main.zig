// zig run -lc -lnotcurses -lnotcurses-core -lnotcurses-ffi main.zig
// zig run -lc -lncurses main.zig
const std = @import("std");
const NC = @import("interfaces/ncurses.zig");
const Parser = @import("interfaces/parser/parser.zig");
const Generator = union(enum) {
  word: WordGen,

  const WordGen = @import("word_gen/genWords.zig").GetWordGen(.{});
};

var parserOptions: @import("interfaces/parser/options.zig") = .{};
var parser: Parser = undefined;
var generaor: Generator = undefined;

fn gen() []const u8 {
  return switch(generaor) {
    .word => generaor.word.gen(),
  };
}

/// the default initialization
fn init() !void {
  // https://github.com/ziglang/zig/issues/19832
  generaor = Generator{
    .word = Generator.WordGen.default(),
  };

  parser = try Parser.init(std.heap.c_allocator, &parserOptions, gen);
}

/// The ncursesLoop
fn ncursesLoop() !void {
  defer NC.deinit() catch unreachable;

  try NC.init(.{
    .parser = &parser,
  });

  while (try NC.process()) {}
}

pub fn main() !void {
  try init();
  try ncursesLoop();
}

