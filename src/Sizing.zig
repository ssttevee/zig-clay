//! Controls the sizing of this element along one axis inside its parent container.

const std = @import("std");
const cdef = @import("cdef.zig");

const Sizing = @This();

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
pub const Axis = union(Type) {
    /// (default) Wraps tightly to the size of the element's contents.
    fit: MinMax,

    /// Expands along this axis to fill available space in the parent element, sharing it with other GROW elements.
    grow: MinMax,

    /// Expects 0-1 range. Clamps the axis size to a percent of the parent container's axis size minus padding and child gaps.
    percent: f32,

    /// Clamps the axis size to an exact size in pixels.
    fixed: MinMax,

    pub const default: Axis = Axis.fit(.{});

    pub fn fit(min_max: MinMax) Axis {
        return .{ .fit = min_max };
    }

    pub fn grow(min_max: MinMax) Axis {
        return .{ .grow = min_max };
    }

    pub fn fixed(size: f32) Axis {
        return .{ .fixed = .{ .min = size, .max = size } };
    }

    /// Range between 0 - 1
    pub fn percent(pct: f32) Axis {
        return .{ .percent = std.math.clamp(pct, 0, 1) };
    }
};

/// Controls the width sizing of the element, along the x axis.
width: Axis = Axis.default,

/// Controls the height sizing of the element, along the y axis.
height: Axis = Axis.default,

fn both(axis: Axis) Sizing {
    return .{ .width = axis, .height = axis };
}

pub fn fit(min_max: MinMax) Sizing {
    return both(Axis.fit(min_max));
}

pub fn grow(min_max: MinMax) Sizing {
    return both(Axis.grow(min_max));
}

pub fn fixed(size: f32) Sizing {
    return both(Axis.fixed(size));
}

/// Range between 0 - 1
pub fn percent(pct: f32) Sizing {
    return both(Axis.percent(pct));
}
