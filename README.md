# Coffixi.js
a CoffeeScript-based, AMD-compatible, minimal subset of pixi.js

### What?
Coffixi is a **subset** of pixi.js translated to CoffeeScript.

### Why?
Pixi.js is a performance-powerhouse, but I wanted to integrate it into a 
CoffeeScript-based game engine, and I like to have a consistent codebase.
The same reasoning explains why I chose to modularize pixi.js with AMD.

#### Why a Subset?
I want to keep the pixi.js code doing what it does best: rendering sprites.
Simpler APIs have fewer disagreements with other games/game engines.

### What's Changed?
Some things have been removed:
* Interactivity
* MovieClip
* Text
* `Rope` (from `extras`)

I also intend to change any parts of the API as needed to integrate with my
engine or other games/engines.

