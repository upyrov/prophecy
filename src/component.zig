const std = @import("std");

const element = @import("element.zig");
const Element = element.Element;
const engine = @import("engine.zig");
const Signal = @import("signal.zig").Signal;
const style = @import("style.zig");

const Options = struct {
    style: style.Style = .{},
    ref: ?**Element = null,
};

fn applyOptions(e: *Element, options: Options) void {
    if (options.ref) |ref| {
        ref.* = e;
    }
    e.node.width.set(options.style.width);
    e.node.height.set(options.style.height);
    e.node.padding.set(options.style.padding);
    e.node.margin.set(options.style.margin);
    e.node.flex_direction.set(options.style.flex_direction);
    e.node.justify_content.set(options.style.justify_content);
    e.node.align_items.set(options.style.align_items);
    e.node.flex_grow.set(options.style.flex_grow);
}

pub const Root = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    element: *Element,
    width: f32,
    height: f32,

    pub fn init(allocator: std.mem.Allocator, e: *Element, width: f32, height: f32) Self {
        return .{
            .allocator = allocator,
            .element = e,
            .width = width,
            .height = height,
        };
    }

    pub fn deinit(self: *Self) void {
        self.element.deinit();
    }

    pub fn layout(self: *Self) void {
        const constraints = style.Constraints{
            .max_width = self.width,
            .max_height = self.height,
            .min_width = 0,
            .min_height = 0,
        };
        engine.measure(self.element.node, &constraints);
        engine.position(self.element.node, 0, 0);
    }

    /// Traverses the element tree and call a drawing callback.
    fn drawElementTree(e: *Element, callback: *const fn (e: *Element) void) void {
        callback(e);
        for (e.children.items) |child| {
            drawElementTree(child, callback);
        }
    }

    /// Traverses the element tree and calls a provided callback function for each element.
    /// This allows external renderers to draw the UI without the Self knowing about them.
    pub fn draw(self: *Self, callback: *const fn (e: *Element) void) void {
        drawElementTree(self.element, callback);
    }
};

pub fn Box(allocator: std.mem.Allocator, children: []const *Element, options: Options) !*Element {
    const e = try Element.init(allocator, .generic);
    for (children) |child| {
        try e.appendChild(child);
    }
    applyOptions(e, options);
    return e;
}

pub fn Text(allocator: std.mem.Allocator, content: []const u8, options: Options) !*Element {
    const e = try Element.init(allocator, .{ .text = .{ .content = content } });
    e.node.text_content = e.kind.text.content;
    applyOptions(e, options);
    return e;
}

/// A reusable Button component that encapsulates its own state and appearance.
pub const Button = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    hovered: Signal(bool),
    pressed: Signal(bool),
    root: *Element,

    pub fn init(allocator: std.mem.Allocator, text: []const u8) !*Self {
        const self = try allocator.create(Self);

        self.* = .{
            .allocator = allocator,
            .hovered = Signal(bool).init(false, self, onStateChange),
            .pressed = Signal(bool).init(false, self, onStateChange),
            .root = undefined,
        };

        _ = try Box(
            allocator,
            &.{
                try Text(allocator, text, .{}),
            },
            .{
                .ref = &self.root,
                .style = .{
                    .width = .{ .points = 120 },
                    .height = .{ .points = 40 },
                    .margin = .{ .points = 10 },
                    .justify_content = .center,
                    .align_items = .center,
                },
            },
        );

        onStateChange(self);
        return self;
    }

    pub fn getRoot(self: *Self) *Element {
        return self.root;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }

    fn onStateChange(context: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(context));
        const node = self.root.node;

        if (self.pressed.get()) {
            node.padding.set(.{ .points = 5 });
        } else if (self.hovered.get()) {
            node.padding.set(.{ .points = 2 });
        } else {
            node.padding.set(.{ .points = 0 });
        }
    }
};
