const std = @import("std");

fn build_tests(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    build_options: *std.Build.Step.Options,
) void {
    _ = b;
    _ = target;
    _ = optimize;
    _ = build_options;
}
