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
  wclear,

  /// Deinitialization and stuff
  DeinitError,
} || std.mem.Allocator.Error;

pub const Options = struct {
  parser: *Parser,

  color: Color = Color{},

  /// The ncurses color type
  pub const NcColor = nc.NCURSES_COLOR_T;

  /// The struct for all the colors
  pub const Color = struct {
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

  inline for (std.meta.fields(ColorEnum)) |field| {
    if (nc.ERR == nc.init_pair(@as(nc.NCURSES_PAIRS_T, field.value+1),
      @field(options.color, field.name),
      @field(options.color, field.name ++ "Bg"),
    )) return NcursesErrors.init_color;
  }

  try hardRefresh();
}

/// Deinit ncurses, otherwise the terminal will be messed up
pub fn deinit() !void {
  if (0 != nc.endwin()) return NcursesErrors.DeinitError;
}

/// Set the options, only sets what is changed
pub fn setOptions() NcursesErrors!void {
  return NcursesErrors.unimplemented;
}

/// The main loop
pub fn process() NcursesErrors!bool {
  const inp = nc.getch();

  if (try OPTIONS.parser.processInput(switch (inp) {
    32...126 => |val| @intCast(val), // ascii characters
    263 => 0, // backspace
    0x3 => return false, // ctrl+c
    0x1b => return false, // esc
    else => return true, // continue
  })) { try hardRefresh(); }
  return true;
}

fn hardRefresh() NcursesErrors!void {
  // clear the WINDOW as (redundant text when backspace is pressed)
  if(nc.wclear(WINDOW) != 0) return NcursesErrors.wclear;

  if (OPTIONS.parser.original.items.len > nc.COLS - 2) {
    const cols: usize = @intCast(nc.COLS - 1);
    for (0..OPTIONS.parser.original.items.len) |i| {
      if (OPTIONS.parser.original.items[i] == '\n') OPTIONS.parser.original.items[i] = ' ';
    }

    var prevNext: usize = 0;
    while (prevNext < OPTIONS.parser.original.items.len - cols) {
      var next = prevNext + cols;
      while (next > prevNext and OPTIONS.parser.original.items[next] != ' ') next -= 1;

      if (next != prevNext) OPTIONS.parser.original.items[next] = '\n';
      prevNext = next;
    }
  }

  // Move to second line
  if (nc.ERR == nc.move(1, 0)) return NcursesErrors.move;

  // The colored input
  for (0.. ,OPTIONS.parser.color.items[0..]) |ind, color| {
    try attrPut(OPTIONS.parser.original.items[ind], color);
  }
  const y = nc.getcury(WINDOW);
  const x = nc.getcurx(WINDOW);

  // Rest of the stuff
  if (OPTIONS.parser.original.items.len > OPTIONS.parser.color.items.len) {
    try attrSet(.normal);
    for (OPTIONS.parser.original.items[OPTIONS.parser.color.items.len..]) |char| {
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

