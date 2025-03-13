const std = @import("std");
pub const cdef = @import("cdef.zig");

pub const renderers = @import("renderers.zig");

pub usingnamespace @import("id.zig");

/// Clay's representation of non owning string slices, and includes
/// a baseChars field which points to the string this slice is derived from.
pub const String = extern struct {
    len: i32,
    ptr: [*]const u8,

    /// Slice/substring of a String. The pointer to the original string is included as `orig`.
    pub const Slice = extern struct {
        len: i32,
        ptr: [*]const u8,
        orig: [*]const u8,

        pub fn fromSlice(slice: []const u8) Slice {
            return .{
                .len = slice.len,
                .ptr = slice.ptr,
            };
        }

        pub fn asSlice(self: Slice) []const u8 {
            return @ptrCast(self.ptr[0..@intCast(self.len)]);
        }
    };

    pub fn fromSlice(slice: []const u8) String {
        return .{
            .len = @intCast(slice.len),
            .ptr = slice.ptr,
        };
    }

    pub fn asSlice(self: String) []const u8 {
        return @ptrCast(self.ptr[0..@intCast(self.len)]);
    }
};

test String {
    try std.testing.expectEqualStrings("asdf", String.fromSlice("asdf").asSlice());
}

pub const Context = opaque {
    pub fn init(allocator: std.mem.Allocator, layout_dimensions: Dimensions, error_handler: @import("errors.zig").ErrorHandler) !*Context {
        const arena = try Arena.initMin(allocator);
        errdefer arena.deinit(allocator);

        return cdef.Clay_Initialize(
            arena,
            layout_dimensions,
            error_handler,
        );
    }

    pub fn deinit(self: *const Context, allocator: std.mem.Allocator) void {
        defer if (getCurrent() == self) cdef.Clay_SetCurrentContext(null);

        // HACK: There does not seem to be an official way to free the context...
        //       So, let's employ a magic number! :D
        const internal_arena_offset = 152; // TODO: this number must be updated whenever `Clay_Context` implementation is changed.
        // TODO: please please please remember to rewrite this as soon as a proper way is available
        @as(*const Arena, @alignCast(@ptrCast(&@as([*]const u8, @ptrCast(self))[internal_arena_offset]))).deinit(allocator);
    }

    pub const SavedContext = struct {
        saved: ?*Context,

        pub fn restore(saved: SavedContext) void {
            cdef.Clay_SetCurrentContext(saved.saved);
        }
    };

    pub fn swapCurrent(self: *Context) SavedContext {
        defer self.setCurrent();

        return .{ .saved = getCurrent() };
    }

    pub fn setCurrent(self: *Context) void {
        cdef.Clay_SetCurrentContext(@ptrCast(self));
    }

    pub fn getCurrent() ?*Context {
        return @ptrCast(cdef.Clay_GetCurrentContext());
    }

    pub fn isHovered(self: *Context) void {
        const saved = self.swapCurrent();
        defer saved.restore();

        return cdef.Clay_Hovered();
    }

    pub fn setOnHover(self: *Context, onHoverFn: *const OnHoverFn, user_data: ?*anyopaque) void {
        const saved = self.swapCurrent();
        defer saved.restore();

        return cdef.Clay_OnHover(onHoverFn, user_data);
    }

    pub fn isPointerOver(self: *Context, element_id: ElementId) bool {
        const saved = self.swapCurrent();
        defer saved.restore();

        return cdef.Clay_PointerOver(element_id);
    }
};

test Context {
    const ctx = try Context.init(std.testing.allocator, .{ .height = 1080, .width = 1920 }, .{});
    defer ctx.deinit(std.testing.allocator);
}

/// A memory arena structure that is used by clay to manage its internal allocations.
pub const Arena = extern struct {
    next_allocation: usize, // uintptr
    capacity: usize,
    memory: [*]u8,

    pub fn initMin(allocator: std.mem.Allocator) !Arena {
        return initBuf(try allocator.alloc(u8, @intCast(cdef.Clay_MinMemorySize())));
    }

    pub fn initBuf(buf: []u8) Arena {
        return cdef.Clay_CreateArenaWithCapacityAndMemory(@intCast(buf.len), buf.ptr);
    }

    pub fn deinit(self: Arena, allocator: std.mem.Allocator) void {
        allocator.free(self.memory[0..self.capacity]);
    }
};

test Arena {
    const arena = try Arena.initMin(std.testing.allocator);
    defer arena.deinit(std.testing.allocator);
}

pub const Dimensions = extern struct {
    width: f32 = 0,
    height: f32 = 0,
};

pub const Vector2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
};

