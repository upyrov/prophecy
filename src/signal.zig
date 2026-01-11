const std = @import("std");

pub fn Signal(comptime T: type) type {
    return struct {
        value: T,
        // Node pointer
        context: *anyopaque,
        // Callback function pointer
        on_change: *const fn (ctx: *anyopaque) void,

        const Self = @This();

        pub fn init(
            value: T,
            context: *anyopaque,
            on_change: *const fn (ctx: *anyopaque) void,
        ) Self {
            return .{ .value = value, .context = context, .on_change = on_change };
        }

        pub fn set(self: *Self, new_value: T) void {
            if (std.meta.eql(self.value, new_value)) return;

            self.value = new_value;
            self.on_change(self.context);
        }

        pub fn get(self: *Self) T {
            return self.value;
        }
    };
}
