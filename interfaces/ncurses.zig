//! The Ncurses interface
const std = @import("std");
const Parser = @import("parser/parser.zig");
const ColorEnum = Parser.Color;
const Topts = @import("typeops/operations.zig");

const nc = @cImport({
  @cInclude("ncurses.h");
});

/// Error union returned by most functions
pub const NcursesErrors = error{
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
  printw,
  attrset,
  move,
  addch,
  refresh,

  /// Deinitialization and stuff
  DeinitError,
} || std.mem.Allocator.Error;

pub const Options = struct {
  parser: *Parser,

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

pub const SparseOptions = Topts.NonOptional(Topts.DeepOptioned(Options));


pub var OPTIONS: Options = undefined;
var WINDOW: *nc.WINDOW = undefined;

/// The main init function
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

  try hardRefresh();
}

/// Deinit ncurses, otherwise the terminal will be messed up
pub fn deinit() void {
  _ = nc.endwin();
}

/// Set the options, only sets what is changed
pub fn setOptions() NcursesErrors!void {
  return NcursesErrors.unimplemented;
}

/// The main loop
pub fn process() NcursesErrors!bool {
  const inp = nc.getch();
  // { // for debugging input
  //   const y = nc.getcury(WINDOW);
  //   const x = nc.getcurx(WINDOW);
  //   if (nc.ERR == nc.mvprintw(nc.getmaxy(WINDOW) - 1, 0, "%d", inp)) return NcursesErrors.printw;
  //   if (nc.ERR == nc.move(y, x)) return NcursesErrors.move;
  // }

  if (try OPTIONS.parser.processInput(switch (inp) {
    32...126 => |val| @intCast(val), // ascii characters
    263 => 0, // backspace
    0x1b, 0x3 => return false,
    else => return true,
  })) {
    try hardRefresh();
  }
  return true;
}

fn hardRefresh() NcursesErrors!void {
  // if (nc.ERR == nc.move(0, 0)) return NcursesErrors.move;
  // if (OPTIONS.parser._at == 0)
  // if (nc.printw("%f", @as(f32, )))

  if (nc.ERR == nc.move(1, 0)) return NcursesErrors.move;

  // The colored input
  for (0.. ,OPTIONS.parser._color.items[0..]) |ind, color| {
    try attrPut(OPTIONS.parser._original.items[ind], color);
  }
  const y = nc.getcury(WINDOW);
  const x = nc.getcurx(WINDOW);

  // Rest of the stuff
  if (OPTIONS.parser._original.items.len > OPTIONS.parser._color.items.len) {
    try attrSet(.normal);
    for (OPTIONS.parser._original.items[OPTIONS.parser._color.items.len..]) |char| {
      try put(char);
    }
    if (nc.ERR == nc.move(y, x)) return NcursesErrors.move;
  }

  if (nc.ERR == nc.refresh()) return NcursesErrors.refresh;
}

inline fn attrPut(char: u8, color: ColorEnum) NcursesErrors!void {
  try attrSet(color);
  try put(char);
}

inline fn attrSet(color: ColorEnum) NcursesErrors!void {
  const colorPair: c_int = nc.COLOR_PAIR(@as(c_int, @intFromEnum(color))+1);
  if (nc.ERR == nc.attrset(colorPair)) return NcursesErrors.attrset;
}

inline fn put(char: u8) NcursesErrors!void {
  if (nc.ERR == nc.addch(char)) return NcursesErrors.addch;
}

