This is my take on the zig bindings for clay.

The goals are to be as zig-idiomatic as possible, while being as close as possible to the original clay syntax and naming.

In general, all symbols that are originally prefixed with `Clay_` are translated to `clay.`. All symbols prefixed with `clay.` are optimized for zig-idiomicity, but may not all be bit-compatible with their C counter parts, most notably `clay.RenderCommand` and `clay.String`. In such cases, the bit-incompatible type will have a `asSlice()` (for `clay.String` and `clay.RenderCommandArray`) or a `toZig()` (for `clay.RenderCommand`, `clay.ScrollContainerData`, and `clay.ElementData`) helper method for converting to the zig-optimized variants, and a `fromSlice()` or  a`fromZig()` helper method for converting to the c-compatible variants.
