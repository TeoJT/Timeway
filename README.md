## Rejected code branch
Originally, this branch was going to implement a new rendering system called the Dynamic Texture Atlas in which it stores every image into one texture to prevent texture swapping and hence save performance, while also avoiding the annoying lag issue in large PImages. However, several major disadvantages arised while developing it:
- Severely complicates code
- Added over 1000 lines that had to be maintained
- Rendered PImage obselete (no pun intended)
- Made it difficult to use regular functions like rect() etc.
- Consumes a massive amount of memory
- Complicates other things (some files needed to be named with the extension repeat.png large.png pad.png to avoid artefacts)
- Takes way too long to implement


And, to top it all off, there were no performance benefits with this new system in place that I could notice.
Kinda sucks, because I came so far with this code. But I think it's better to cut our losses than to continue with this... unfortunate mess.

