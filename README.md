# Prophecy

A reactive UI engine for Zig, designed around flexible layouts and signal-based state.

## Examples

Here are some examples to get you started:

### Basic Structure

```zig
// The tree is built declaratively by passing children as a slice
const app = try prophecy.Box(allocator, &.{
    // Text elements display static strings
    try prophecy.Text(allocator, "Hello Prophecy", .{}),
    
    // You can nest Boxes to create complex layouts
    try prophecy.Box(allocator, &.{
        try prophecy.Text(allocator, "Inner Content", .{})
    }, .{})
}, .{});
```

### Styling and Layout

```zig
// Prophecy uses a Flexbox-inspired layout engine.
// Styles are defined using a simple struct.
try prophecy.Box(allocator, children, .{
    .style = .{
        .width = .{ .percent = 1.0 },
        .height = .{ .points = 60 },
        
        // Layout controls how children are arranged
        .flex_direction = .row,
        .justify_content = .spaceBetween,
        .align_items = .center,
        
        // Spacing is handled via padding and margins
        .padding = .{ .points = 10 },
        .margin = .{ .points = 5 },
    }
});
```

### Reactivity

> [!WARNING]
> Prophecy is currently in an experimental phase. Core APIs are subject to significant changes.
>
> The current signal implementation is technically not a "true" reactive signal with automatic dependency tracking. Expect this system to be refactored in future updates.

```zig
// We use signals to manage state.
// Signals notify their listeners automatically when changed.
var counter = prophecy.Signal(i32).init(0, null, null);

// You can update the signal from anywhere in your code
counter.set(42);
```

### Reusable Components

```zig
// Components are just Zig structs that manage their own element tree
const MyButton = struct {
    root: *prophecy.Element,

    pub fn init(allocator: std.mem.Allocator, text: []const u8) !*Self {
        const self = try allocator.create(Self);
        // Initialize the internal element tree
        self.root = try prophecy.Text(allocator, text, .{
            .style = .{ .padding = .{ .points = 10 } }
        });
        return self;
    }

    // Expose the root element so parents can render it
    pub fn getRoot(self: *Self) *prophecy.Element {
        return self.root;
    }
};
```


## License

Mova is distributed under the terms of [MIT License](./LICENSE).
