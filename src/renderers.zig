const options = @import("options");

pub const raylib = if (options.enable_renderer_raylib) @import("clay-renderer-raylib") else @compileError("raylib renderer not enabled");
pub const cairo = if (options.enable_renderer_cairo) @import("clay-renderer-cairo") else @compileError("cairo renderer not enabled");