/// Internally clay conventionally represents colors as 0-255, but interpretation is up to the renderer.
pub const Color = extern struct {
    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,
    a: f32 = 0,

    pub const black: Color = rgb(0, 0, 0);
    pub const white: Color = rgb(255, 255, 255);
    pub const red: Color = rgb(255, 0, 0);
    pub const green: Color = rgb(0, 255, 0);
    pub const blue: Color = rgb(0, 0, 255);
    pub const transparent: Color = .{};

    pub inline fn rgb(r: f32, g: f32, b: f32) Color {
        return rgba(r, g, b, 255);
    }

    pub inline fn rgba(r: f32, g: f32, b: f32, a: f32) Color {
        return .{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
    }
};

pub const BoundingBox = extern struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn contains(self: BoundingBox, pt: Vector2) bool {
        return self.x <= pt.x and pt.x <= self.x + self.width and self.y <= pt.y and pt.y <= self.y + self.height;
    }
};

/// Primarily created via the CLAY_ID(), CLAY_IDI(), CLAY_ID_LOCAL() and CLAY_IDI_LOCAL() macros.
/// Represents a hashed string ID used for identifying and finding specific clay UI elements, required
/// by functions such as Clay_PointerOver() and Clay_GetElementData().
pub const ElementId = extern struct {
    /// The resulting hash generated from the other fields.
    id: u32 = 0,
    /// A numerical offset applied after computing the hash from stringId.
    offset: u32 = 0,
    /// A base hash value to start from, for example the parent element ID is used when calculating CLAY_ID_LOCAL().
    base_id: u32 = 0,
    /// The string id to hash.
    string_id: String = .{ .len = 0, .ptr = undefined },

    pub usingnamespace @import("id.zig");
};

/// Controls the "radius", or corner rounding of elements, including rectangles, borders and images.
/// The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
pub const CornerRadius = extern struct {
    top_left: f32 = 0,
    top_right: f32 = 0,
    bottom_left: f32 = 0,
    bottom_right: f32 = 0,

    pub fn all(width: f32) CornerRadius {
        return .{
            .top_left = width,
            .top_right = width,
            .bottom_left = width,
            .bottom_right = width,
        };
    }
};

/// Controls the direction in which child elements will be automatically laid out.
pub const LayoutDirection = enum(u8) {
    /// (Default) Lays out child elements from left to right with increasing x.
    left_to_right,
    /// Lays out child elements from top to bottom with increasing y.
    top_to_bottom,
};

/// Controls the alignment along the x axis (horizontal) of child elements.
pub const LayoutAlignmentX = enum(u8) {
    /// (Default) Aligns child elements to the left hand side of this element, offset by padding.width.left
    left,
    /// Aligns child elements to the right hand side of this element, offset by padding.width.right
    right,
    /// Aligns child elements horizontally to the center of this element
    center,
};

/// Controls the alignment along the y axis (vertical) of child elements.
pub const LayoutAlignmentY = enum(u8) {
    /// (Default) Aligns child elements to the top of this element, offset by padding.width.top
    top,
    /// Aligns child elements to the bottom of this element, offset by padding.width.bottom
    bottom,
    /// Aligns child elements vertiically to the center of this element
    center,
};

/// Controls how child elements are aligned on each axis.
pub const ChildAlignment = extern struct {
    /// Controls alignment of children along the x axis.
    x: LayoutAlignmentX = .left,

    /// Controls alignment of children along the y axis.
    y: LayoutAlignmentY = .top,

    pub const top_left: ChildAlignment = .{};
    pub const top_center: ChildAlignment = .{ .x = .center };
    pub const top_right: ChildAlignment = .{ .x = .right };
    pub const center_left: ChildAlignment = .{ .y = .center };
    pub const center_center: ChildAlignment = .{ .x = .center, .y = .center };
    pub const center_right: ChildAlignment = .{ .x = .right, .y = .center };
    pub const bottom_left: ChildAlignment = .{ .y = .bottom };
    pub const bottom_center: ChildAlignment = .{ .x = .center, .y = .bottom };
    pub const bottom_right: ChildAlignment = .{ .x = .right, .y = .bottom };

    pub const left_top = top_left;
    pub const left_center = center_left;
    pub const left_bottom = bottom_left;

    pub const right_top = top_right;
    pub const right_center = center_right;
    pub const right_bottom = bottom_right;

    pub const center = center_center;
};

