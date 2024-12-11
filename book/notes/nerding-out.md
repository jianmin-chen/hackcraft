## Appendix X: Nerding out

So for this site I made a static site generator, with an entirely custom Markdown parser. This probably wasn't needed, but I find it pretty cool.

I also built a custom analytics tool. This website uses two: [Plausible]() and my own, called [Impossible]() (irony intended). 

The JSON library that we use is written from scratch, and you can find the source [here](). The documentation for the builtin version was a little confusing, plus I also wanted to try my hand at writing a streaming parser of some form in Zig, so this is my attempt. If you don't know what any of these words mean/want to learn a little bit about how parsers work, I wrote a little something on my [personal blog](https://braindump.ing) as well.