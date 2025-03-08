const clay = @import("clay");
pub const cairo = @import("cairo");

// pub const measureText: *const clay.MeasureTextFn = @ptrCast(&c.Raylib_MeasureText);
extern fn Clay_Cairo_MeasureText(text: clay.String.Slice, config: *clay.TextElementConfig, user_data: ?*anyopaque) clay.Dimensions;
pub const measureText = Clay_Cairo_MeasureText;

// pub const initialize: *const fn (arg_width: c_int, arg_height: c_int, arg_title: [*c]const u8, arg_flags: c_uint) void = @ptrCast(&c.Clay_Raylib_Initialize);
extern fn Clay_Cairo_Initialize(arg_width: c_int, arg_height: c_int, arg_title: [*c]const u8, arg_flags: c_uint) void;
pub const initialize = Clay_Cairo_Initialize;

// pub const render: *const fn (render_commands: clay.RenderCommandArray, fonts: [*]raylib.Font) callconv(.C) void = @ptrCast(&c.Clay_Raylib_Render);
extern fn Clay_Cairo_Render(render_commands: clay.RenderCommandArray, fonts: [*]raylib.Font) callconv(.C) void;
pub const render = Clay_Cairo_Render;
