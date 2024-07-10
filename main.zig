// zig run -lc -lnotcurses -lnotcurses-core -lnotcurses-ffi main.zig
const std = @import("std");
const NCUI = @import("interfaces/notcurses.zig");
const Options = @import("interfaces/options.zig");

fn interfaces() !void {
  try NCUI.init(null);
  var options: Options.InterfaceOptions = .{ .allocator = null, };
  var ui = NCUI.NotcursesUI{ .options = &options };
  try ui.print("hlo mann");
}

pub fn main() !void{
  interfaces() catch |e| {
    try NCUI.deinit();
    return e;
  };
  try NCUI.deinit();
}

