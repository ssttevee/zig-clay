const options = @import("options");

pub const raylib = if (options.enable_renderer_raylib) @import("clay-renderer-raylib") else @compileError("raylib renderer not enabled");
