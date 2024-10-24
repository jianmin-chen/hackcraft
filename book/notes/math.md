I want to make sure all the math content is readily available - that I don't leave out a single bit of the math if the user really wants to understand - so here are my notes on math as I do research.

TODO: Throw my paper notes in here, maybe.

## Math with matrices and vectors

Vectors are basically arrays in programming, that is [x, y] or [x, y, z] or [x, y, z, w]. Matrices are 

## Transformations

To do transformations efficiently, we want to use matrices. 

## Projection

* Interactive frustum, see by side

Projection is basically mapping from one coordinate space to the next. Usually as programmers we want to work in a coordinate space that is not OpenGL's *normalized device coordinates* coordinate space. Working with a range of [-1, 1] for both x and y is quite inconvenient.

Thus, we want a matrix that can take a (x, y, z) and convert it into a point on the screen. This is our projection matrix.

There are two kinds: orthographic and perspective. Perspective accounts for what you think of as perspective in the real world - as things get further away from you, they sort of converge and disappear.

**Our goal is to create a matrix that can take a $\ (x, y, z)$ which is our coordinate

## Perlin noise