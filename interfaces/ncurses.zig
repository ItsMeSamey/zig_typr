//! The Ncurses interface

const std = @import("std");
const Parser = @import("parser.zig");
const ColorEnum = Parser.Color;

const nc = @cImport({
  @cInclude("ncurses.h");
});

/// Error union returned by most functions
const NotcursesErrors = error{
  /// Initialization and stuff
  initscr,
  noecho,
  raw,
  keypad,
  start_color,
  init_color,
  init_pair,

  /// Regarding everything in between
  PutstrError,
  RenderError,
  RasterizeError,

  /// Deinitialization and stuff
  DeinitError,
};

const Color = struct {
  /// Default color of text
  normal:    c_int = nc.COLOR_WHITE,
  /// Default color of text background
  normalBg:  c_int = nc.COLOR_BLACK,

  /// Color of correct text
  correct:   c_int = nc.COLOR_GREEN,
  /// Color of correct text background
  correctBg: c_int = nc.COLOR_BLACK,

  /// Color of text that was once wrong
  fixed:     c_int = nc.COLOR_MAGENTA,
  /// Color of fixed text background
  fixedBg:   c_int = nc.COLOR_BLACK,

  /// Color of mistake
  mistake:   c_int = nc.COLOR_RED,
  /// Color of mistake's background
  mistakeBg: c_int = nc.COLOR_BLACK,
};

const Options = struct {
  color: Color = Color{},
};

pub fn init(options: Options) void {
  std.log.debug("initscr", .{}); std.time.sleep(1000_000_00);
  _ = nc.initscr() orelse @panic("error at initscr");
  std.log.debug("initscr", .{}); std.time.sleep(1000_000_00);
  if (0 != nc.noecho()) unreachable;
  if (0 != nc.raw()) unreachable;
  if (0 != nc.keypad(nc.stdscr, true)) unreachable;
  if (0 != nc.start_color()) unreachable;
  if (0 != nc.init_color(nc.COLOR_BLACK, 0, 0, 0)) unreachable;
  nc.ESCDELAY = 0; // DO NOT delay the escape key press

  inline for (@typeInfo(ColorEnum).Enum.fields) |field| {
    _ = nc.init_pair(@intCast(field.value),
      @intCast(@field(options.color, field.name)),
      @intCast(@field(options.color, field.name ++ "Bg")),
    );
  }
}

pub fn deinit() void {
  _ = nc.endwin();
}

test {
  init(Options{});

  _ = nc.mvprintw(0, 0, "%s", "Helooooooooooo");
  std.time.sleep(1000_000_000);

  deinit();
}

pub fn main() void {
  std.log.debug("init", .{}); std.time.sleep(1000_000_00);
  init(Options{});

  std.log.debug("mvprint", .{}); std.time.sleep(1000_000_00);
  _ = nc.mvprintw(0, 0, "%s", "Helooooooooooo");
  std.time.sleep(1000_000_000);

  std.log.debug("deinit", .{}); std.time.sleep(1000_000_00);
  deinit();

}

