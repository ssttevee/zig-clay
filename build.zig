const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const enable_renderer_raylib = b.option(bool, "enable_renderer_raylib", "Enable the raylib renderer") orelse true;
    const enable_renderer_cairo = b.option(bool, "enable_renderer_cairo", "Enable the cairo renderer") orelse false;

    const options = b.addOptions();
    options.addOption(bool, "enable_renderer_raylib", enable_renderer_raylib);
    options.addOption(bool, "enable_renderer_cairo", enable_renderer_cairo);

    const clay = b.dependency("clay", .{});

    const clay_impl_c = b.addWriteFiles().add("clay.c",
        \\#define CLAY_IMPLEMENTATION
        \\#include<clay.h>
    );

    const clay_module = b.addModule("clay", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/root.zig"),
    });

    clay_module.addOptions("options", options);
    clay_module.addIncludePath(clay.path(""));
    clay_module.addCSourceFile(.{ .file = clay_impl_c });

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib_unit_tests.root_module.addOptions("options", options);
    lib_unit_tests.addIncludePath(clay.path(""));
    lib_unit_tests.addCSourceFile(.{ .file = clay_impl_c });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    if (enable_renderer_raylib) {
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
            lib_unit_tests.root_module.addImport("clay-renderer-raylib", raylib_module);
            lib_unit_tests.root_module.addImport("raylib", raylib_module);

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

    if (enable_renderer_cairo) {
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
            cairo_renderer_module.addCSourceFile(.{
                .file = b.addWriteFiles().add("cairo-renderer.c",
                    \\#include "clay.h"
                    \\#include "renderers/cairo/clay_renderer_cairo.c"
                    \\Clay_Dimensions Clay_Raylib_MeasureText(Clay_StringSlice text, Clay_TextElementConfig *config, void *userData) {
                    \\    return Raylib_MeasureText(text, config, userData);
                    \\};
                ),
            });
            cairo_renderer_module.addIncludePath(clay.path(""));
            cairo_renderer_module.addImport("clay", clay_module);
            cairo_renderer_module.addImport("cairo", cairo_module);
            clay_module.addImport("clay-renderer-cairo", cairo_renderer_module);
            lib_unit_tests.root_module.addImport("clay-renderer-cairo", cairo_module);
            lib_unit_tests.root_module.addImport("cairo", cairo_module);

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
