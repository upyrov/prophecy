const std = @import("std");

const raylib = @import("raylib");

const Node = @import("node.zig").Node;
const style = @import("style.zig");
const Constraints = style.Constraints;

/// Calculates the size of a node and its children based on styling and constraints.
/// Traverses the node tree from the bottom up (depth-first recursion),
/// calculating the size of each node based on its children and styling rules.
pub fn measure(node: *Node, constraints: *const Constraints) void {
    if (!node.is_dirty) return;

    const node_width = node.width.get();
    const node_height = node.height.get();

    var actual_node_width = node_width.getPoints(constraints.max_width);
    var actual_node_height = node_height.getPoints(constraints.max_height);

    const padding = node.padding.get().getPoints(0);

    // Create constraints for children.
    // The available space for children is this node's potential size minus its own padding.
    // If this node's size is 'auto', children get the parent's constraints.
    const child_constraints = Constraints{
        .max_width = if (node_width.is_auto()) constraints.max_width else actual_node_width - padding * 2,
        .max_height = if (node_height.is_auto()) constraints.max_height else actual_node_height - padding * 2,
        .min_width = 0,
        .min_height = 0,
    };

    // Measure children to determine content size
    var content_width: f32 = 0;
    var content_height: f32 = 0;
    var total_flex_grow: f32 = 0;

    if (node.text_content) |text| {
        const font_size = style.default_font_size;

        var buffer: [1024]u8 = undefined;
        const text_z = std.fmt.bufPrintZ(&buffer, "{s}", .{text}) catch "Error";

        const width_px = raylib.measureText(text_z, font_size);

        content_width = @as(f32, @floatFromInt(width_px));
        content_height = @as(f32, @floatFromInt(font_size));
    } else {
        for (node.children.items) |child| {
            measure(child, &child_constraints);
            total_flex_grow += child.flex_grow.get();

            const child_margin = child.margin.get().getPoints(0);
            const child_margin_w = child_margin * 2;
            const child_margin_h = child_margin * 2;

            switch (node.flex_direction.get()) {
                .column => {
                    content_width = @max(content_width, child.layout.width + child_margin_w);
                    content_height += child.layout.height + child_margin_h;
                },
                .row => {
                    content_width += child.layout.width + child_margin_w;
                    content_height = @max(content_height, child.layout.height + child_margin_h);
                },
            }
        }
    }

    // Distribute remaining space among children
    if (total_flex_grow > 0) {
        const remaining_w = child_constraints.max_width - content_width;
        const remaining_h = child_constraints.max_height - content_height;

        if (remaining_w > 0 and node.flex_direction.get() == .row) {
            for (node.children.items) |child| {
                const grow_ratio = child.flex_grow.get() / total_flex_grow;
                child.layout.width += remaining_w * grow_ratio;
            }
            content_width = child_constraints.max_width; // fills the content space
        }

        if (remaining_h > 0 and node.flex_direction.get() == .column) {
            for (node.children.items) |child| {
                const grow_ratio = child.flex_grow.get() / total_flex_grow;
                child.layout.height += remaining_h * grow_ratio;
            }
            content_height = child_constraints.max_height;
        }
    }

    // Resolve this node's final 'auto' size
    if (node_width.is_auto()) {
        actual_node_width = content_width + padding * 2;
    }
    if (node_height.is_auto()) {
        actual_node_height = content_height + padding * 2;
    }

    node.layout.width = std.math.clamp(actual_node_width, constraints.min_width, constraints.max_width);
    node.layout.height = std.math.clamp(actual_node_height, constraints.min_height, constraints.max_height);
}

/// Sets the absolute x/y position of a node and its children.
/// Traverses the tree from the top down, placing each child node
/// relative to its parent based on the sizes calculated in the `measure` pass.
pub fn position(node: *Node, x: f32, y: f32) void {
    // Set our own absolute position
    node.layout.x = x;
    node.layout.y = y;

    const padding = node.padding.get().getPoints(0);

    // Calculate total size of children and available space
    var total_child_width: f32 = 0;
    var total_child_height: f32 = 0;
    for (node.children.items) |child| {
        const margin = child.margin.get().getPoints(0);
        total_child_width += child.layout.width + margin * 2;
        total_child_height += child.layout.height + margin * 2;
    }

    const available_width = node.layout.width - padding * 2;
    const available_height = node.layout.height - padding * 2;

    var free_space_main_axis: f32 = 0;
    switch (node.flex_direction.get()) {
        .column => free_space_main_axis = available_height - total_child_height,
        .row => free_space_main_axis = available_width - total_child_width,
    }

    // Determine starting position and spacing from justify content
    var initial_offset: f32 = 0;
    var spacing: f32 = 0;
    const child_count: f32 = @floatFromInt(node.children.items.len);

    switch (node.justify_content.get()) {
        // Initial offset and spacing are zero
        .start => {},
        .end => initial_offset = free_space_main_axis,
        .center => initial_offset = free_space_main_axis / 2.0,
        .spaceBetween => if (child_count > 1) {
            spacing = free_space_main_axis / (child_count - 1);
        },
        .spaceAround => if (child_count > 0) {
            spacing = free_space_main_axis / child_count;
            initial_offset = spacing / 2.0;
        },
    }

    // Position children
    var cursor_main = initial_offset;

    for (node.children.items) |child| {
        const margin = child.margin.get().getPoints(0);
        var child_x: f32 = 0;
        var child_y: f32 = 0;

        // Align on cross axis using align_items
        switch (node.flex_direction.get()) {
            .column => {
                // Main axis is Y, cross axis is X
                var cross_offset: f32 = 0;
                const child_width_with_margin = child.layout.width + margin * 2;
                switch (node.align_items.get()) {
                    .start => {},
                    .end => cross_offset = available_width - child_width_with_margin,
                    .center => cross_offset = (available_width - child_width_with_margin) / 2.0,
                    .stretch => {
                        if (child.width.get().is_auto()) {
                            child.layout.width = available_width - margin * 2;
                        }
                    },
                }
                child_x = x + padding + margin + cross_offset;
                child_y = y + padding + margin + cursor_main;
                cursor_main += child.layout.height + margin * 2 + spacing;
            },
            .row => {
                // Main axis is X, cross axis is Y
                var cross_offset: f32 = 0;
                const child_height_with_margin = child.layout.height + margin * 2;
                switch (node.align_items.get()) {
                    .start => {},
                    .end => cross_offset = available_height - child_height_with_margin,
                    .center => cross_offset = (available_height - child_height_with_margin) / 2.0,
                    .stretch => {
                        if (child.height.get().is_auto()) {
                            child.layout.height = available_height - margin * 2;
                        }
                    },
                }
                child_x = x + padding + margin + cursor_main;
                child_y = y + padding + margin + cross_offset;
                cursor_main += child.layout.width + margin * 2 + spacing;
            },
        }

        position(child, child_x, child_y);
    }

    node.is_dirty = false;
}
