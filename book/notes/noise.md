How does Minecraft and other voxel rendering engines go about making terrain? If

The answer is noise. Mathematically defining noise, it's a function $f$ that takes a set of input(s) (you know, one for one dimension, two for two dimensions, three for three dimensions, etc.) and returns a psuedorandom output. This output is usually $noise(input) \subset [0, 1]$, and the value is usually used to adjust some parameter.

## Just noise

There are a few different kinds of noise. The first one we'll take a look at is noise made from a random number generator.

Yeah that doesn't look really smooth, right? If we mapped this onto a 2D grid where the darker the point was the more lower it was, it woould look something like this:

The truth is, we want something more like this:

Notice how every point fades in with its neighbors. There's a really smooth transition. To do that, we need to use a noise algorithm that doesn't use random numbers, but instead does two things: a) provides a predetermined value and b) values and their neighbors are continuous and smooth, which should be relatively intuitive.

## Perlin noise

One of these noise algorithms is called Perlin noise. It's what we're going to use for our terrain generation and is the meat of this chapter. It's a little bit harder to understand then white noise but if you give it your best you'll get it.

> By the way...
>
> There are two versions of Perlin noise, both created by the man himself: the original version, [published](https://dl.acm.org/doi/pdf/10.1145/325165.325247) in 1984 and the [improved]() version in 2007. Here we are using the latter. As this chapter goes on I'll try to point out the differences.
>
> Ken Perlin won the Academy Award for this. I think that's kind of crazy.

First of all, we know that noise is a function that takes in any sets of inputs and returns a pseudorandom output based upon the input. 

Perlin noise does this by breaking it down into smaller steps. We go from

## A little bit of optimization

Now that we've gone ahead and 

## One last problem

A minor problem that you may have come to realize by now is if you're exploring, everything's kinda short. Some of the mountains in Minecraft are majestically tall. 

The solution to this is that the elevation needs to apply to more than one block. 

## Trees and grass

## Clouds

## Challenges

A lot of things in Minecraft depend on noise. Frankly, I think it's kind of crazy:

* Mining
* Villages

If you want a little more fun **Appendix X** on shaders plays around with Perlin noise to generate some cool 2D effects, like a map! If generative art is your thing.