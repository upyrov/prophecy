/// A tagged union representing a dimension that can be specified in points,
/// percent, or be automatically determined.
pub const Dimension = union(enum) {
    points: f32,
    percent: f32,
    auto: void,

    pub fn is_auto(self: Dimension) bool {
        return self == .auto;
    }

    /// Gets concrete float values from a Dimension.
    pub fn getPoints(self: Dimension, parent_dimension: f32) f32 {
        return switch (self) {
            .points => |p| p,
            .percent => |p| p * parent_dimension,
            .auto => 0,
        };
    }
};

pub const default_font_size: i32 = 16;

/// Defines the direction of the main axis for child nodes.
pub const FlexDirection = enum {
    column,
    row,
};

/// Defines how children are aligned along the main axis.
pub const JustifyContent = enum {
    start,
    end,
    center,
    /// Distribute children evenly, with the first child at the start and the last at the end.
    spaceBetween,
    /// Distribute children evenly, with equal space around each child.
    spaceAround,
};

/// Defines how children are aligned along the cross axis.
pub const AlignItems = enum {
    start,
    end,
    center,
    /// Stretch children to fill the container's cross axis.
    stretch,
};

pub const Constraints = struct {
    max_width: f32,
    max_height: f32,
    min_width: f32,
    min_height: f32,
};

/// The final computed geometry of a node after layout calculation.
pub const Geometry = struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
};

pub const Style = struct {
    width: Dimension = .auto,
    height: Dimension = .auto,
    padding: Dimension = .auto,
    margin: Dimension = .auto,
    flex_direction: FlexDirection = .column,
    justify_content: JustifyContent = .start,
    align_items: AlignItems = .stretch,
    flex_grow: f32 = 0.0,
};
