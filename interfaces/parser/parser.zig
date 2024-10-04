//! The parser struct

allocator: std.mem.Allocator,
options: *Options,
getWord: *const fn () []const u8,

/// The array containing the text to be displayed
original: ListU8,
/// The array we use for coloring
color: ListColor,
/// Where the next uncolored character is at
at: u16 = 0,

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

fn populate(self: *Self) std.mem.Allocator.Error!void {
  for (0..self.options.wordcount) |_| {
    try self.original.appendSlice(self.getWord());
    try self.original.append(' ');
  }

  self.original.items.len -= 1;
}

fn rePopulate(self: *Self) std.mem.Allocator.Error!void {
  self.original.clearRetainingCapacity();
  self.color.clearRetainingCapacity();
  self.at = 0;

  try self.populate();
}

/// Create instance of `This` struct
pub fn init(allocator: std.mem.Allocator, options: *Options, comptime getWord: *const fn () []const u8) AllocatorError!Self {
  var retval: Self = .{
    .allocator = allocator,
    .options = options,
    .getWord = getWord,
    .original = ListU8.init(allocator),
    .color = ListColor.init(allocator),
  };
  try retval.original.ensureTotalCapacity(options.wordcount*32);
  try retval.color.ensureTotalCapacity(options.wordcount*32);
  try retval.populate();
  return retval;
}

fn processBackspace(self: *Self) bool {
  if (self.color.items.len == 0) {
    return false;
  }

  // For BehaviourTyping = .append
  if (self.color.getLast() == .mistake) {
    _ = self.original.orderedRemove(self.color.items.len - 1);
    self.color.items.len -= 1;
    self.at -= 1;
    return true;
  }

  switch (self.options.behaviourBackspace) {
    .never => { return false; },
    .mistake => {
      if (self.color.getLast() == .fixed) {
        self.color.items.len -= 1;
        self.at -= 1;
      }
    },
    .always => {
      self.color.items.len -= 1;
      self.at -= 1;
    },
  }
  return true;
}

fn processTextInput(self: *Self, input: u8) AllocatorError!bool {
  if (input == self.original.items[self.at] and (self.options.behaviourTyping != .append or
      self.color.items.len == 0 or self.color.getLast() != .mistake)) {
    try self.color.append(.correct);
    self.at += 1;
  } else {
    // Next character will be .fixed no matter what (or maybe a .mistake)
    if (self.color.items.len == self.at) {
      try self.color.append(.fixed);
    }
    switch (self.options.behaviourTyping) {
      .stop => { return false; },
      .skip => { self.at += 1; },
      .append => {
        try self.original.insertSlice(self.at, &[1]u8{input});
        self.color.items[self.at] = .mistake;
        self.at += 1;
      },
    }
  }
  return true;
}

/// Process input character by character (this currently only supports ascii)
/// returns true if display needs to be updated
pub fn processInput(self: *Self, input: u8) AllocatorError!bool {
  defer if (self.at == self.original.items.len) {
    self.rePopulate() catch unreachable;
  };

  return switch (input) {
    0 => self.processBackspace(),
    else => self.processTextInput(input),
  };
}

