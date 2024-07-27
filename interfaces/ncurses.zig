//! The Ncurses interface
const std = @import("std");
const Parser = @import("parser/parser.zig");
const ColorEnum = Parser.Color;
const Topts = @import("typeops/operations.zig");

const nc = @cImport({
  @cDefine("_GNU_SOURCE", {});
  @cInclude("ncurses.h");
  @cUndef("_GNU_SOURCE");
});

/// Error union returned by most functions
const NcursesErrors = error{
  /// Initialization and stuff
  unimplemented,
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

const Options = struct {
  // parser: Parser,
  color: Color = Color{},

  /// The ncurses color type
  const NcColor = nc.NCURSES_COLOR_T;

  /// The struct for all the colors
  const Color = struct {
    /// Default color of text
    normal:    NcColor = nc.COLOR_WHITE,
    /// Default color of text background
    normalBg:  NcColor = nc.COLOR_BLACK,

    /// Color of correct text
    correct:   NcColor = nc.COLOR_GREEN,
    /// Color of correct text background
    correctBg: NcColor = nc.COLOR_BLACK,

    /// Color of text that was once wrong
    fixed:     NcColor = nc.COLOR_MAGENTA,
    /// Color of fixed text background
    fixedBg:   NcColor = nc.COLOR_BLACK,

    /// Color of mistake
    mistake:   NcColor = nc.COLOR_RED,
    /// Color of mistake's background
    mistakeBg: NcColor = nc.COLOR_BLACK,
  };
};

const SparseOptions = Topts.NonOptional(Topts.DeepOptioned(Options));


var OPTIONS: Options = undefined;
var WINDOW: *nc.WINDOW = undefined;

pub fn init(options: Options) NcursesErrors!void {
  OPTIONS = options;
  nc.ESCDELAY = 0; // DO NOT delay the escape key press

  WINDOW = nc.initscr() orelse return NcursesErrors.initscr;
  if (nc.ERR == nc.noecho()) return NcursesErrors.noecho;
  if (nc.ERR == nc.raw()) return NcursesErrors.raw;
  if (nc.ERR == nc.keypad(nc.stdscr, true)) return NcursesErrors.keypad;
  if (nc.ERR == nc.start_color()) return NcursesErrors.start_color;
  if (nc.ERR == nc.init_color(nc.COLOR_BLACK, 0, 0, 0)) return NcursesErrors.init_color;

  inline for (@typeInfo(ColorEnum).Enum.fields) |field| {
    if (nc.ERR == nc.init_pair(@as(nc.NCURSES_PAIRS_T, field.value+1),
      @field(options.color, field.name),
      @field(options.color, field.name ++ "Bg"),
    )) return NcursesErrors.init_color;
  }
}

pub fn deinit() void {
  _ = nc.endwin();
}

pub fn setOptions() NcursesErrors!void {
  return NcursesErrors.unimplemented;
}

pub fn poll() void {
}

pub fn main() !void {
  defer deinit();
  try init(Options{});

  _ = nc.mvprintw(0, 0, "%s", "Heloo");

  _ = nc.getch();
}

