//! The parser struct

allocator: std.mem.Allocator,
options: *Options,
getWord: *const fn () []const u8,

/// The array containing the text to be displayed
_original: ListU8,
/// The array we use for coloring
_color: ListColor,
/// Where the next uncolored character is at
_at: u16 = 0,

const std = @import("std");
const Options = @import("options.zig");

const Self = @This();
/// How to color the screen text
pub const Color = enum {
  normal,
  correct,
  fixed,
  mistake,
};

const ListU8 = std.ArrayList(u8);
const ListColor = std.ArrayList(Color);
const AllocatorError = std.mem.Allocator.Error;

/// Create instance of `This` struct
pub fn create(allocator: std.mem.Allocator, options: *Options, comptime getWord: *const fn () []const u8) AllocatorError!Self {
  var retval: Self = .{
    .allocator = allocator,
    .options = options,
    .getWord = getWord,
    ._original = ListU8.init(allocator),
    ._color = ListColor.init(allocator),
  };
  try retval._original.ensureTotalCapacity(options.wordcount*32);
  try retval._color.ensureTotalCapacity(options.wordcount*32);
  try retval.populate();
  return retval;
}

fn rePopulate(self: *Self) std.mem.Allocator.Error!void {
  self._original.clearRetainingCapacity();
  self._color.clearRetainingCapacity();
  self._at = 0;

  try self.populate();
} 

fn populate(self: *Self) std.mem.Allocator.Error!void {
  for (0..self.options.wordcount) |_| {
    try self._original.appendSlice(self.getWord());
    try self._original.append(' ');
  }

  self._original.items.len -= 1;
}

/// Process input character by character (this currently only supports ascii)
/// returns true if display needs to be updated
pub fn processInput(self: *Self, input: u8) AllocatorError!bool {
  defer if (self._at == self._original.items.len) {
    self.rePopulate() catch {};
  };

  return switch (input) {
    0 => self.processBackspace(),
    else => self.processTextInput(input),
  };
}

inline fn processBackspace(self: *Self) bool {
  if (self._color.items.len == 0) {
    return false;
  }

  // For BehaviourTyping = .append
  if (self._color.getLast() == .mistake) {
    _ = self._original.orderedRemove(self._color.items.len - 1);
    self._color.items.len -= 1;
    self._at -= 1;
    return true;
  }

  switch (self.options.behaviourBackspace) {
    .never => { return false; },
    .mistake => {
      if (self._color.getLast() == .fixed) {
        self._color.items.len -= 1;
        self._at -= 1;
      }
    },
    .always => {
      self._color.items.len -= 1;
      self._at -= 1;
    },
  }
  return true;
}

inline fn processTextInput(self: *Self, input: u8) AllocatorError!bool {
  if (input == self._original.items[self._at] and (self.options.behaviourTyping != .append or
      self._color.items.len == 0 or self._color.getLast() != .mistake)) {
    try self._color.append(.correct);
    self._at += 1;
  } else {
    // Next character will be .fixed no matter what (or maybe a .mistake)
    if (self._color.items.len == self._at) {
      try self._color.append(.fixed);
    }
    switch (self.options.behaviourTyping) {
      .stop => { return false; },
      .skip => { self._at += 1; },
      .append => {
        try self._original.insertSlice(self._at, &[1]u8{input});
        self._color.items[self._at] = .mistake;
        self._at += 1;
      },
    }
  }
  return true;
}

