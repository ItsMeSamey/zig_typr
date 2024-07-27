//! The parser struct

allocator: *std.mem.Allocator,
options: *Options,
getWord: fn () []u8,

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

/// Create instance of `This` struct
pub fn create(allocator: *std.mem.Allocator, options: *Options, getWord: fn () []u8) std.mem.Allocator.Error!Self {
  var retval: Self = .{
    .allocator = allocator,
    .options = options,
    .getWord = getWord,
    ._original = try ListU8.init(allocator),
    ._color = try ListColor.init(allocator),
  };
  retval._original.ensureTotalCapacity(options.wordcount*32);
  retval._color.ensureTotalCapacity(options.wordcount*32);
  retval.populate();
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

  self._original.items[self._original.items.len - 1] = 0;
}

/// Process input character by character (this currently only supports ascii)
/// returns true if display needs to be updated
pub fn processInput(self: *Self, input: u8) bool {
  defer if (self._at == self._original.items.len - 1) {
    self.rePopulate();
  };

  return if (input == 0) {
    self.processBackspace();
  } else {
    self.processTextInput(input);
  };
}

inline fn processBackspace(self: *Self) bool {
  if (self._at == 0) {
    return false;
  }
  self._at -= 1;

  // For BehaviourTyping = .append
  if (self._color[self._at] == .mistake) {
    _ = self._original.orderedRemove(self._at);
    return true;
  }

  switch (self.options.behaviourBackspace) {
    .never => {
      self._at += 1;
      return false;
    },
    .mistake => {
      if (self._color[self._at - 1] == .fixed) {
        self._color.items.len -= 1;
      }
    },
    .always => {
      self._color.items.len -= 1;
    },
  }
  return true;
}

inline fn processTextInput(self: *Self, input: u8) bool {
  self._at += 1;
  if (input == self._original[self._at] and (self.options.behaviourTyping != .append or
      (self._color.items.len != 0  and self._color.items[self._color.items.len - 1] == .mistake))) {
    self._color.append(.correct);
    return true;
  } else {
    // Next character will be .fixed no matter what (or maybe a .mistake)
    if (self._color.items.len == self._at - 1) {
      self._color.append(.fixed);
    }
    switch (self.options.behaviourTyping) {
      .stop => {
        self._at -= 1;
        return false;
      },
      .skip => {},
      .append => {
        self._color[self._at - 1] = .mistake;
      },
    }
  }

  return true;
}

