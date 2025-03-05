const std = @import("std");
const cdef = @import("cdef.zig");
const clay = @import("root.zig");

/// copy/paste of Clay__HashString implementation to use in comptime
fn hashString(key: []const u8, offset: u32, seed: u32) clay.ElementId {
    var hash: u32 = 0;
    var base: u32 = seed;

    for (key) |c| {
        base +%= c;
        base +%= (base << 10);
        base ^= (base >> 6);
    }

    hash = base;
    hash +%= offset;
    hash +%= (hash << 10);
    hash ^= (hash >> 6);

    hash +%= (hash << 3);
    base +%= (base << 3);
    hash ^= (hash >> 11);
    base ^= (base >> 11);
    hash +%= (hash << 15);
    base +%= (base << 15);

    return .{
        .id = hash + 1,
        .offset = offset,
        .base_id = base + 1,
        .string_id = clay.String.fromSlice(key),
    };
}

fn testHashStringCorrectness(key: []const u8, offset: u32, seed: u32) !void {
    try std.testing.expectEqualDeep(cdef.internal.Clay__HashString(clay.String.fromSlice(key), offset, seed), hashString(key, offset, seed));
}

test hashString {
    try testHashStringCorrectness("asdf", 0, 0);
    try testHashStringCorrectness("asdf", 1, 0);
    try testHashStringCorrectness("asdf", 1, 1);
    try testHashStringCorrectness("asdf", 0, 1);

    try testHashStringCorrectness("foobar", 0, 0);
    try testHashStringCorrectness("foobar", 1, 0);
    try testHashStringCorrectness("foobar", 1, 1);
    try testHashStringCorrectness("foobar", 0, 1);

    try testHashStringCorrectness("hello", 0, 0);
    try testHashStringCorrectness("hello", 2, 0);
    try testHashStringCorrectness("hello", 2, 1);
    try testHashStringCorrectness("hello", 0, 1);
}

// NOTE TO READERS: the `CLAY_ID` family of macros all contain `CLAY__ENSURE_STRING_LITERAL`, which guarantees the
// string has static lifetime (i.e. address won't change and can't be freed/invalidated). This guarantee can be made
// using comptime, thus all the equivalent `id` family of functions below have a comptime requirement for the label.
//
// If you need an id from a runtime string, you can use one of the functions derived from `Clay_GetElementId` or
// `Clay_GetElementIdWithIndex`.

pub inline fn id(comptime label: []const u8) clay.ElementId {
    return idi(label, 0);
}

pub inline fn idi(comptime label: []const u8, index: u32) clay.ElementId {
    return hashString(label, index, 0);
}

pub inline fn idLocal(comptime label: []const u8) clay.ElementId {
    return idiLocal(label, 0);
}

pub inline fn idiLocal(comptime label: []const u8, index: u32) clay.ElementId {
    return hashString(label, index, cdef.internal.Clay__GetParentElementId());
}

pub inline fn getElementId(label: []const u8) clay.ElementId {
    return cdef.Clay_GetElementId(clay.String.fromSlice(label));
}

pub inline fn getElementIdWithIndex(label: []const u8, index: u32) clay.ElementId {
    return cdef.Clay_GetElementIdWithIndex(clay.String.fromSlice(label), index);
}