/// Controls the sizing of this element inside its parent container.
pub const Sizing = extern struct {
    /// Controls how the element takes up space inside its parent container.
    pub const Type = enum(u8) {
        /// (default) Wraps tightly to the size of the element's contents.
        fit,

        /// Expands along this axis to fill available space in the parent element, sharing it with other GROW elements.
        grow,

        /// Expects 0-1 range. Clamps the axis size to a percent of the parent container's axis size minus padding and child gaps.
        percent,

        /// Clamps the axis size to an exact size in pixels.
        fixed,

        pub const default: Type = .fit;
    };

    /// Controls the minimum and maximum size in pixels that this element is allowed to grow or shrink to,
    /// overriding sizing types such as FIT or GROW.
    pub const MinMax = extern struct {
        /// The smallest final size of the element on this axis will be this value in pixels.
        min: f32 = 0,

        /// The largest final size of the element on this axis will be this value in pixels.
        max: f32 = std.math.floatMax(f32),
    };

    /// Controls how the element takes up space inside its parent container.
    pub const Axis = extern struct {
        size: extern union {
            min_max: MinMax,
            percent: f32,
        },
        type: Type,

        pub fn fit(min_max: MinMax) Axis {
            return .{
                .type = .fit,
                .size = .{
                    .min_max = min_max,
                },
            };
        }

        pub fn grow(min_max: MinMax) Axis {
            return .{
                .type = .grow,
                .size = .{
                    .min_max = min_max,
                },
            };
        }

        pub fn percent(pct: f32) Axis {
            return .{
                .type = .percent,
                .size = .{
                    .percent = pct,
                },
            };
        }

        pub fn fixed(value: f32) Axis {
            return .{
                .type = .fixed,
                .size = .{
                    .min_max = .{
                        .min = value,
                        .max = value,
                    },
                },
            };
        }

        pub const default: Axis = .fit(.{});
    };

    /// Controls the width sizing of the element, along the x axis.
    width: Axis = .default,

    /// Controls the height sizing of the element, along the y axis.
    height: Axis = .default,

    fn both(axis: Axis) Sizing {
        return .{ .width = axis, .height = axis };
    }

    pub fn fit(min_max: MinMax) Sizing {
        return both(.fit(min_max));
    }

    pub fn grow(min_max: MinMax) Sizing {
        return both(.grow(min_max));
    }

    pub fn fixed(size: f32) Sizing {
        return both(.fixed(size));
    }

    /// Range between 0 - 1
    pub fn percent(pct: f32) Sizing {
        return both(.percent(pct));
    }
};

/// Controls "padding" in pixels, which is a gap between the bounding box of this element and where its children
/// will be placed.
pub const Padding = extern struct {
    left: u16 = 0,
    right: u16 = 0,
    top: u16 = 0,
    bottom: u16 = 0,

    pub fn all(padding: u16) Padding {
        return .{
            .left = padding,
            .right = padding,
            .top = padding,
            .bottom = padding,
        };
    }

    pub fn xy(x: u16, y: u16) Padding {
        return .{
            .left = x,
            .right = x,
            .top = y,
            .bottom = y,
        };
    }
};

/// Controls various settings that affect the size and position of an element, as well as the sizes and positions
/// of any child elements.
pub const LayoutConfig = extern struct {
    /// Controls the sizing of this element inside it's parent container, including FIT, GROW, PERCENT and FIXED sizing.
    sizing: Sizing = .{},
    /// Controls "padding" in pixels, which is a gap between the bounding box of this element and where its children will be placed.
    padding: Padding = .{},
    /// Controls the gap in pixels between child elements along the layout axis (horizontal gap for LEFT_TO_RIGHT, vertical gap for TOP_TO_BOTTOM).
    child_gap: u16 = 0,
    /// Controls how child elements are aligned on each axis.
    child_alignment: ChildAlignment = .{},
    /// Controls the direction in which child elements will be automatically laid out.
    layout_direction: LayoutDirection = .left_to_right,
};

/// Controls how wrapped lines of text are horizontally aligned within the outer text bounding box.
pub const TextAlignment = enum(u8) {
    /// (default) Horizontally aligns wrapped lines of text to the left hand side of their bounding box.
    left,
    /// Horizontally aligns wrapped lines of text to the center of their bounding box.
    center,
    /// Horizontally aligns wrapped lines of text to the right hand side of their bounding box.
    right,
};

/// Controls various functionality related to text elements.
pub const TextElementConfig = extern struct {
    /// Controls how text "wraps", that is how it is broken into multiple lines when there is insufficient horizontal space.
    pub const WrapMode = enum(u8) {
        /// (default) breaks on whitespace characters.
        words,
        /// Don't break on space characters, only on newlines.
        newlines,
        /// Disable text wrapping entirely.
        none,
    };

    /// The RGBA color of the font to render, conventionally specified as 0-255.
    text_color: Color,

    /// An integer transparently passed to Clay_MeasureText to identify the font to use.
    /// The debug view will pass fontId = 0 for its internal text.
    font_id: u16 = 0,

    /// Controls the size of the font. Handled by the function provided to Clay_MeasureText.
    font_size: u16,

    /// Controls extra horizontal spacing between characters. Handled by the function provided to Clay_MeasureText.
    letter_spacing: u16 = 0,

    /// Controls additional vertical space between wrapped lines of text.
    line_height: u16 = 0,

    /// Controls how text "wraps", that is how it is broken into multiple lines when there is insufficient horizontal space.
    /// CLAY_TEXT_WRAP_WORDS (default) breaks on whitespace characters.
    /// CLAY_TEXT_WRAP_NEWLINES doesn't break on space characters, only on newlines.
    /// CLAY_TEXT_WRAP_NONE disables wrapping entirely.
    wrap_mode: WrapMode = .words,

    /// Controls how wrapped lines of text are horizontally aligned within the outer text bounding box.
    /// CLAY_TEXT_ALIGN_LEFT (default) - Horizontally aligns wrapped lines of text to the left hand side of their bounding box.
    /// CLAY_TEXT_ALIGN_CENTER - Horizontally aligns wrapped lines of text to the center of their bounding box.
    /// CLAY_TEXT_ALIGN_RIGHT - Horizontally aligns wrapped lines of text to the right hand side of their bounding box.
    text_alignment: TextAlignment = .left,

    /// When set to true, clay will hash the entire text contents of this string as an identifier for its internal
    /// text measurement cache, rather than just the pointer and length. This will incur significant performance cost for
    /// long bodies of text.
    hash_string_contents: bool = false,
};

