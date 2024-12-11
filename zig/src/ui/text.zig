const c = @cImport({
    @cInclude("glad/glad.h");
});
const std = @import("std");
const Character = @import("../module/character.zig");
const math = @import("math");
const Shader = @import("shader");
const Texture = @import("texture.zig");

const Allocator = std.mem.Allocator;

const Characters = Character.Characters;

const Float = math.types.Float;

const Color = math.vector.Vec4(Float);

const Self = @This();

const vertex_shader = 
    \\#version 330 core
    \\
    \\layout (location = 0) in vec4 vertex;
    \\layout (location = 1) in vec4 position;
    \\layout (location = 2) in vec4 glyph;
    \\
    \\out vec2 tex_coord;
    \\
    \\uniform mat4 projection;
    \\
    \\void main() {
    \\  vec2 xy = vertex.xy * position.zw + position.xy;
    \\  gl_Position = projection * vec4(xy, 0.0, 1.0);
    \\}
;

const fragment_shader = 
    \\#version 330 core
    \\
    \\uniform sampler2D atlas;
    \\uniform vec2 background_color;
    \\uniform vec3 color;
    \\
    \\// in vec2 tex_coord;
    \\
    \\out vec4 out_color;
    \\
    \\void main() {
    \\  float alpha = texture(atlas, tex_coord).r;
    \\  out_color = vec4(color, alpha);
    \\}
;

const VERTEX_SIZE = 4;
const POSITION_SIZE = 4;
const GLYPH_SIZE = 4;
const INSTANCED_SIZE = POSITION_SIZE + GLYPH_SIZE;

const Text = struct {
    character_count: usize = 0,

    // Offset in buffer.
    start: usize = 0
};

allocator: Allocator,

shader: Shader,
atlas: c_uint,
characters: Characters,
quads: usize = 0,

vao: c_uint,
vbo: c_uint,
base_vbo: c_uint,
ebo: c_uint,

pub fn from(
    allocator: Allocator,
    options: struct {
        background_color: Color.Primitive = Color.Primitive{0, 0, 0, 0},
        color: Color.Primitive = Color.Primitive{1, 1, 1, 1}
    }
) !Self {
    // const atlas = try Texture.from(atlas_path);
    _ = allocator;

    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;
    var base_vbo: c_uint = undefined;
    var ebo: c_uint = undefined;

    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);
    c.glGenBuffers(1, &base_vbo);
    c.glGenBuffers(1, &ebo);

    c.glBindVertexArray(vao);

    // Base quad: 1x1 pixel covering entire atlas.
    const base_quad = [_]Float{
        0, 1, 0, 1, 
        0, 0, 0, 0,
        1, 0, 1, 0,
        1, 1, 1, 1
    };

    c.glBindBuffer(c.GL_ARRAY_BUFFER, base_vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @sizeOf(Float) * base_quad.len,
        @ptrCast(&base_quad[0]),
        c.GL_STATIC_DRAW
    );

    c.glVertexAttribPointer(
        0,
        VERTEX_SIZE,
        c.GL_FLOAT,
        c.GL_FALSE,
        @sizeOf(Float) * VERTEX_SIZE,
        null
    );

    c.glEnableVertexAttribArray(0);

    const indices = [_]c.GLuint{
        3, 1, 0,
        3, 2, 1
    };

    // Instanced rendering with a base set of vertices.
    // Our element buffer object is going to store indices
    // to the base set of vertices.
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(
        c.GL_ELEMENT_ARRAY_BUFFER,
        @sizeOf(c.GLuint) * indices.len,
        @ptrCast(&indices[0]),
        c.GL_STATIC_DRAW
    );

    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(
        c.GL_ARRAY_BUFFER,
        @sizeOf(Float) * INSTANCED_SIZE,
        null,
        c.GL_DYNAMIC_DRAW
    );

    // Position of the character on screen.
    c.glVertexAttribPointer(
        1,
        POSITION_SIZE,
        c.GL_FLOAT,
        c.GL_FALSE,
        @sizeOf(Float) * INSTANCED_SIZE,
        null
    );
    c.glEnableVertexAttribArray(1);
    c.glVertexAttribDivisor(1, 1);

    // Glyph x, y, width, height on atlas.
    const glyph_offset: *const anyopaque = @ptrFromInt(@sizeOf(Float) * POSITION_SIZE);
    c.glVertexAttribPointer(
        2,
        GLYPH_SIZE,
        c.GL_FLOAT,
        c.GL_FALSE,
        @sizeOf(Float) * INSTANCED_SIZE,
        glyph_offset
    );
    c.glEnableVertexAttribArray(2);
    c.glVertexAttribDivisor(2, 1);

    // Update uniforms of our shader.
    // Having a shader for every instance is convenient,
    // especially since there aren't many text variations in the game.
    var shader = try Shader.compile(vertex_shader, fragment_shader);
    c.glUniform3fv(shader.uniform("background_color"), 1, @ptrCast(options.background_color));
    c.glUniform3fv(shader.uniform("color"), 1, @ptrCast(&options.color));

    // Load texture based on atlas.
}