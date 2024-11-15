Basically, we have a 1x1x1 block that can be drawn using `glDrawElementsInstanced`. This is good for memory storage - we need three less values per vertex, which over time means a huge amount of memory gets saved.

> What is the magnitude of this "huge amount of memory" that gets saved?

Then we have chunks. A chunk is a set of 16x16x16 blocks. To us, this lets us manage blocks 16x16x16 at a time. We can toggle a block on or off by simply setting that value to -1.

Then after chunks we have the chunk manager. This manages the chunks. In Minecraft you will notice that blocks get rendered "outward" from you. The chunk manager is responsible for deciding what chunks get *painted*: which chunks need to send their data to the appropriate data buffer in a way that doesn't slow down our performance. Then it's responsible for *rendering* those chunks: making the draw calls that will actually draw them on screen and determining which ones should and shouldn't be drawn to maintain performance.

> I want to point out that "paint" and "render" are terms that I thought made logically sense. They might not be the exact technical term people use to describe writing to a data buffer -> using that data buffer.

So our shader will be called for each chunk. To determine the position, we have:

```glsl
mat4 mvp = projection * view * model;
gl_Position = mvp * vec4(base, 1.0);
```

We need to multiply `base` by our chunk offset. Then inside that, we need to have an index of the cube.

This is what OpenGL has to say about `glVertexAttribDivisor`.

> `glVertexAttribDivisor` modifies the rate at which generic vertex attributes advance when rendering multiple instanced of primitives in a single draw call. If divisor is zero, the attribute at slot `index` advances once per vertex. If `divisor` is non-zero, the attribute advances once per `divisor` instances of the set(s) of vertices being rendered.

Basically, by default this is set to `glVertexAttribDivisor(index, 0)`. The zero means that this will change every time a new vertex is passed through the vertex shader. However, if we change it to one, we will only pass in a new value every time a set of vertices has been passed through.

In our case, we will pass in `chunk` once for every $16 * 16 * 16 * \text{set of vertices}$.

> Alert
>
> This only works with instanced drawing functions, like `glDrawArraysInstanced` and in our case `glDrawElementsInstanced`.
