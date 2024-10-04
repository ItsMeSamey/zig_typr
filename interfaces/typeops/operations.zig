//! This is where the type operations happen
const std = @import("std");

pub fn Optional(comptime T: type) type {
  return switch (@typeInfo(T)) {
    .optional => T,
    else => @Type(.{ .optional = .{.child = T} }),
  };
} 

fn OperatedStruct(comptime T: type, comptime operation: fn(comptime T: type) type) type {
  const info = @typeInfo(T).@"struct";
  comptime var fields: []const std.builtin.Type.StructField = &.{};
  for (info.fields) |f| {
    const optionalFtype = operation(f.type);
    fields = fields ++ [_]std.builtin.Type.StructField{
      .{
        .name = f.name,
        .type = optionalFtype,
        .default_value = @ptrCast(&@as(optionalFtype, null)),
        .is_comptime = f.is_comptime,
        .alignment = f.alignment,
      }
    };
  }
  return @Type(.{
    .@"struct" = .{
      .layout = info.layout,
      .backing_integer = info.backing_integer,
      .fields = fields,
      .decls = info.decls,
      .is_tuple = info.is_tuple,
    }
  });
}

pub fn OptionalStruct(comptime T: type) type {
  return OperatedStruct(T, Optional);
}

fn DeepOptionalStruct(comptime T: type) type {
  return switch (@typeInfo(T)) {
    .optional => |t| DeepOptionalStruct(t.child),
    .@"struct" => |s| OperatedStruct(s, DeepOptionalStruct),
    else => @Type(.{ .optional = .{.child = T} }),
  };
}

