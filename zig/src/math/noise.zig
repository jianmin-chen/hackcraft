const std = @import("std");
const Float = @import("types.zig").Float;
const vector = @import("vector.zig");

const assert = std.debug.assert;

const Vec2Primitive = vector.Vec2Primitive;
const Vec2 = vector.Vec2;

const PERMUTATION_SIZE: usize = 255;
pub const PermutationTable = [PERMUTATION_SIZE * 2]usize; 

// Gradients, taken from Ken Perlin's "Improving Noise",
// with all the ones with no change (i.e. zero) in either direction removed.
const GRADIENTS = [_]Vec2Primitive{
    Vec2Primitive{1, 1},
    Vec2Primitive{-1, 1},
    Vec2Primitive{1, -1},
    Vec2Primitive{-1, -1}
};

pub fn permutations(seed: u64) PermutationTable {
    var perm: PermutationTable = [_]usize{0} ** (PERMUTATION_SIZE * 2);
    for (0..PERMUTATION_SIZE) |i| perm[i] = i;

    // Shuffle values using Fisher-Yates.
    var prng = std.rand.DefaultPrng.init(seed);
    const random = prng.random();
    var curr_i = PERMUTATION_SIZE - 1;
    while (curr_i > 0) : (curr_i -= 1)  {
        const rand_i: usize = @intFromFloat(std.math.floor(random.float(Float) * @as(Float, @floatFromInt(curr_i))));
        const swap = perm[rand_i];
        perm[rand_i] = perm[curr_i];
        perm[curr_i] = swap;
    }

    for (PERMUTATION_SIZE..PERMUTATION_SIZE * 2) |i| perm[i] = perm[i - PERMUTATION_SIZE];
    return perm;
}

fn fade(x: Float) Float {
    // smootherstep, taken from Ken Perlin's "Improving Noise".
    return 6 * std.math.pow(Float, x, 5) - 15 * std.math.pow(Float, x, 4) + 10 * std.math.pow(Float, x, 3);
}

fn lerp(min: Float, max: Float, x: Float) Float {
    return min * (1 - x) + max * x;
}

pub fn noise2D(x: Float, y: Float, permutation: PermutationTable) Float {
    const x_floored = std.math.floor(x);
    const y_floored = std.math.floor(y);

    // Gradients from the corners of the grid that point to [x, y].
    const tl = Vec2Primitive{x - x_floored, y - y_floored};
    const tr = Vec2Primitive{x - x_floored - 1, y - y_floored};
    const bl = Vec2Primitive{x - x_floored, y - y_floored - 1};
    const br = Vec2Primitive{x - x_floored - 1, y - y_floored - 1};

    // Wrap around values of x and y for lookup in permutation table.
    const hash_x = @as(usize, @intFromFloat(x_floored)) & PERMUTATION_SIZE;
    const hash_y = @as(usize, @intFromFloat(y_floored)) & PERMUTATION_SIZE;

    const tl_permutation = permutation[permutation[hash_x] + hash_y];
    const tr_permutation = permutation[permutation[hash_x + 1] + hash_y];
    const bl_permutation = permutation[permutation[hash_x] + hash_y + 1];
    const br_permutation = permutation[permutation[hash_x + 1] + hash_y + 1];

    // Random gradients for each of the corners.
    const tl_gradient = GRADIENTS[tl_permutation % GRADIENTS.len];
    const tr_gradient = GRADIENTS[tr_permutation % GRADIENTS.len];
    const bl_gradient = GRADIENTS[bl_permutation % GRADIENTS.len];
    const br_gradient = GRADIENTS[br_permutation % GRADIENTS.len];

    // Calculate the dot product, which effectively determines the influence of the corner gradient
    // on the value of the noise.
    const tl_dot = Vec2.dot(tl, tl_gradient);
    const tr_dot = Vec2.dot(tr, tr_gradient);
    const bl_dot = Vec2.dot(bl, bl_gradient);
    const br_dot = Vec2.dot(br, br_gradient);

    // Now we fade x and y,
    // and then interpolate them to the range between the corners,
    // giving us the noise.
    const fade_x = fade(x - x_floored);
    const top_lerp = lerp(tl_dot, tr_dot, fade_x);
    const bottom_lerp = lerp(bl_dot, br_dot, fade_x);
    return lerp(top_lerp, bottom_lerp, fade(y - y_floored));
}

// Wrap around noise2D to smooth out Perlin noise
// by averaging out a set of octaves.
//
// Also has options for starting frequency and amplitude,
// which affect our density and elevation respectively.
pub fn fbm2D(
    x: Float, 
    y: Float, 
    permutation: PermutationTable, 
    options: struct {
        octaves: u8 = 8,
        starting_frequency: Float = 0.005,
        starting_amplitude: Float = 1,
        delta_frequency: Float = 2,
        delta_amplitude: Float = 0.5
    }
) Float {
    var n: Float = 0;
    var frequency = options.starting_frequency;
    var amplitude = options.starting_amplitude;
    for (0..options.octaves) |_| {
        n += noise2D(x * frequency, y * frequency, permutation) * amplitude;
        frequency *= options.delta_frequency;
        amplitude *= options.delta_amplitude;
        assert(-1 < n and n < 1);
    }
    return n;
}
