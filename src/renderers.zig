const options = @import("options");

pub const raylib = if (options.renderers.raylib) @import("clay-renderer-raylib") else @compileError("raylib renderer not enabled");
pub const cairo = if (options.renderers.cairo) @import("clay-renderer-cairo") else @compileError("cairo renderer not enabled");
