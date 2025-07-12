const clay = @import("clay");
pub const cairo = @import("cairo");

extern fn Clay_Cairo_MeasureText(text: clay.String.Slice, config: *clay.TextElementConfig, user_data: ?*anyopaque) clay.Dimensions;
pub const measureText = Clay_Cairo_MeasureText;

extern fn Clay_Cairo_Initialize(cairo: *cairo.Context) void;
pub const initialize = Clay_Cairo_Initialize;

extern fn Clay_Cairo_Render(render_commands: clay.RenderCommandArray, fonts: [*c]const [*c]const u8) callconv(.C) void;
pub const render = Clay_Cairo_Render;
