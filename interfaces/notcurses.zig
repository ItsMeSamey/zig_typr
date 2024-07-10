const std = @import("std");
const Options = @import("options.zig");

/// Import the notcurses headers
pub const nc = @cImport({
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
  testing.expect(0 == nc.notcurses_stop(win)) catch unreachable;
}

/// Error union returned by nost functions
const NotcursesErrors = error{
  InitError,
  StdPlaneIsNull,
  ReparentFailed,
  PlaneCreationFailed,
  DeinitError,
};

  // const supported_styles = nc.notcurses_supported_styles(win);
  // const palette_size = nc.notcurses_palette_size(win);
  // const canfade = nc.notcurses_canfade(win);
  // const canchangecolor = nc.notcurses_canchangecolor(win);
  // const cantruecolor = nc.notcurses_cantruecolor(win);
  // _ = supported_styles | palette_size;
  // _ = canfade or canchangecolor or cantruecolor;

/// the main notcurses struct
var ncStruct: ?*nc.struct_notcurses = null;
/// The standard plane
var ncStdplane: ?*nc.struct_ncplane = null;

/// the Header Plane, to display typing speed/stats etc.
var ncHeaderPlane: ?*nc.struct_ncplane = null;
/// the Plance on which the words appear
var ncTypingPlane: ?*nc.struct_ncplane = null;

/// Initialize notcurses with given options
/// use null to Initialize with defaults
pub fn init(ncOptions: ?*const nc.struct_notcurses_options) NotcursesErrors!void {
  ncStruct = nc.notcurses_core_init(ncOptions, nc.stdout) orelse return NotcursesErrors.InitError;
  ncStdplane = nc.notcurses_stdplane(ncStruct) orelse return NotcursesErrors.StdPlaneIsNull;

  ncHeaderPlane = nc.ncplane_create(ncStdplane, &.{
    .y = 0, .x = 0,
    .rows = 1, .cols = 0,
    .margin_b = 0, .margin_r = 0,
    .name = null,
    .resizecb = null,
    .flags = nc.NCPLANE_OPTION_MARGINALIZED | nc.NCPLANE_OPTION_AUTOGROW,
  }) orelse return NotcursesErrors.PlaneCreationFailed;

  // ncHeaderPlane = nc.ncplane_reparent(ncHeaderPlane, ncHeaderPlane) orelse return NotcursesErrors.ReparentFailed;

  ncTypingPlane = nc.ncplane_create(ncStdplane, &.{
    .y = 1, .x = 0,
    .rows = 0, .cols = 0,
    .margin_b = 0, .margin_r = 0,
    .name = null,
    .resizecb = null,
    .flags = nc.NCPLANE_OPTION_MARGINALIZED | nc.NCPLANE_OPTION_VSCROLL,
  }) orelse return NotcursesErrors.PlaneCreationFailed;
}

/// Deinitialize notcurses, you must call this or terminal will be messed up
pub fn deinit() NotcursesErrors!void {
  if (nc.notcurses_stop(ncStruct) != 0) return NotcursesErrors.DeinitError;
}


pub const NotcursesUI = struct {
  options: *Options.InterfaceOptions,

  const Self = @This();

  pub fn print(self: *Self, str: [*:0]const u8) !void{
    _ = self;
    _ = str;
    if (0 != nc.ncplane_putstr(ncTypingPlane, "HI, Dude")) return ;
    _ = nc.ncpile_render(ncHeaderPlane);
    std.time.sleep(1000_000_000*1);
  }
};

test NotcursesUI {
  init(null) catch undefined;

  var options: Options.InterfaceOptions = .{.allocator = null, };
  var ui = NotcursesUI{&options};
  var bi = NotcursesUI{&options};

  try bi.print();

  std.testing.expect(0 == nc.ncplane_putstr(ncTypingPlane, "Hi mann"));
  std.testing.expect(0 == nc.notcurses_render(ncStruct));

  try ui.deinit();
}