/// Controls various settings related to image elements.
pub const ImageElementConfig = extern struct {
    /// A transparent pointer used to pass image data through to the renderer.
    image_data: ?*anyopaque = null,
    /// The original dimensions of the source image, used to control aspect ratio.
    source_dimensions: Dimensions = .{ .width = 0, .height = 0 },
};

/// Controls where a floating element is offset relative to its parent element.
///
/// Note: see https://github.com/user-attachments/assets/b8c6dfaa-c1b1-41a4-be55-013473e4a6ce for a visual explanation.
pub const FloatingAttachPointType = enum(u8) {
    left_top,
    left_center,
    left_bottom,
    center_top,
    center_center,
    center_bottom,
    right_top,
    right_center,
    right_bottom,
};

/// Controls where a floating element is offset relative to its parent element.
pub const FloatingAttachPoints = extern struct {
    /// Controls the origin point on a floating element that attaches to its parent.
    element: FloatingAttachPointType = .left_top,
    /// Controls the origin point on the parent element that the floating element attaches to.
    parent: FloatingAttachPointType = .left_top,
};

/// Controls how mouse pointer events like hover and click are captured or passed through to elements underneath a floating element.
pub const PointerCaptureMode = enum(u8) {
    /// (default) "Capture" the pointer event and don't allow events like hover and click to pass through to elements underneath.
    capture,

    // parent,

    /// Transparently pass through pointer events like hover and click to elements underneath the floating element.
    passthrough,
};

/// Controls which element a floating element is "attached" to (i.e. relative offset from).
pub const FloatingAttachToElement = enum(u8) {
    /// (default) Disables floating for this element.
    none,
    /// Attaches this floating element to its parent, positioned based on the .attachPoints and .offset fields.
    parent,
    /// Attaches this floating element to an element with a specific ID, specified with the .parentId field. positioned based on the .attachPoints and .offset fields.
    element_with_id,
    /// Attaches this floating element to the root of the layout, which combined with the .offset field provides functionality similar to "absolute positioning".
    attach_to_root,
};

/// Controls various settings related to "floating" elements, which are elements that "float" above other elements, potentially overlapping their boundaries,
/// and not affecting the layout of sibling or parent elements.
pub const FloatingElementConfig = extern struct {
    offset: Vector2 = .{},
    expand: Dimensions = .{ .width = 0, .height = 0 },
    parent_id: u32 = 0,
    z_index: i16 = 0,
    attach_points: FloatingAttachPoints = .{},
    pointer_capture_mode: PointerCaptureMode = .capture,
    attach_to: FloatingAttachToElement = .none,
};

/// Controls various settings related to custom elements.
pub const CustomElementConfig = extern struct {
    /// A transparent pointer through which you can pass custom data to the renderer.
    ///
    /// Generates CUSTOM render commands.
    custom_data: ?*anyopaque = null,
};

/// Controls the axis on which an element switches to "scrolling", which clips the contents and allows scrolling in that direction.
pub const ScrollElementConfig = extern struct {
    /// Clip overflowing elements on the X axis and allow scrolling left and right.
    horizontal: bool = false,
    /// Clip overflowing elements on the YU axis and allow scrolling up and down.
    vertical: bool = false,
};

/// Controls the widths of individual element borders.
pub const BorderWidth = extern struct {
    left: u16 = 0,
    right: u16 = 0,
    top: u16 = 0,
    bottom: u16 = 0,

    /// Creates borders between each child element, depending on the .layout_direction.
    ///
    /// e.g. for LEFT_TO_RIGHT, borders will be vertical lines, and for TOP_TO_BOTTOM borders will be horizontal lines.
    /// .between_children borders will result in individual RECTANGLE render commands being generated.
    between_children: u16 = 0,

    pub fn outside(width: u16) BorderWidth {
        return .{
            .left = width,
            .right = width,
            .top = width,
            .bottom = width,
            .between_children = 0,
        };
    }

    pub fn all(width: u16) BorderWidth {
        return .{
            .left = width,
            .right = width,
            .top = width,
            .bottom = width,
            .between_children = width,
        };
    }
};

/// Controls settings related to element borders.
pub const BorderElementConfig = extern struct {
    /// Controls the color of all borders with width > 0. Conventionally represented as 0-255, but interpretation is up to the renderer.
    color: Color = .{},
    /// Controls the widths of individual borders. At least one of these should be > 0 for a BORDER render command to be generated.
    width: BorderWidth = .{},
};

