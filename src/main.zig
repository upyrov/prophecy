const std = @import("std");

const prophecy = @import("prophecy");
const Button = prophecy.Button;
const raylib = prophecy.raylib;

fn updateButtonState(button: *Button, mouse_x: f32, mouse_y: f32) void {
    const layout = button.getRoot().node.layout;

    // Check collision
    const is_hovered = mouse_x >= layout.x and
        mouse_x <= (layout.x + layout.width) and
        mouse_y >= layout.y and
        mouse_y <= (layout.y + layout.height);

    button.hovered.set(is_hovered);
    button.pressed.set(is_hovered and raylib.isMouseButtonDown(raylib.MouseButton.left));
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const screen_width: f32 = 800;
    const screen_height: f32 = 600;

    prophecy.renderer.initWindow(@as(i32, @intFromFloat(screen_width)), @as(i32, @intFromFloat(screen_height)), "Prophecy UI with Raylib");
    defer prophecy.renderer.closeWindow();

    const left_button = try Button.init(allocator, "Button 1");
    defer left_button.deinit();

    const right_button = try Button.init(allocator, "Button 2");
    defer right_button.deinit();

    const big_button = try Button.init(allocator, "BIG BUTTON");
    defer big_button.deinit();

    const footer_button = try Button.init(allocator, "Footer Button");
    defer footer_button.deinit();

    const app = try prophecy.Box(
        allocator,
        &.{
            // Header
            try prophecy.Box(
                allocator,
                &.{ left_button.getRoot(), right_button.getRoot() },
                .{ .style = .{
                    .height = .{ .points = 60 },
                    .width = .{ .percent = 1.0 },
                    .flex_direction = .row,
                    .justify_content = .spaceBetween,
                    .align_items = .center,
                    .padding = .{ .points = 10 },
                } },
            ),
            // Content
            try prophecy.Box(
                allocator,
                &.{big_button.getRoot()},
                .{ .style = .{
                    .width = .{ .percent = 1.0 },
                    .flex_grow = 1.0,
                    .justify_content = .center,
                    .align_items = .center,
                } },
            ),
            // Footer
            try prophecy.Box(
                allocator,
                &.{footer_button.getRoot()},
                .{ .style = .{
                    .height = .{ .points = 60 },
                    .width = .{ .percent = 1.0 },
                    .flex_direction = .row,
                    .justify_content = .center,
                    .align_items = .center,
                } },
            ),
        },
        .{
            .style = .{
                .width = .{ .percent = 1.0 },
                .height = .{ .percent = 1.0 },
                .padding = .{ .points = 10 },
                .flex_direction = .column,
            },
        },
    );

    var root = prophecy.Root.init(allocator, app, screen_width, screen_height);
    defer root.deinit();

    while (!prophecy.renderer.windowShouldClose()) {
        // Input handling
        const mouse_x = @as(f32, @floatFromInt(raylib.getMouseX()));
        const mouse_y = @as(f32, @floatFromInt(raylib.getMouseY()));

        // Update all buttons here
        updateButtonState(left_button, mouse_x, mouse_y);
        updateButtonState(right_button, mouse_x, mouse_y);
        updateButtonState(big_button, mouse_x, mouse_y);
        updateButtonState(footer_button, mouse_x, mouse_y);

        // Layout calculation
        root.layout();

        // Drawing
        prophecy.renderer.beginDrawing();
        root.draw(prophecy.renderer.drawElement);
        prophecy.renderer.endDrawing();
    }
}
