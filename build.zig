const std = @import("std");
const StreamEditor = @import("build/StreamEditor.zig");

pub const Renderer = std.meta.FieldEnum(Renderers);

const Renderers = struct {
    raylib: bool,
    cairo: bool,

    pub fn fromSlice(renderers: []const Renderer) Renderers {
        var result: Renderers = std.mem.zeroes(Renderers);
        for (renderers) |renderer| {
            switch (renderer) {
                inline else => |tag| {
                    @field(result, @tagName(tag)) = true;
                },
            }
        }

        return result;
    }
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const renderers = Renderers.fromSlice(b.option([]const Renderer, "renderers", "List of renderers to enable (Defaults to all available renderers on your platform)") orelse std.enums.values(Renderer));

    const options = b.addOptions();
    options.addOption(Renderers, "renderers", renderers);

    const clay = b.dependency("clay", .{});

    const clay_module = b.addModule("clay", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/root.zig"),
    });

    clay_module.addOptions("options", options);
    clay_module.addCMacro("CLAY_IMPLEMENTATION", "");
    clay_module.addCSourceFile(.{ .file = b.addWriteFiles().addCopyFile(clay.path("clay.h"), "clay.c") });
    if (target.result.os.tag == .windows) {
        clay_module.addCMacro("CLAY_DISABLE_SIMD", "");
    }

    const lib_unit_tests = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_module = clay_module,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    if (renderers.raylib) {
        if (b.lazyDependency("raylib", .{
            .target = target,
            .optimize = optimize,
        })) |raylib| {
            const raylib_module = raylib.module("raylib");
            const raylib_renderer_module = b.addModule("clay-renderer-raylib", .{
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path("src/renderers/raylib.zig"),
            });
            raylib_renderer_module.addCSourceFile(.{
                .file = b.addWriteFiles().add("raylib-renderer.c",
                    \\#include "clay.h"
                    \\#include "renderers/raylib/clay_renderer_raylib.c"
                    \\Clay_Dimensions Clay_Raylib_MeasureText(Clay_StringSlice text, Clay_TextElementConfig *config, void *userData) {
                    \\    return Raylib_MeasureText(text, config, userData);
                    \\};
                ),
            });
            raylib_renderer_module.addIncludePath(clay.path(""));
            raylib_renderer_module.addImport("clay", clay_module);
            raylib_renderer_module.addImport("raylib", raylib_module);
            raylib_renderer_module.linkLibrary(raylib.artifact("raylib"));
            clay_module.addImport("clay-renderer-raylib", raylib_renderer_module);

            const example_raylib_sidebar_scrolling_container = b.addExecutable(.{
                .target = target,
                .optimize = optimize,
                .name = "raylib-sidebar-scrolling-container",
                .root_source_file = b.path("examples/raylib-sidebar-scrolling-container/main.zig"),
            });

            example_raylib_sidebar_scrolling_container.root_module.addImport("clay", clay_module);

            b.getInstallStep().dependOn(
                &b.addInstallArtifact(
                    example_raylib_sidebar_scrolling_container,
                    .{
                        .dest_sub_path = "examples/raylib-sidebar-scrolling-container",
                    },
                ).step,
            );
        }
    }

    if (renderers.cairo) {
        if (b.lazyDependency("cairo", .{
            .target = target,
            .optimize = optimize,
        })) |cairo| {
            const cairo_module = cairo.module("cairo");
            const cairo_renderer_module = b.addModule("clay-renderer-cairo", .{
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path("src/renderers/cairo.zig"),
            });

            const sed = StreamEditor.create(b);

            cairo_renderer_module.addCSourceFile(.{
                .file = sed.add(.{
                    .input_file = clay.path("renderers/cairo/clay_renderer_cairo.c"),
                    .expressions = &[_][]const u8{
                        "/CLAY_IMPLEMENTATION/d",
                        "s!\"../../clay.h\"!\"clay.h\"!g",
                        "s/static inline Clay_Dimensions/Clay_Dimensions/g",
                    },
                }),
            });
            cairo_renderer_module.addIncludePath(clay.path(""));
            cairo_renderer_module.addImport("clay", clay_module);
            cairo_renderer_module.addImport("cairo", cairo_module);
            clay_module.addImport("clay-renderer-cairo", cairo_renderer_module);

            const example_cairo_pdf_rendering = b.addExecutable(.{
                .target = target,
                .optimize = optimize,
                .name = "cairo-pdf-rendering",
                .root_source_file = b.path("examples/cairo-pdf-rendering/main.zig"),
            });

            example_cairo_pdf_rendering.root_module.addImport("clay", clay_module);

            b.getInstallStep().dependOn(
                &b.addInstallArtifact(
                    example_cairo_pdf_rendering,
                    .{
                        .dest_sub_path = "examples/cairo-pdf-rendering",
                    },
                ).step,
            );
        }
    }
}
