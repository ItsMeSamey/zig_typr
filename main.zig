// zig run -lc -lnotcurses -lnotcurses-core -lnotcurses-ffi main.zig
// zig run -lc -lnotcurses-core main.zig
// zig run -lc -lncurses main.zig
const std = @import("std");
const NC = @import("interfaces/ncurses.zig");

var PARSER: @import("interfaces/parser/parser.zig") = undefined;
var PARSEROPTIONS: @import("interfaces/parser/options.zig") = .{};
var RANDOM: std.Random = undefined;

var GENERAOR: union(enum) {
  word: @import("word_gen/words.zig"),
} = undefined;

fn gen() []const u8 {
  return switch(GENERAOR) {
    .word => |w| w.gen(),
  };
}

fn init() !void {
  RANDOM = @import("word_gen/rng.zig").random();

  // https://github.com/ziglang/zig/issues/19832
  GENERAOR = @TypeOf(GENERAOR){
    .word = .{
      .random = RANDOM,
    }
  };

  PARSER = try @TypeOf(PARSER).create(std.heap.c_allocator, &PARSEROPTIONS, gen);
}

pub fn main() !void {
  try init();
  try ncursesLoop();
}

fn ncursesLoop() !void {
  defer NC.deinit();

  try NC.init(.{
    .parser = &PARSER,
  });

  while (try NC.process()) {}
}