pub const RenderCommand = union(enum(u8)) {
    pub const Rectangle = extern struct {
        pub const RenderData = extern struct {
            /// The solid background color to fill this rectangle with. Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
            background_color: Color,

            /// Controls the "radius", or corner rounding of elements, including rectangles, borders and images.
            /// The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
            corner_radius: CornerRadius,
        };

        /// A rectangular box that fully encloses this UI element, with the position relative to the root of the layout.
        bounding_box: BoundingBox,
        render_data: RenderData,
        /// // A pointer transparently passed through from the original element declaration.
        user_data: ?*anyopaque,
        /// The id of this element, transparently passed through from the original element declaration.
        id: u32,
        /// The z order required for drawing this command correctly.
        /// Note: the render command array is already sorted in ascending order, and will produce correct results if drawn in naive order.
        /// This field is intended for use in batching renderers for improved performance.
        z_index: i16,
    };

    pub const Border = extern struct {
        pub const RenderData = extern struct {
            /// Controls a shared color for all this element's borders.
            /// Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
            color: Color,
            /// Specifies the "radius", or corner rounding of this border element.
            /// The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
            corner_radius: CornerRadius,
            /// Controls individual border side widths.
            width: BorderWidth,
        };

        /// A rectangular box that fully encloses this UI element, with the position relative to the root of the layout.
        bounding_box: BoundingBox,
        render_data: RenderData,
        /// // A pointer transparently passed through from the original element declaration.
        user_data: ?*anyopaque,
        /// The id of this element, transparently passed through from the original element declaration.
        id: u32,
    };

    pub const Text = extern struct {
        pub const RenderData = extern struct {
            /// A string slice containing the text to be rendered.
            string_contents: String.Slice,
            /// Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
            text_color: Color,
            /// An integer representing the font to use to render this text, transparently passed through from the text declaration.
            font_id: u16,
            font_size: u16,
            /// Specifies the extra whitespace gap in pixels between each character.
            letter_spacing: u16,
            /// The height of the bounding box for this line of text.
            line_height: u16,
        };

        /// A rectangular box that fully encloses this UI element, with the position relative to the root of the layout.
        bounding_box: BoundingBox,
        render_data: RenderData,
        /// // A pointer transparently passed through from the original element declaration.
        user_data: ?*anyopaque,
        /// The id of this element, transparently passed through from the original element declaration.
        id: u32,

        /// The z order required for drawing this command correctly.
        /// Note: the render command array is already sorted in ascending order, and will produce correct results if drawn in naive order.
        /// This field is intended for use in batching renderers for improved performance.
        z_index: i16,
    };

    pub const Image = extern struct {
        pub const RenderData = extern struct {
            /// The tint color for this image. Note that the default value is 0,0,0,0 and should likely be interpreted
            /// as "untinted".
            /// Conventionally represented as 0-255 for each channel, but interpretation is up to the renderer.
            background_color: Color,
            /// Controls the "radius", or corner rounding of this image.
            /// The rounding is determined by drawing a circle inset into the element corner by (radius, radius) pixels.
            corner_radius: CornerRadius,
            /// The original dimensions of the source image, used to control aspect ratio.
            source_dimensions: Dimensions,
            /// A pointer transparently passed through from the original element definition, typically used to represent image data.
            image_data: ?*anyopaque,
        };

        /// A rectangular box that fully encloses this UI element, with the position relative to the root of the layout.
        bounding_box: BoundingBox,
        render_data: RenderData,
        /// // A pointer transparently passed through from the original element declaration.
        user_data: ?*anyopaque,
        /// The id of this element, transparently passed through from the original element declaration.
        id: u32,
    };

    pub const ScissorStart = extern struct {
        pub const RenderData = extern struct {
            horizontal: bool,
            vertical: bool,
        };

        /// A rectangular box that fully encloses this UI element, with the position relative to the root of the layout.
        bounding_box: BoundingBox,
        render_data: RenderData,
        /// // A pointer transparently passed through from the original element declaration.
        user_data: ?*anyopaque,
        /// The id of this element, transparently passed through from the original element declaration.
        id: u32,
    };

    pub const ScissorEnd = extern struct {
        /// The id of this element, transparently passed through from the original element declaration.
        id: u32,
    };

    pub const Custom = extern struct {
        pub const RenderData = extern struct {
            background_color: Color,
            corner_radius: CornerRadius,
            custom_data: ?*anyopaque,
        };

        /// A rectangular box that fully encloses this UI element, with the position relative to the root of the layout.
        bounding_box: BoundingBox,
        render_data: RenderData,
        /// // A pointer transparently passed through from the original element declaration.
        user_data: ?*anyopaque,
        /// The id of this element, transparently passed through from the original element declaration.
        id: u32,
    };

    /// This command type should be skipped.
    none,
    /// The renderer should draw a solid color rectangle.
    rectangle: Rectangle,
    /// The renderer should draw a colored border inset into the bounding box.
    border: Border,
    /// The renderer should draw text.
    text: Text,
    /// The renderer should draw an image.
    image: Image,
    /// The renderer should begin clipping all future draw commands, only rendering content that falls within the provided boundingBox.
    scissor_start: ScissorStart,
    /// The renderer should finish any previously active clipping, and begin rendering elements in full again.
    scissor_end: ScissorEnd,
    /// The renderer should provide a custom implementation for handling this render command based on its .customData
    custom: Custom,
};

