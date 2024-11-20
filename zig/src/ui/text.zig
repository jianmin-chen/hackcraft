const c = @cImport({
    @cInclude("glad/glad.h");
});
const Character = @import("../module/character.zig");
const math = @import("math");
const Shader = @import("shader");

const Characters = Character.Characters;

const Float = math.types.Float;

const Self = @This();

const vertex_shader = 
    \\#version 330 core
    \\
    \\layout (location = 0) in vec2 vertex;
    \\layout (location = 1) in vec4 position;
    \\layout (location = 2) in vec4 character;
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
    \\uniform vec3 color;
    \\
    \\in vec2 tex_coord;
    \\
    \\out vec4 out_color;
    \\
    \\void main() {
    \\  float alpha = texture(atlas, tex_coord).r;
    \\  out_color = vec4(color, alpha);
    \\} 
;

const VERTEX_SIZE = 2;

shader: Shader,
atlas: c_uint,
characters: Characters,
quads: usize = 0,

vao: c_uint,
vbo: c_uint,
base_vbo: c_uint,
ebo: c_uint,

pub fn from(
    atlas: struct {
        data: []u8,
        width: c_int,
        height: c_int
    },
    characters: Characters,
    projection: math.matrix.MatrixPrimitive,
    color: math.vector.Vec3(Float)
) !Self {
    var vao: c_uint = undefined;
    var vbo: c_uint = undefined;
    var base_vbo: c_uint = undefined;
    var ebo: c_uint = undefined;

    c.glGenVertexArrays(1, &vao);
    c.glGenBuffers(1, &vbo);
    c.glGenBuffers(1, &base_vbo);
    c.glGenBuffers(1, &ebo);

    c.glBindVertexArray(vao);

    // Base quad: 1x1 pixel.
    const base_quad = [_]Float{
        0, 1,
        0, 0,
        1, 0,
        1, 1
    };

    c.glBindBuffer(c.GL_ARRAY_BUFFER, base_quad);
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

    // Instanced rendering with a base set of a vertices.
    // Our element buffer object is going to store indices
    // to the base set of vertices.
    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(
        c.GL_ELEMENT_ARRAY_BUFFER,
        @sizeOf(c.GLuint) * indices.len,
        @ptrCast(&indices[0]),
        c.GL_STATIC_DRAW 
    );

    // Update uniforms of our shader.
    // Having a shader for every instance is convenient,
    // especially since there aren't many text variations in the game.
    const shader = try Shader.compile(vertex_shader, fragment_shader);
    c.glUniformMatrix4fv(shader.uniform("projection"), 1, c.GL_FALSE, @ptrCast(&projection[0]));
    c.glUniform3fv(shader.uniform("color"), 1, @ptrCast(&color));

    // Load texture based on atlas.
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 1);
    var texture: c_uint = undefined;
    c.glGenTextures(1, &texture);
    c.glBindTexture(c.GL_TEXTURE_2D, texture);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_CLAMP_TO_BORDER);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_CLAMP_TO_BORDER);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);
    c.glTexImage2D(
        c.GL_TEXTURE_2D,
        0,
        c.GL_RED,
        atlas.width,
        atlas.height,
        0,
        c.GL_RED,
        c.GL_UNSIGNED_BYTE,
        @ptrCast(&atlas[0])
    );
    c.glPixelStorei(c.GL_UNPACK_ALIGNMENT, 4);

    return .{
        .shader = shader,
        .atlas = texture,
        .characters = characters,

        .vao = vao,
        .vbo = vbo,
        .base_vbo = base_vbo,
        .ebo = ebo
    };
}

pub fn deinit(self: *Self) void {
    c.glDeleteVertexArrays(1, &self.vao);
    self.shader.deinit();
}

pub fn add(self: *Self, text: []const u8) !void {
    _ = self;
    _ = text;
}

pub fn render(self: *Self) void {
    self.shader.use();
    c.glBindTexture(c.GL_TEXTURE_2D, self.atlas);
    c.glBindVertexArray(self.vao);
}