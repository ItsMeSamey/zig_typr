const std = @import("std");
const Options = @import("options.zig");

const nc = @cImport({
  @cDefine("_GNU_SOURCE", {});
  @cInclude("notcurses/notcurses.h");
  @cInclude("notcurses/nckeys.h");
  @cInclude("notcurses/ncport.h");
  @cInclude("notcurses/ncseqs.h");
  @cInclude("notcurses/version.h");
  @cUndef("_GNU_SOURCE");
});

test nc {
  const testing = std.testing;
  const win = nc.notcurses_init(null, nc.stdout).?;
  const err = nc.notcurses_stop(win);
  testing.expect(err == 0) catch unreachable;
}

const NotcursesErrors = error{
  InitError,
  StdPlaneIsNull,
  DeinitError,
};

  // const supported_styles = nc.notcurses_supported_styles(win);
  // const palette_size = nc.notcurses_palette_size(win);
  // const canfade = nc.notcurses_canfade(win);
  // const canchangecolor = nc.notcurses_canchangecolor(win);
  // const cantruecolor = nc.notcurses_cantruecolor(win);
  // _ = supported_styles | palette_size;
  // _ = canfade or canchangecolor or cantruecolor;

const NotcursesUI = struct {
  options: *Options.InterfaceOptions,

  const Self = @This();

  var ncStruct: ?*nc.struct_notcurses = null;
  var ncStdplane: ?*nc.struct_ncplane = null;

  fn init(ncOptions: ?*const nc.struct_notcurses_options) NotcursesErrors!void {
    ncStruct = nc.notcurses_init(ncOptions, nc.stdout) orelse return NotcursesErrors.InitError;
    ncStdplane = nc.notcurses_stdplane(ncStruct) orelse return NotcursesErrors.StdPlaneIsNull;
  }
  fn deinit() NotcursesErrors!void {
    if (nc.notcurses_stop(ncStruct) != 0) return NotcursesErrors.DeinitError;
  }


  fn print(self: *Self) !void{
    _ = self;
    const str: [*:0]const u8 = "Hi mann";

    _ = nc.ncplane_putstr(ncStdplane, str);
    _ = nc.notcurses_render(ncStruct);
    std.time.sleep(1000_000_000*1);
  }

  fn initWords() void{
  }

};

test {
  NotcursesUI.init(null) catch undefined;

  var options: Options.InterfaceOptions = .{.allocator = null, };
  var ui = NotcursesUI{&options};
  var bi = NotcursesUI{&options};

  bi.print() catch undefined;
  bi.print() catch undefined;
  bi.print() catch undefined;
  // ui.print() catch undefined;

  ui.deinit() catch undefined;
}

