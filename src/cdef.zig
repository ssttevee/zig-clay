const std = @import("std");
const clay = @import("root.zig");

pub const RenderCommand = extern struct {
    bounding_box: clay.BoundingBox,
    render_data: extern union {
        rectangle: clay.RenderCommand.Rectangle.RenderData,
        text: clay.RenderCommand.Text.RenderData,
        image: clay.RenderCommand.Image.RenderData,
        custom: clay.RenderCommand.Custom.RenderData,
        border: clay.RenderCommand.Border.RenderData,
        scroll: clay.RenderCommand.ScissorStart.RenderData,
    },
    user_data: ?*anyopaque,
    id: u32,
    z_index: i16,
    command_type: std.meta.Tag(clay.RenderCommand),

    pub fn toZig(self: RenderCommand) clay.RenderCommand {
        return switch (self.command_type) {
            .none => .none,
            .rectangle => .{
                .rectangle = .{
                    .bounding_box = self.bounding_box,
                    .render_data = self.render_data.rectangle,
                    .user_data = self.user_data,
                    .id = self.id,
                    .z_index = self.z_index,
                },
            },
            .border => .{
                .border = .{
                    .bounding_box = self.bounding_box,
                    .render_data = self.render_data.border,
                    .user_data = self.user_data,
                    .id = self.id,
                },
            },
            .text => .{
                .text = .{
                    .bounding_box = self.bounding_box,
                    .render_data = self.render_data.text,
                    .user_data = self.user_data,
                    .id = self.id,
                    .z_index = self.z_index,
                },
            },
            .image => .{
                .image = .{
                    .bounding_box = self.bounding_box,
                    .render_data = self.render_data.image,
                    .user_data = self.user_data,
                    .id = self.id,
                },
            },
            .scissor_start => .{
                .scissor_start = .{
                    .bounding_box = self.bounding_box,
                    .render_data = self.render_data.scroll,
                    .user_data = self.user_data,
                    .id = self.id,
                },
            },
            .scissor_end => .{
                .scissor_end = .{
                    .id = self.id,
                },
            },
            .custom => .{
                .custom = .{
                    .bounding_box = self.bounding_box,
                    .render_data = self.render_data.custom,
                    .user_data = self.user_data,
                    .id = self.id,
                },
            },
        };
    }
};

pub const ScrollContainerData = extern struct {
    scroll_position: *clay.Vector2,
    scroll_container_dimensions: clay.Dimensions,
    content_dimensions: clay.Dimensions,
    config: clay.ScrollElementConfig,
    found: bool,

    pub fn toZig(self: ScrollContainerData) clay.ScrollContainerData {
        return .{
            .scroll_position = self.scroll_position,
            .scroll_container_dimensions = self.scroll_container_dimensions,
            .content_dimensions = self.content_dimensions,
            .config = self.config,
        };
    }
};

pub const ElementData = extern struct {
    bounding_box: clay.BoundingBox,
    found: bool,

    pub fn toZig(self: ElementData) clay.ElementData {
        return .{
            .bounding_box = self.bounding_box,
            .config = self.config,
        };
    }
};

// Public API functions ------------------------------------------

pub extern fn Clay_MinMemorySize() u32;
pub extern fn Clay_CreateArenaWithCapacityAndMemory(capacity: u32, memory: [*]u8) clay.Arena;
pub extern fn Clay_SetPointerState(position: clay.Vector2, pointer_down: bool) void;
pub extern fn Clay_Initialize(arena: clay.Arena, layout_dimensions: clay.Dimensions, error_handler: clay.ErrorHandler) *clay.Context;
pub extern fn Clay_GetCurrentContext() *clay.Context;
pub extern fn Clay_SetCurrentContext(context: ?*clay.Context) void;
pub extern fn Clay_UpdateScrollContainers(enable_drag_scrolling: bool, scroll_delta: clay.Vector2, delta_time: f32) void;
pub extern fn Clay_SetLayoutDimensions(dimensions: clay.Dimensions) void;
pub extern fn Clay_BeginLayout() void;
pub extern fn Clay_EndLayout() clay.RenderCommandArray;
pub extern fn Clay_GetElementId(id_string: clay.String) clay.ElementId;
pub extern fn Clay_GetElementIdWithIndex(id_string: clay.String, index: u32) clay.ElementId;
pub extern fn Clay_GetElementData(id: clay.ElementId) ElementData;
pub extern fn Clay_Hovered() bool;
pub extern fn Clay_OnHover(on_hover_fn: *const clay.OnHoverFn, user_data: ?*anyopaque) void;
pub extern fn Clay_PointerOver(element_id: clay.ElementId) bool;
pub extern fn Clay_GetScrollContainerData(element_id: clay.ElementId) ScrollContainerData;
pub extern fn Clay_SetMeasureTextFunction(measure_text_fn: *const clay.MeasureTextFn, user_data: ?*anyopaque) void;
pub extern fn Clay_SetQueryScrollOffsetFunction(query_scroll_offset_fn: *const clay.QueryScrollOffsetFn) void;
pub extern fn Clay_RenderCommandArray_Get(array: clay.RenderCommandArray, index: i32) *RenderCommand;
pub extern fn Clay_SetDebugModeEnabled(enabled: bool) void;
pub extern fn Clay_IsDebugModeEnabled() bool;
pub extern fn Clay_SetCullingEnabled(enabled: bool) void;
pub extern fn Clay_GetMaxElementCount() i32;
pub extern fn Clay_SetMaxElementCount(max_element_count: i32) void;
pub extern fn Clay_GetMaxMeasureTextCacheWordCount() i32;
pub extern fn Clay_SetMaxMeasureTextCacheWordCount(max_measure_text_cache_word_count: i32) void;
pub extern fn Clay_ResetMeasureTextCache() void;

// Internal API functions required by macros ----------------------

pub const internal = struct {
    pub extern fn Clay__OpenElement() void;
    pub extern fn Clay__ConfigureOpenElement(config: clay.ElementDeclaration) void;
    pub extern fn Clay__CloseElement() void;
    pub extern fn Clay__HashString(key: clay.String, offset: u32, seed: u32) clay.ElementId;
    pub extern fn Clay__OpenTextElement(text: clay.String, text_config: *const clay.TextElementConfig) void;
    pub extern fn Clay__StoreTextElementConfig(config: clay.TextElementConfig) *clay.TextElementConfig;
    pub extern fn Clay__GetParentElementId() u32;
};