/// A sized array of render commands.
pub const RenderCommandArray = extern struct {
    cap: i32,
    len: i32,
    ptr: [*]cdef.RenderCommand,

    pub fn asSlice(self: RenderCommandArray) []cdef.RenderCommand {
        return self.ptr[0..@intCast(self.len)];
    }

    /// WARNING: this function destructively overwrites the underlying memory, invalidating the `RenderCommandArray`
    pub fn toZig(self: RenderCommandArray) []RenderCommand {
        const out: [*]RenderCommand = @ptrCast(self.ptr);
        var len: usize = @intCast(self.len);
        if (comptime @sizeOf(RenderCommand) <= @sizeOf(cdef.RenderCommand)) {
            for (0..len) |k| {
                out[k] = self.ptr[k].toZig();
            }
        } else {
            if (self.cap * @sizeOf(cdef.RenderCommand) < self.len * @sizeOf(RenderCommand)) {
                std.debug.print("emitting capacity exceeded error", .{});
                // artificially force a `elements_capacity_exceeded` error to be emitted
                for (0..@as(usize, @intCast(self.cap - self.len + 1))) |_| {
                    @extern(*const fn (cdef.RenderCommand) callconv(.C) void, .{ .name = "Clay__AddRenderCommand" })(comptime std.mem.zeroes(cdef.RenderCommand));
                }
            }

            // quietly drop commands that don't fit
            len = @min(@as(usize, @intCast(self.cap)) * @sizeOf(cdef.RenderCommand) / @sizeOf(RenderCommand), @as(usize, len));
            for (0..len) |k| {
                // transform backwards so data that we still need isn't overwritten
                const i = len - k - 1;
                out[i] = self.ptr[i].toZig();
            }
        }

        return out[0..len];
    }
};

fn testRenderCommandArrayToZigErrored(expect_error: bool) !void {
    var errored = false;
    const ctx = try Context.init(std.testing.allocator, .{ .width = 1920, .height = 1080 }, .{
        .handler = struct {
            fn handleError(data: @import("errors.zig").ErrorData) callconv(.C) void {
                const b: *bool = @ptrCast(data.user_data);
                if (!b.* and data.error_type == .elements_capacity_exceeded) {
                    b.* = true;
                }
            }
        }.handleError,
        .user_data = @ptrCast(&errored),
    });
    defer ctx.deinit(std.testing.allocator);

    const cmds = layout()({
        ui()(.{
            .border = .{
                .width = BorderWidth.all(1),
                .color = Color.black,
            },
        })({});
    });

    try std.testing.expectEqual(@as(usize, @intFromBool(!expect_error)), cmds.toZig().len);

    try std.testing.expect(errored == expect_error);
}

test "RenderCommandArray.toZig fits" {
    const default_max_element_count = blk: {
        // HACK: A current context is required to get max element count
        //       Also, deinit will clear the max element count wtf
        const ctx = try Context.init(std.testing.allocator, .{ .width = 1920, .height = 1080 }, .{});
        defer ctx.deinit(std.testing.allocator);

        break :blk getMaxElementCount();
    };
    defer setMaxElementCount(default_max_element_count); // reset to default

    try testRenderCommandArrayToZigErrored(false);

    setMaxElementCount(2);

    try testRenderCommandArrayToZigErrored(false);
}

test "RenderCommandArray.toZig does not fit" {
    const default_max_element_count = blk: {
        // HACK: A current context is required to get max element count
        //       Also, deinit will clear the max element count wtf
        const ctx = try Context.init(std.testing.allocator, .{ .width = 1920, .height = 1080 }, .{});
        defer ctx.deinit(std.testing.allocator);

        break :blk getMaxElementCount();
    };
    defer setMaxElementCount(default_max_element_count); // reset to default

    setMaxElementCount(1);

    try testRenderCommandArrayToZigErrored(true);
}

/// Data representing the current internal state of a scrolling element.
pub const ScrollContainerData = extern struct {
    /// Note: This is a pointer to the real internal scroll position, mutating it may cause a change in final layout.
    /// Intended for use with external functionality that modifies scroll position, such as scroll bars or auto scrolling.
    scroll_position: *Vector2,
    /// The bounding box of the scroll element.
    scroll_container_dimensions: Dimensions,
    /// The outer dimensions of the inner scroll container content, including the padding of the parent scroll container.
    content_dimensions: Dimensions,
    /// The config that was originally passed to the scroll element.
    config: ScrollElementConfig,
};

/// Bounding box and other data for a specific UI element.
pub const ElementData = extern struct {
    /// The rectangle that encloses this UI element, with the position relative to the root of the layout.
    bounding_box: BoundingBox,
};

