const std = @import("std");

const Options = @import("options.zig");
const ListU8 = std.ArrayList(u8);
const ListColor = std.ArrayList(Color);
const AllocatorError = std.mem.Allocator.Error;

/// enum to dectate how to color the screen text
pub const Color = enum {
  normal,
  correct,
  fixed,
  mistake
};

/// Returns the parser struct
pub fn GetParser(comptime Generator: anytype) type {
  @import("../typeops/typeConstraints.zig").ConformsGenerator(Generator);
  const AssumedWordLength = 32;

  return struct {
    allocator: std.mem.Allocator,
    options: *Options,
    generator: Generator,

    /// The array containing the text to be displayed
    text: ListU8,
    /// The array we use for coloring
    color: ListColor,
    /// Where the next uncolored character is at
    at: u16 = 0,

    const Self = @This();

    fn populate(self: *Self) std.mem.Allocator.Error!void {
      for (0..self.options.wordcount) |_| {
        try self.text.appendSlice(self.generator.gen());
        try self.text.append(' ');
      }

      self.text.items.len -= 1;
    }

    fn rePopulate(self: *Self) std.mem.Allocator.Error!void {
      self.text.clearRetainingCapacity();
      self.color.clearRetainingCapacity();
      self.at = 0;

      try self.populate();
    }

    /// Create instance of `This` struct
    pub fn init(allocator: std.mem.Allocator, options: *Options, generatorOptions: Generator.OptionalOptions) AllocatorError!Self {
      var retval: Self = .{
        .allocator = allocator,
        .options = options,
        .generator = Generator.init(allocator, generatorOptions),
        .text = ListU8.init(allocator),
        .color = ListColor.init(allocator)
      };

      try retval.text.ensureTotalCapacity(options.wordcount*AssumedWordLength);
      try retval.color.ensureTotalCapacity(options.wordcount*AssumedWordLength);
      try retval.populate();

      return retval;
    }

    fn processBackspace(self: *Self) bool {
      if (self.color.items.len == 0) return false;

      switch (self.options.behaviourBackspace) {
        .never => {
          if (self.options.behaviourTyping != .append or self.color.getLast() != .mistake) return false;
          _ = self.text.orderedRemove(self.color.items.len - 1);
        },
        .mistake => {
          // since backspacing mistake makes sense only when using `behaviourTyping = .skip`
          if (self.options.behaviourTyping != .skip or self.color.getLast() != .fixed) return false;
        },
        .always => {},
      }

      self.color.items.len -= 1;
      self.at -= 1;
      return true;
    }

    fn processTextInput(self: *Self, input: u8) AllocatorError!bool {
      if (input == self.text.items[self.at] and (self.options.behaviourTyping != .append or
          self.color.items.len == 0 or self.color.getLast() != .mistake)) {
        try self.color.append(.correct);
      } else {
        switch (self.options.behaviourTyping) {
          .stop => {
            try self.color.append(.fixed);
            return false;
          },
          .skip => try self.color.append(.fixed),
          .append => {
            try self.text.insertSlice(self.at, &[1]u8{input});
            try self.color.append(.mistake);
          },
        }
      }
      self.at += 1;
      return true;
    }

    /// Process input character by character (this currently only supports ascii)
    /// returns true if display needs to be updated
    pub fn process(self: *Self, input: u8) AllocatorError!bool {
      const retval = if (input == 0) self.processBackspace() else try self.processTextInput(input);

      if (self.at == self.text.items.len) try self.rePopulate();
      return retval;
    }
  };
}

