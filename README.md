Get a sense of how graphics programming works behind the scenes by writing a little clone of Minecraft in 1k lines of JavaScript! Zig source code that can compile to WASM to build for both cross-platform OpenGL and WebGL is available and feature-complete, too, if you're a low-levels person! 

Written in JavaScript and Zig 0.13. Features:

* Add and remove blocks
* Textures
* Terrain and cloud generation
* Lighting: block-based propagation system &larr; ambient occlusion
* Day/light cycle
* Server for running multiplayer games

More about the book:

## Build WebGL

## Build OpenGL

The Zig codebase 

## Repository layout

* `/book` contains the contents of the book, including drafts and notes I took along the way.
* `/js` contains the JavaScript version.
* `/site` contains the actual site output, served by GitHub Pages.
* `/ssg` contains the static site generator I wrote to generate the site. If you're interested in this, I wrote a little [appendix]() for the book on it!
* `/tool` contains various Zig programs I wrote to generate resources, such as the file atlas.
* `/zig` contains the Zig version.