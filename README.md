# zig-clay

This is my take on zig bindings for [clay](https://github.com/nicbarker/clay), inspired by https://codeberg.org/Zettexe/clay-zig.

The goal is to be as zig-idiomatic as possible, while being as close as possible to the original clay syntax and naming.

In general, all symbols that are originally prefixed with `Clay_` are translated to `clay.`.

All symbols prefixed with `clay.` are optimized for zig-idiomaticity, but may not all be bit-compatible with their C counter parts. Most notably, `clay.RenderCommand` and `clay.String`. In such cases, the bit-incompatible type will have a `asSlice()` (for `clay.String` and `clay.RenderCommandArray`) or a `toZig()` (for `clay.RenderCommand`, `clay.ScrollContainerData`, and `clay.ElementData`) helper method for converting to the zig-optimized variants, and a `fromSlice()` or a `fromZig()` helper method for converting to the c-compatible variants.

## Using zig-clay in your own project

Run this command from your project folder

```sh
zig fetch --save git+https://github.com/nicbarker/clay.git#{commit hash to pin version}
```

Then add this snippet to your build.zig file

```zig
const clay = b.dependency("clay", .{
    .optimize = optimize,
    .target = target,
});

exe.root_module.addImport("clay", clay.module("clay"));
```

## Examples

Examples can be found in the `examples` folder.

## Renderers

Currently, only the raylib renderer bindings are available because it's the only library with a strong zig bindings package. If bindings for cairo or SDL become available, I'd be more than happy to add them.
