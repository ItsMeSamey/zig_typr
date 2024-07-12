/// The parser struct
allocator: *std.mem.Allocator,
options: *Options,
getWord: fn () []u8,

_original: []u8,
_color: []Color,
_at: u16 = 0,

const std = @import("std");
const Options = @import("options.zig");
const Self = @This();
const List = std.ArrayList(u8);

/// How to color the screen text
pub const Color = enum {
  NORMAL,
  CORRECT,
  FIXED_MISTAKE,
  INCORRECT,
};

fn populate(self: *Self) std.mem.Allocator.Error!void {
  const wc = self.options.wordcount;

  var arr: List = try List.initCapacity(wc*32);
  for (0..wc) |_| { try arr.appendSlice(self.getWord()); }

  self._original = try arr.toOwnedSlice();
  self._color = try self.allocator.alloc(Color, self._original.len);
}

fn rePopulate(self: *Self) std.mem.Allocator.Error!void {
  self.allocator.free(self._original);
  self.allocator.free(self._color);

  try self.populate();
  
  self._at = 0;
} 

pub fn create(allocator: *std.mem.Allocator, options: *Options, getWord: fn () []u8) std.mem.Allocator.Error!Self {
  var retval: Self = .{
    .allocator = allocator,
    .options = options,
    .getWord = getWord,
    ._original = []u8{},
    ._color = []u8{},
  };
  retval.populate();
  return retval;
}

