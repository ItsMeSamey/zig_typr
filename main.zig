// zig run -lc -lnotcurses -lnotcurses-core -lnotcurses-ffi main.zig
// zig run -lc -lncurses main.zig
const std = @import("std");
const NC = @import("ui/ncurses.zig");
const GetParser = @import("parser/parser.zig").GetParser;


fn init() !void {
  const Generator = @import("text_gen/genWords.zig").GetWordGen(.{});

  var parserOptions: @import("parser/options.zig") = .{};
  const Parser = GetParser(Generator);
  const Ui = NC.GetUi(Parser);

  var ui = Ui{.parser = try Parser.init(std.heap.c_allocator, &parserOptions, .{})};

  while (try ui.process()) {}
}

pub fn main() !void {
  defer NC.deinit() catch unreachable;
  try NC.init(.{});

  try init();
}

