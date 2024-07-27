//! This is where the type operations happen
const std = @import("std");
const Type = std.builtin.Type;
const StructField = Type.StructField;

/// Converts all structs and their fields to optional recursively
pub fn DeepOptioned(comptime T: type) type {
  return switch (@typeInfo(T)) {
    .Struct => |s| Optional(operatedStruct(s, deepOptionedStructField)),
    else => Optional(T),
  };
}
fn deepOptionedStructField(comptime field: StructField) StructField {
  return .{
    .name = field.name,
    .default_value = null, // field.default_value
    .is_comptime = field.is_comptime,
    .alignment = field.alignment,
    .type = DeepOptioned(field.type),
  };
}

/// Converts all structs and their fields to optional
pub fn Optioned(comptime T: type) type {
  return switch (@typeInfo(T)) {
    .Struct => |s| Optional(operatedStruct(s, optionedStructField)),
    else => Optional(T),
  };
}
fn optionedStructField(comptime field: StructField) StructField {
  return .{
    .name = field.name,
    .default_value = null, // field.default_value
    .is_comptime = field.is_comptime,
    .alignment = field.alignment,
    .type = Optional(field.type),
  };
}

/// Operates on all the fields of a given structs
fn operatedStruct(comptime structInfo: Type.Struct, comptime func: fn (StructField) StructField) type {
  comptime var fieldsArr: [structInfo.fields.len]StructField = undefined;
  return @Type(.{
    .Struct = .{
      .layout = structInfo.layout,
      .backing_integer = structInfo.backing_integer,
      .decls = structInfo.decls,
      .is_tuple = structInfo.is_tuple,
      .fields = inline for (structInfo.fields, 0..) |field, i| {
        fieldsArr[i] = func(field);
      },
    }
  });
}

/// Converts a type to an optional type
pub fn Optional(comptime T: type) type {
  return switch (@typeInfo(T)) {
    .Optional => T,
    else => @Type(.{ .Optional = .{ .child = T } }),
  };
}

/// Converts a type to an non-optional type
pub fn NonOptional(comptime T: type) type {
  return switch (@typeInfo(T)) {
    .Optional => |o| o.child,
    else => T,
  };
}

