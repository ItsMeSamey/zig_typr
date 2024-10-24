const std = @import("std");

// Is

fn Is(comptime T: type, comptime tag: std.builtin.TypeId) void {
  const typeInfo = @typeInfo(T);
  comptime if (typeInfo != tag) {
    @compileError("Expected a " ++ @tagName(tag) ++ " but got " ++ std.fmt.comptimePrint("{}", .{ typeInfo }));
  };
}

// Has

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

// Get

fn GetField(comptime T: type, comptime field: [:0]const u8) type {
  HasField(T, field);

  const fields = std.meta.fields(T);
  inline for (fields) |f| {
    if (std.mem.eql(u8, f.name, field)) {
      return f.type;
    }
  }
}

fn GetFnReturnType(comptime T: type) type {
  Is(T, .@"fn");

  return @typeInfo(T).@"fn".return_type.?;
}

fn GetErrorUnionChild(comptime T: type) type {
  Is(T, .error_union);

  return @typeInfo(T).error_union.payload;
}

// Conforms

pub fn ConformsParser(comptime T: type) void {
  Is(T, .@"struct");

  HasField(GetField(T, "text"), "items");
  HasField(GetField(T, "color"), "items");

  const processReturnType = GetFnReturnType(@TypeOf(@field(T, "process")));
  Is(GetErrorUnionChild(processReturnType), .bool);
  
  HasFn(T, "process", fn (self: *T, input: u8) processReturnType);
}

pub fn ConformsGenerator(comptime T: type) void {
  Is(T, .@"struct");
  HasDecl(T, "gen");

  HasDecl(T, "Options");
  Is(@field(T, "Options"), .@"struct");

  const initOptionsType = if (@hasDecl(T, "OptionalOptions")) @field(T, "OptionalOptions") else @field(T, "Options");
  HasFn(T, "init", fn (allocator: std.mem.Allocator, options: initOptionsType) T);

  HasFn(T, "gen", fn (self: *T) []const u8);
}