/// Represents the current state of interaction with clay this frame.
pub const PointerDataInteractionState = enum(u8) {
    /// A left mouse click, or touch occurred this frame.
    pressed_this_frame,
    /// The left mouse button click or touch happened at some point in the past, and is still currently held down this frame.
    pressed,
    /// The left mouse button click or touch was released this frame.
    released_this_frame,
    /// The left mouse button click or touch is not currently down / was released at some point in the past.
    released,
};

/// Information on the current state of pointer interactions this frame.
pub const PointerData = extern struct {
    /// The position of the mouse / touch / pointer relative to the root of the layout.
    position: Vector2,
    /// Represents the current state of interaction with clay this frame.
    state: PointerDataInteractionState,
};

pub const ElementDeclaration = extern struct {
    /// Primarily created via the CLAY_ID(), CLAY_IDI(), CLAY_ID_LOCAL() and CLAY_IDI_LOCAL() macros.
    /// Represents a hashed string ID used for identifying and finding specific clay UI elements, required by functions such as Clay_PointerOver() and Clay_GetElementData().
    id: ElementId = .{},
    /// Controls various settings that affect the size and position of an element, as well as the sizes and positions of any child elements.
    layout: LayoutConfig = .{},
    /// Controls the background color of the resulting element.
    /// By convention specified as 0-255, but interpretation is up to the renderer.
    /// If no other config is specified, .backgroundColor will generate a RECTANGLE render command, otherwise it will be passed as a property to IMAGE or CUSTOM render commands.
    background_color: Color = .{},
    /// Controls the "radius", or corner rounding of elements, including rectangles, borders and images.
    corner_radius: CornerRadius = .{},
    /// Controls settings related to image elements.
    image: ImageElementConfig = .{},
    /// Controls whether and how an element "floats", which means it layers over the top of other elements in z order, and doesn't affect the position and size of siblings or parent elements.
    floating: FloatingElementConfig = .{},
    /// Used to create CUSTOM render commands, usually to render element types not supported by Clay.
    custom: CustomElementConfig = .{},
    /// Controls whether an element should clip its contents and allow scrolling rather than expanding to contain them.
    scroll: ScrollElementConfig = .{},
    /// Controls settings related to element borders, and will generate BORDER render commands.
    border: BorderElementConfig = .{},
    /// A pointer that will be transparently passed through to resulting render commands.
    user_data: ?*anyopaque = null,
};

pub usingnamespace @import("errors.zig");

/// Alternate syntax to beginLayout/endLayout. Works the same way as element declaration.
pub inline fn layout() fn (void) callconv(.Inline) RenderCommandArray {
    beginLayout();
    return layoutBody;
}

inline fn layoutBody(_: void) RenderCommandArray {
    return endLayout();
}

pub const beginLayout = cdef.Clay_BeginLayout;

pub const endLayout = cdef.Clay_EndLayout;

/// Opens a generic empty container, that is configurable and supports nested children.
///
/// ```
/// // Define an element with 16px of x and y padding
/// clay.ui()(.{
///     .id = clay.id("Outer"),
///     .layout = .{
///         .padding = .all(16),
///     },
/// })({
///     // A nested child element
///     clay.ui()(.{
///         .id = clay.id("SideBar"),
///         .layout = .{
///             .layout_direction = .top_to_bottom,
///             .child_gap = 16,
///         },
///     })({
///         // Children laid out top to bottom with a 16 px gap between them
///     });
///
///     // A vertical scrolling container with a colored background
///     CLAY({
///         .layout = {
///             .layout_direction = .top_to_bottom,
///             .child_gap = 16,
///         },
///         .background_color = .rgb(200, 200, 100),
///         .corner_radius = .all(10),
///         .scroll = {
///             .vertical = true,
///         },
///     })({
///         // child elements
///     });
/// });
/// ```
///
/// this needs to be a separate step from `elementConfig` or else `clay.isHovered()` does not work in the config declaration.
pub inline fn ui() @TypeOf(elementConfig) {
    cdef.internal.Clay__OpenElement();
    return elementConfig;
}

inline fn elementConfig(config: ElementDeclaration) @TypeOf(elementBody) {
    cdef.internal.Clay__ConfigureOpenElement(config);
    return elementBody;
}

inline fn elementBody(_: void) void {
    cdef.internal.Clay__CloseElement();
}

pub fn text(s: []const u8, config: *const TextElementConfig) void {
    cdef.internal.Clay__OpenTextElement(String.fromSlice(s), config);
}

pub fn string(s: []const u8) String {
    return String.fromSlice(s);
}

pub const OnHoverFn = fn (element_id: ElementId, pointer_data: PointerData, user_data: ?*anyopaque) callconv(.C) void;
pub const MeasureTextFn = fn (text: String.Slice, config: *TextElementConfig, user_data: ?*anyopaque) callconv(.C) Dimensions;
pub const QueryScrollOffsetFn = fn (element_id: u32, user_data: ?*anyopaque) callconv(.C) Vector2;

