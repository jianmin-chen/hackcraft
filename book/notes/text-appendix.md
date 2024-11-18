## Appendix X: Rendering text

In this book, we rendered the text

In this appendix you'll find answers to how we rendered that font atlas and other ways to render text.

So there are a couple of ways to render text. The two most common are to render a font atlas of some sort, with glyphs that we can map onto quads in our graphics programs. The other method is to manually draw the triangles that form a glyph. This method is obviously not particularly performant.

There's a thing called *signed distance fields*.

> JC Nerds Out
>
> To be honest, I don't understand much about text rendering still because it's such a *massive* field of its own. As I learn more about it I may update this appendix.
>
> If this is the kind of thing that's up your alley too, I found these really good reading resources.