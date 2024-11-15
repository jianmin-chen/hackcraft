So up until this point we've been experimenting with a world that's getting rotated by a extra `model` matrix, which represents our local transformations on the chunks. But I presume you want to be able to move around and explore your world. Me too.

So let's work on that.

Usually our camera is atached to our player. Here I am assuming that our player is two units tall, and the head (which, in theory, is where our camera or "eyes" are attached) is on top. Thus we can have a constant that our camera can start out as:

Having a separate camera is handy because you can change the point of view. For example, the camera is usually behind and above the player in spectator mode.

From here on out until the end of this chapter, *I will refer to the player as the camera*, as they are mostly analogous.

So we can move forwards and backwards by adjusting the z position of our camera. The next logical thing would be able to make it so that when we move our mouse from left to right, our camera pans left and right. Same thing for moving our mouse up and down. Of course we'll also want to account for the delta time too.

To do this, we need to adjust the x and y of the camera's target, since our

To do this we make use of Euler angles. They represent all the ways an object can rotate based on its center of axis in a dimension: roll is based on the z-axis; yaw is based on the y-axis, and pitch is based on the x-axis.

Here's a good visual!

{TODO: Euler angles}

Personally I remember this as (y)aw = (y)-axis, and from there roll and pitch are pretty easy to discern.

We only need to make use of the yaw and pitch values. Now is a good time to add that:

```zig
yaw: Float = 0,
pitch: Float = 0,
```

Intuitively, it makes sense to think about pitch like this:
 
And the yaw like this:

Together they're like this:

It's no surprise that they're the exact same, but in two different dimensions. More importantly both of them are made up of two right triangles, which means we can use just a little bit of trig to solve for them!

> Hey!
>
> The following steps assume that our angles have been converted to radians, as we'll see later.

Good. The last step is to get **strafing**. Strafing just means moving the player left and right. This is different from moving the player front and back because the direction of the player can affect its speed, and we don't want that to happen.