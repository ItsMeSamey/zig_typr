const std = @import("std");

fn IsStruct(comptime T: type) void {
  const typeInfo = @typeInfo(T);
  comptime if (typeInfo != .@"struct") {
    @compileError("Expected a struct but got " ++ std.fmt.comptimePrint("{}", .{ typeInfo }));
  };
}

fn HasDecl(comptime T: type, comptime decl: [:0]const u8) void {
  comptime if (!@hasDecl(T, decl)) {
    @compileError("Input type " ++ @typeName(T) ++ " does not have `" ++ decl ++ "` declaration");
  };
}

fn HasField(comptime T: type, comptime field: [:0]const u8) void {
  comptime if (!@hasField(T, field)) {
    @compileError("Input type " ++ @typeName(T) ++ " does not have `" ++ field ++ "` declaration");
  };
}

fn HasFn(comptime T: type, funcName: [:0]const u8, comptime F: type) void {
  const Fn = @TypeOf(@field(T, funcName));
  comptime if (Fn != F) {
    @compileError("`" ++ funcName ++ "` (" ++ @typeName(Fn) ++ ") does not match the required signature `" ++ @typeName(F) ++ "`");
  };
}

pub fn ConformsParser(comptime T: type) void {
  IsStruct(T);
  HasDecl(T, "process");
  const processFn = @typeInfo(@TypeOf(@field(T, "process"))).@"fn";
  if (@typeInfo(processFn.return_type.?).error_union.payload != bool) {
    @compileError("`process` return type must be `!bool` not " ++ std.fmt.comptimePrint("{}", .{ @typeInfo(processFn.return_type.?) }));
  }

  HasField(T, "text");
  HasField(T, "color");
}

pub fn ConformsGenerator(comptime T: type) void {
  IsStruct(T);
  HasDecl(T, "gen");

  HasDecl(T, "Options");
  IsStruct(@field(T, "Options"));

  const initOptionsType = if (@hasDecl(T, "OptionalOptions")) @field(T, "OptionalOptions") else @field(T, "Options");
  HasFn(T, "init", fn (allocator: std.mem.Allocator, options: initOptionsType) T);

  HasFn(T, "gen", fn (self: *T) []const u8);
}