/// Sets the state of the "pointer" (i.e. the mouse or touch) in Clay's internal data. Used for detecting and responding to mouse events in the debug view,
/// as well as for Clay_Hovered() and scroll element handling.
pub const setPointerState = cdef.Clay_SetPointerState;

/// Updates the state of Clay's internal scroll data, updating scroll content positions if scrollDelta is non zero, and progressing momentum scrolling.
/// - enableDragScrolling when set to true will enable mobile device like "touch drag" scroll of scroll containers, including momentum scrolling after the touch has ended.
/// - scrollDelta is the amount to scroll this frame on each axis in pixels.
/// - deltaTime is the time in seconds since the last "frame" (scroll update)
pub const updateScrollContainers = cdef.Clay_UpdateScrollContainers;

/// Updates the layout dimensions in response to the window or outer container being resized.
pub const setLayoutDimensions = cdef.Clay_SetLayoutDimensions;

/// Returns layout data such as the final calculated bounding box for an element with a given ID.
/// The returned Clay_ElementData contains a `found` bool that will be true if an element with the provided ID was found.
/// This ID can be calculated either with CLAY_ID() for string literal IDs, or Clay_GetElementId for dynamic strings.
pub fn getElementData(element_id: ElementId) ?ElementData {
    const data = cdef.Clay_GetElementData(element_id);
    if (!data.found) {
        return null;
    }

    return data.toZig();
}

/// Returns true if the pointer position provided by Clay_SetPointerState is within the current element's bounding box.
/// Works during element declaration, e.g. CLAY({ .backgroundColor = Clay_Hovered() ? BLUE : RED });
pub const isHovered = cdef.Clay_Hovered;

// Bind a callback that will be called when the pointer position provided by Clay_SetPointerState is within the current element's bounding box.
// - onHoverFunction is a function pointer to a user defined function.
// - userData is a pointer that will be transparently passed through when the onHoverFunction is called.
pub const isPointerOver = cdef.Clay_PointerOver;

/// Returns data representing the state of the scrolling element with the provided ID.
/// The returned Clay_ScrollContainerData contains a `found` bool that will be true if a scroll element was found with the provided ID.
/// An imperative function that returns true if the pointer position provided by Clay_SetPointerState is within the element with the provided ID's bounding box.
/// This ID can be calculated either with CLAY_ID() for string literal IDs, or Clay_GetElementId for dynamic strings.
pub fn getScrollContainerData(element_id: ElementId) ?ScrollContainerData {
    const data = cdef.Clay_GetScrollContainerData(element_id);
    if (!data.found) {
        return null;
    }

    return data.toZig();
}

/// Binds a callback function that Clay will call to determine the dimensions of a given string slice.
/// - measureTextFunction is a user provided function that adheres to the interface Clay_Dimensions (Clay_StringSlice text, Clay_TextElementConfig *config, void *userData);
/// - userData is a pointer that will be transparently passed through when the measureTextFunction is called.
pub const setMeasureTextFunction = cdef.Clay_SetMeasureTextFunction;

/// Experimental - Used in cases where Clay needs to integrate with a system that manages its own scrolling containers externally.
/// Please reach out if you plan to use this function, as it may be subject to change.
pub const setQueryScrollOffsetFunction = cdef.Clay_SetQueryScrollOffsetFunction;

/// Enables and disables Clay's internal debug tools.
/// This state is retained and does not need to be set each frame.
pub const setDebugModeEnabled = cdef.Clay_SetDebugModeEnabled;

/// Returns true if Clay's internal debug tools are currently enabled.
pub const isDebugModeEnabled = cdef.Clay_IsDebugModeEnabled;

/// Alias for `isDebugModeEnabled`
pub const getDebuggingModeEnabled = isDebugModeEnabled;

/// Enables and disables visibility culling. By default, Clay will not generate render commands for elements whose bounding box is entirely outside the screen.
pub const setCullingEnabled = cdef.Clay_SetCullingEnabled;

/// Returns the maximum number of UI elements supported by Clay's current configuration.
pub const getMaxElementCount = cdef.Clay_GetMaxElementCount;

/// Modifies the maximum number of UI elements supported by Clay's current configuration.
/// This may require reallocating additional memory, and re-calling Clay_Initialize();
pub const setMaxElementCount = cdef.Clay_SetMaxElementCount;

/// Returns the maximum number of measured "words" (whitespace seperated runs of characters) that Clay can store in its internal text measurement cache.
pub const getMaxMeasureTextCacheWordCount = cdef.Clay_GetMaxMeasureTextCacheWordCount;

/// Modifies the maximum number of measured "words" (whitespace seperated runs of characters) that Clay can store in its internal text measurement cache.
/// This may require reallocating additional memory, and re-calling Clay_Initialize();
pub const setMaxMeasureTextCacheWordCount = cdef.Clay_SetMaxMeasureTextCacheWordCount;

/// Resets Clay's internal text measurement cache, useful if memory to represent strings is being re-used.
/// Similar behaviour can be achieved on an individual text element level by using Clay_TextElementConfig.hashStringContents
pub const resetMeasureTextCache = cdef.Clay_ResetMeasureTextCache;
