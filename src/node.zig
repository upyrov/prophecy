const std = @import("std");

const Signal = @import("signal.zig").Signal;
const style = @import("style.zig");

/// Each node has styling properties that define how it and its children are laid out.
/// These properties are reactive "Signals", meaning that changing them will automatically
/// mark the node and its ancestors as "dirty", triggering a recalculation of the layout.
pub const Node = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    parent: ?*Node = null,
    children: std.ArrayList(*Node),
    text_content: ?[]const u8 = null,

    // If it's dirty, this node and its children need their layout recalculated
    is_dirty: bool = true,

    // Sizing
    width: Signal(style.Dimension),
    height: Signal(style.Dimension),

    // Spacing
    padding: Signal(style.Dimension),
    margin: Signal(style.Dimension),

    // Flexbox properties
    flex_direction: Signal(style.FlexDirection),
    justify_content: Signal(style.JustifyContent),
    align_items: Signal(style.AlignItems),
    flex_grow: Signal(f32),

    /// The final computed position and size of the node. This is calculated by the layout engine.
    layout: style.Geometry = .{},

    /// Creates a new Node with default styling.
    pub fn init(allocator: std.mem.Allocator) !*Node {
        const node = try allocator.create(Node);

        node.* = .{
            .allocator = allocator,
            .children = std.ArrayList(*Node){},

            // Initialize all style signals with default values.
            // Whenever a signal's value is changed, the node will be marked for a layout update.
            .width = Signal(style.Dimension).init(.auto, node, markDirtyOpaque),
            .height = Signal(style.Dimension).init(.auto, node, markDirtyOpaque),
            .padding = Signal(style.Dimension).init(.auto, node, markDirtyOpaque),
            .margin = Signal(style.Dimension).init(.auto, node, markDirtyOpaque),
            .flex_direction = Signal(style.FlexDirection).init(.column, node, markDirtyOpaque),
            .justify_content = Signal(style.JustifyContent).init(.start, node, markDirtyOpaque),
            .align_items = Signal(style.AlignItems).init(.stretch, node, markDirtyOpaque),
            .flex_grow = Signal(f32).init(0.0, node, markDirtyOpaque),
        };

        return node;
    }

    /// Adds a child node to this node.
    pub fn appendChild(self: *Node, child: *Node) !void {
        child.parent = self;
        try self.children.append(self.allocator, child);
        self.markDirty();
    }

    /// Marks this node as dirty and recursively marks all of its parents as dirty.
    /// This ensures that the entire branch of the layout tree is recalculated when a
    /// property changes.
    pub fn markDirty(self: *Node) void {
        // If we're already dirty, our parents must be too, so we can stop
        if (self.is_dirty) return;

        self.is_dirty = true;

        // Bubble the dirty state up to the root of the tree
        if (self.parent) |p| p.markDirty();
    }

    /// A callback function used by the Signal system.
    /// It's a "type-erased" function that takes a context, which we know
    /// is a pointer to a Node. It casts the pointer back to the node and
    /// marks it as dirty.
    fn markDirtyOpaque(context: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(context));
        self.markDirty();
    }
};
