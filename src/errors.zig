const clay = @import("root.zig");

pub const ErrorType = enum(u8) {
    missing_text_measurement_function,
    arena_capacity_exceeded,
    elements_capacity_exceeded,
    text_measurement_capacity_exceeded,
    duplicate_id,
    floating_container_parent_not_found,
    percentage_over_one,
    internal_error,
};

pub const ErrorData = extern struct {
    error_type: ErrorType,
    error_text: clay.String,
    user_data: ?*anyopaque,
};

pub const ErrorHandler = extern struct {
    handler: ?*const fn (ErrorData) callconv(.C) void = null,
    user_data: ?*anyopaque = null,
};
