You merge a pull request that makes a significant improvement to Hackcraft

* Maps
* Redstone
* Animations for destroying blocks. Most blocks also come with a particle effect where minature clones of the blocks "spray" out when you destroy it. This may require taking a look into animating particle systems.
* Improved movement system. Minecraft has a couple of quality-of-life improvements for the movement, including ease-out functions to "slow to a stop".
* More terrain generation. Cliffs, overhangs, stars/planets in the sky... I think this is one of those where the sky is your imagination.
* Better chunk management. Right now, the way we efficiently render chunks is by moving downwards in the y-direction until we know we're underground because we hit a block occluded by all sides. This works because we don't have underground caves. A better approach would be to divide it into chunks and check if the chunks are occluded.
* Improved text rendering. Right now, we don't have support for emojis. Emojis use surrogate codepoints - that is, Unicode codepoints
* Improved UI. So far, we've designed everything to be changeable and extensible. Now if we could just add a UI for the player to play around with those! Among other things:
  * Intro video instead of a static image. This involves updating a texture with the frames of a video after decoding it with a library of some sort. You might also have to do some optimizations.

To check what has been done already, please check the [changelog](), which gets updated with every significant pull request that gets merged. 