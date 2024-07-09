const std = @import("std");

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
  testing.expect(err == 0);
}

const InterfaceErrors = error{
  InitError,
  DeinitError,
};

pub fn getNotcursesUI(ncOptions :*const nc.notcurses_options) InterfaceErrors!type {
  const ncStruct = nc.notcurses_init(ncOptions, nc.stdout) orelse return error.InitError;
  const ncStdplane = nc.notcurses_stdplane(ncStruct);

  // const supported_styles = nc.notcurses_supported_styles(win);
  // const palette_size = nc.notcurses_palette_size(win);
  // const canfade = nc.notcurses_canfade(win);
  // const canchangecolor = nc.notcurses_canchangecolor(win);
  // const cantruecolor = nc.notcurses_cantruecolor(win);
  // _ = supported_styles | palette_size;
  // _ = canfade or canchangecolor or cantruecolor;

  return struct {
    print: type,
    fn print() !void{
      const str: [*:0]const u8 = "Hi mann";

      _ = nc.ncplane_putstr(ncStdplane, str);
      _ = nc.notcurses_render(ncStruct);

      std.time.sleep(1000_000_000*2);
    }

    fn initWords() void{
    }

    fn deinit() InterfaceErrors!void {
      if (nc.notcurses_stop(ncStruct) != 0) return error.DeinitError;
    }
  };
}

