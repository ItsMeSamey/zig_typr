//! The UI struct

const std = @import("std");

/// Import the notcurses headers
const noc = @cImport({
  @cDefine("_GNU_SOURCE", {});
  @cInclude("notcurses/notcurses.h");
  @cInclude("notcurses/nckeys.h");
  @cInclude("notcurses/ncport.h");
  @cInclude("notcurses/ncseqs.h");
  @cInclude("notcurses/version.h");
  @cUndef("_GNU_SOURCE");
});

/// Error union returned by nost functions
const NotcursesErrors = error{
  /// Initialization and stuff
  InitError,
  StdPlaneIsNull,

  /// Regarding everything in between
  PutstrError,
  RenderError,
  RasterizeError,

  /// Deinitialization and stuff
  DeinitError,
};

/// The main notcurses struct
var ncStruct: ?*noc.struct_notcurses = null;
/// The standard plane
var ncStdplane: ?*noc.struct_ncplane = null;

/// Initialize notcurses with given options
/// use null to Initialize with defaults
pub fn init(ncOptions: ?*const noc.struct_notcurses_options) NotcursesErrors!void {
  ncStruct = noc.notcurses_core_init(ncOptions, noc.stdout) orelse return NotcursesErrors.InitError;
  ncStdplane = noc.notcurses_stdplane(ncStruct) orelse return NotcursesErrors.StdPlaneIsNull;
}

/// Deinitialize notcurses, you must call this or terminal will be messed up
pub fn deinit() NotcursesErrors!void {
  if (noc.notcurses_stop(ncStruct) != 0) return NotcursesErrors.DeinitError;
}

pub fn print(str: [*:0]const u8) !void{
  if (0 > noc.ncplane_putstr(ncStdplane.?, str)) return NotcursesErrors.PutstrError;
  if (0 != noc.ncpile_render(ncStdplane.?)) return NotcursesErrors.RenderError;
  if (0 != noc.ncpile_rasterize(ncStdplane.?)) return NotcursesErrors.RasterizeError;
  std.time.sleep(1000_000_000);
}

test {
  std.debug.print("DONE",.{});

  try init(null);
  try print("Hi");
  try print("How are you");
  try print("Doing");
  try deinit();
}

