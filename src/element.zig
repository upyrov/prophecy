const std = @import("std");

const Node = @import("node.zig").Node;

pub const Element = struct {
    const Self = @This();
    const Kind = union(enum) {
        generic,
        text: struct {
            content: []const u8,
        },
    };

    allocator: std.mem.Allocator,
    node: *Node,
    kind: Kind,
    children: std.ArrayList(*Self),
    ref: ?**Self = null,

    pub fn init(allocator: std.mem.Allocator, kind: Kind) !*Self {
        const self = try allocator.create(Self);
        const node = try Node.init(allocator);

        self.* = .{
            .allocator = allocator,
            .node = node,
            .kind = kind,
            .children = std.ArrayList(*Self){},
            .ref = null,
        };

        return self;
    }

    pub fn deinit(self: *Self) void {
        for (self.children.items) |child| {
            child.deinit();
        }
        self.children.deinit(self.allocator);

        self.node.children.deinit(self.allocator);
        self.allocator.destroy(self.node);
        self.allocator.destroy(self);
    }

    pub fn appendChild(self: *Self, child: *Self) !void {
        try self.children.append(self.allocator, child);
        try self.node.appendChild(child.node);
    }
};
