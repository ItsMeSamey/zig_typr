/// The parser struct
allocator: *std.mem.Allocator,
options: *Options,
getWord: fn () []u8,

/// The array containing the text to be displayed
_original: ListU8,
/// The array we use for coloring
_color: ListColor,
/// Where the cursor should be
_at: u16 = 0,
/// Patches for behaviourTyping = .append
_patch: ListU8,

const std = @import("std");
const Options = @import("options.zig");

const Self = @This();

const ListU8 = std.ArrayList(u8);
const ListColor = std.ArrayList(Color);
/// How to color the screen text
const Color = enum {
  normal,
  correct,
  fixed,
};

pub fn create(allocator: *std.mem.Allocator, options: *Options, getWord: fn () []u8) std.mem.Allocator.Error!Self {
  var retval: Self = .{
    .allocator = allocator,
    .options = options,
    .getWord = getWord,
    ._original = try ListU8.initCapacity(options.wordcount*32),
    ._color = try ListColor.initCapacity(options.wordcount*32),
  };
  retval.populate();
  return retval;
}

fn rePopulate(self: *Self) std.mem.Allocator.Error!void {
  self._original.items.len = 0;
  self._color.items.len = 0;

  try self.populate();
  
  self._at = 0;
  self._cursor = 0;
} 

fn populate(self: *Self) std.mem.Allocator.Error!void {
  for (0..self.options.wordcount) |_| {
    try self._original.appendSlice(self.getWord());
    try self._original.append(' ');
  }
  self._patch.items.len -= 1;

  self._color = try self._color.ensureTotalCapacity(self._original.len);
}

pub fn processInput(self: *Self, input: u8) void {
  if (input == 0) {
    self.processBackspace();
  } else {
    self.processTextInput(input);
  }
}

fn processBackspace(self: *Self) void {
  if (self._patch.items.len != 0) {
    self._patch.items.len -= 1;
    return;
  } else if (self._at == 0) {
    return;
  }

  switch (self.options.behaviourBackspace) {
    .always => { self._at -= 1; },
    .mistake => { if (self._color[self._at - 1] == .fixed) self._at -= 1; },
    .never => { return; },
  }
}

fn processTextInput(self: *Self, input: u8) void {
  if (input == self._original[self._at] and (self.options.behaviourTyping != .append or self._patch.items.len == 0)) {
    self._color[self._at] = .correct;
    self._at += 1;
    return;
  } else {
    self._color[self._at] = .fixed;
    switch (self.options.behaviourTyping) {
      .skip => { self._at += 1;  },
      .stop => {},
      .append => { self._patch.append(input); },
    }
  }
}

