const std = @import("std");

const raylib = @import("raylib");

const Element = @import("element.zig").Element;
const default_font_size = @import("style.zig").default_font_size;

pub fn initWindow(width: i32, height: i32, title: [:0]const u8) void {
    raylib.initWindow(width, height, title);
    raylib.setTargetFPS(60);
}

pub fn closeWindow() void {
    raylib.closeWindow();
}

pub fn windowShouldClose() bool {
    return raylib.windowShouldClose();
}

pub fn beginDrawing() void {
    raylib.beginDrawing();
    raylib.clearBackground(raylib.Color.black);
}

pub fn endDrawing() void {
    raylib.endDrawing();
}

pub fn drawElement(e: *Element) void {
    const node = e.node;
    const layout = node.layout;

    if (e.kind == .generic) {
        // Draw background
        raylib.drawRectangle(
            @as(i32, @intFromFloat(layout.x)),
            @as(i32, @intFromFloat(layout.y)),
            @as(i32, @intFromFloat(layout.width)),
            @as(i32, @intFromFloat(layout.height)),
            raylib.Color.blue,
        );

        // Draw padding area
        const padding = node.padding.get().getPoints(0);
        if (padding > 0) {
            raylib.drawRectangle(
                @as(i32, @intFromFloat(layout.x + padding)),
                @as(i32, @intFromFloat(layout.y + padding)),
                @as(i32, @intFromFloat(layout.width - 2 * padding)),
                @as(i32, @intFromFloat(layout.height - 2 * padding)),
                raylib.Color.sky_blue,
            );
        }
    } else if (e.kind == .text) {
        const text_content = e.kind.text.content;
        const font_size = default_font_size;

        // Buffer for null-termination
        var buffer: [1024]u8 = undefined;
        const text_z = std.fmt.bufPrintZ(&buffer, "{s}", .{text_content}) catch "Error";

        // We calculate text width here to center it perfectly.
        // If you prefer Left Alignment, you can remove this measurement
        // and just use: text_x = layout.x + padding.
        const text_width = raylib.measureText(text_z, font_size);

        const text_x = layout.x + (layout.width - @as(f32, @floatFromInt(text_width))) / 2.0;
        const text_y = layout.y + (layout.height - @as(f32, @floatFromInt(font_size))) / 2.0;

        raylib.drawText(
            text_z,
            @as(i32, @intFromFloat(text_x)),
            @as(i32, @intFromFloat(text_y)),
            font_size,
            raylib.Color.white,
        );
    }
}

pub fn drawElementTree(e: *Element) void {
    drawElement(e);
    for (e.children.items) |child| {
        drawElementTree(child);
    }
}
