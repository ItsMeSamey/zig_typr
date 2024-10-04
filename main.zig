// zig run -lc -lnotcurses -lnotcurses-core -lnotcurses-ffi main.zig
// zig run -lc -lncurses main.zig
const std = @import("std");
const NC = @import("interfaces/ncurses.zig");

const Parser = @import("interfaces/parser/parser.zig");

var parser: Parser = undefined;
var parserOptions: @import("interfaces/parser/options.zig") = .{};
var random: std.Random = undefined;

const Generaors = union(enum) {
  word: @import("word_gen/words.zig"),
};

var generaor: Generaors = undefined;

fn gen() []const u8 {
  return switch(generaor) {
    .word => |w| w.gen(),
  };
}

/// the default initialization
fn init() !void {
  random = @import("word_gen/rng.zig").random();

  // https://github.com/ziglang/zig/issues/19832
  generaor = Generaors{
    .word = .{
      .random = random,
    }
  };

  parser = try Parser.create(std.heap.c_allocator, &parserOptions, gen);
}

pub fn main() !void {
  try init();
  try ncursesLoop();
}

/// The ncursesLoop
fn ncursesLoop() !void {
  defer NC.deinit();

  try NC.init(.{
    .parser = &parser,
  });

  while (try NC.process()) {}
}

