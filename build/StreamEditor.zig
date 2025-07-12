const std = @import("std");
const Step = std.Build.Step;
const StreamEditor = @This();

step: std.Build.Step,
jobs: std.ArrayListUnmanaged(Job) = .{},
generated_directory: std.Build.GeneratedFile,

pub const Job = struct {
    input_file: std.Build.LazyPath,
    expressions: []const []const u8,
    sub_path: []const u8,

    fn output_file(job: Job, sed: *StreamEditor) std.Build.LazyPath {
        return .{
            .generated = .{
                .file = &sed.generated_directory,
                .sub_path = job.sub_path,
            },
        };
    }
};

pub const base_id: Step.Id = .custom;

pub fn create(owner: *std.Build) *StreamEditor {
    const sed = owner.allocator.create(StreamEditor) catch @panic("OOM");
    sed.* = .{
        .step = Step.init(.{
            .id = base_id,
            .name = "StreamEditor",
            .owner = owner,
            .makeFn = make,
        }),
        .generated_directory = .{ .step = &sed.step },
    };
    return sed;
}

pub const JobConfig = struct {
    input_file: std.Build.LazyPath,
    expressions: []const []const u8,
    sub_path: ?[]const u8 = null,
};

pub fn add(sed: *StreamEditor, config: JobConfig) std.Build.LazyPath {
    switch (config.input_file) {
        .generated => |g| sed.step.dependOn(g.file.step),
        else => {},
    }

    const gpa = sed.step.owner.allocator;
    const job = sed.jobs.addOne(gpa) catch @panic("OOM");
    job.* = .{
        .input_file = config.input_file,
        .expressions = config.expressions,
        .sub_path = config.sub_path orelse std.fs.path.basename(switch (config.input_file) {
            .cwd_relative => |p| p,
            inline else => |p| p.sub_path,
        }),
    };
    return job.output_file(sed);
}

fn make(step: *Step, options: Step.MakeOptions) !void {
    _ = options;
    const b = step.owner;
    const gpa = b.allocator;
    const sed: *StreamEditor = @fieldParentPtr("step", step);

    var man = b.graph.cache.obtain();
    defer man.deinit();

    for (sed.jobs.items) |job| {
        const path = job.input_file.getPath3(b, step);
        _ = try man.addFilePath(path, null);
        try step.addWatchInput(job.input_file);

        man.hash.addBytes(job.sub_path);

        for (job.expressions) |expr| {
            man.hash.addBytes(expr);
        }
    }

    if (try step.cacheHit(&man)) {
        const digest = man.final();
        sed.generated_directory.path = try b.cache_root.join(gpa, &.{ "o", &digest });
        step.result_cached = true;
        return;
    }

    const digest = man.final();
    const cache_path = "o" ++ std.fs.path.sep_str ++ digest;

    sed.generated_directory.path = try b.cache_root.join(gpa, &.{ "o", &digest });

    var cache_dir = b.cache_root.handle.makeOpenPath(cache_path, .{}) catch |err| {
        return step.fail("unable to make path '{}{s}': {s}", .{
            b.cache_root, cache_path, @errorName(err),
        });
    };
    defer cache_dir.close();

    var argv: [][]const u8 = try gpa.alloc([]const u8, 1);
    defer gpa.free(argv);

    argv[0] = "sed";

    for (sed.jobs.items) |job| {
        const output_path = job.output_file(sed).getPath3(b, &sed.step);
        const output_file = try output_path.root_dir.handle.createFile(output_path.sub_path, .{});
        defer output_file.close();

        const argc = 2 + job.expressions.len * 2;
        if (argv.len < argc) {
            argv = try gpa.realloc(argv, argc);
        }

        for (job.expressions, 0..) |expr, i| {
            argv[1 + i * 2] = "-e";
            argv[1 + i * 2 + 1] = expr;
        }

        const input_path = job.input_file.getPath3(b, &sed.step);
        argv[argc - 1] = try input_path.toString(gpa);
        defer gpa.free(argv[argc - 1]);

        var child = std.process.Child.init(argv, gpa);
        child.stdin_behavior = .Close;
        child.stdout_behavior = .Pipe;

        try child.spawn();
        errdefer {
            _ = child.kill() catch {};
        }

        try child.waitForSpawn();

        const stdout = child.stdout orelse unreachable;

        var output_buf: [4096]u8 = undefined;

        while (true) {
            // flush remaining output bytes
            const m = try stdout.read(&output_buf);
            if (m == 0) {
                // done!
                break;
            }

            try output_file.writeAll(output_buf[0..m]);
        }

        try step.handleChildProcessTerm(try child.wait(), null, argv);
    }

    try step.writeManifest(&man);
}
