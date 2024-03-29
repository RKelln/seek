# Seek

Godot-based image sequencer for artists. Designed for large image datasets and real-time performances. 


## News

* ### 2022-Oct-11: First prototype made available: 
	* supports basic creating and loading of images and real-time playback
	* requires Godot 4.0 beta 2
	* machine learning aspects not released yet

* ### 2023-July: Second prototype (v0.4.1):
  * supports basic VJ capabilities
  * requires Godot 4.1
  * adds concepts of image tags and image neighbours
  * basic midi support
  * basic custom transition support
  * simple Ken Burns camera effects

* ### 2023-Nov: Third prototype (v0.4.3):
  * requires Godot 4.2
  * manual control over transition
  * small tweaks and fixes for November concerts


## What? Who is this for?

**This is a prototype of software! Use at your own risk. Code is a mess, sorry.**

'Seek' is cross platform software that allows artists to construct and play a sequence of images, journeying along the many relationships between the images. Unlike typical video editor software the sequencer is focused on interpolated paths through the information landscape of the collection of images. The interface also supports navigation, discovery and comparison of images to help artists define a custom sequential path through the image set.

Seek is designed to allow artists to explore large image collections, or still images from videos, and discover and experiment with the relationships between the images. These relationships would be mediated by statistics and machine learning algorithms such as:

* Color (per channel: red, green, blue)
* Luminosity (dark vs light)
* Time (time image was taken or frame number of video still)
* Image features
  * Use machine learning models to compare by perceptual image similarity (“energy” or “feel”)
* Classification
  * Use machine learning to classify all the images, creating a value for each class
	* 0-100% confidence that the image contains a cat, i.e. cat-iest to least cat-ty
	* Saddest to happiest image (sentiment score)
   * Segmentation: Amount of image that is of a class (“cat”, “sky”, etc)

Seek will process a dataset of images and identify the relationships between the images (currently done as separate python scripts).

The Seek software will play two main roles, as an exploration tool allowing artists and audiences to navigate the image space and highlight relationships, and as a playback tool for rapid playback of the images in predefined or algorithmically controlled sequences.

A simple example would be to display each image from darkest to lightest. A more complicated and interesting example is choosing a random image then continually selecting the next most similar image without repeats. Similarity in this case is determined by some algorithm, using machine learning or other mathematical techniques.

## Installation

**Coming soon**: Use one of the pre-built releases.

### For developers or custom changes

1. Download Godot 4.2: https://godotengine.org/download/
2. Clone this repo
3. Import project file in Godot


## Usage

Seek is designed to load folders of images (jpg, png, or webp) into an image pack. These image packs are compressed with video card texture compression and are designed to be stored entirely on your video card for very fast non-sequential access. (Note: in testing Godot will place them in your machine RAM and move them onto the card as needed, but you need enough RAM to store all your image packs.)

So first you'll need to crate an image pack, given Seek a folder of images. Then you can start playing them. By default they play back in sorted (by name) order.

Once you've made some image packs you can load them, instead of re-creating them.

You can also make new sequences from the images to play them back in different orders. These sequences can be created by a text file that has a number on each line that denotes the image in default sorted order, starting from 0. I.E. images selected by number and new sequence is line by line:

```
1
2
3
0
```
Would create a sequence, starting with the second image, then third, fourth and finally the first (of images in the folder sorted by name).

After creating or loading images you can click Start. The first image will be displayed but __playback starts paused__. Press `spacebar` to unpause.

Sequences can be viewed and modified very basically using the `i` or `e` key, but this functionality is mostly placeholder at the moment. [RK: July 2023: currently disabled until properly implemented]

### Controls

* `esc`: Toggle help menu
* `F`:Toggle fullscreen

#### Editing / sequencing controls

* `I`: Image grid (currently disabled)

#### VJ Controls

* `Space`: Pause / resume
* `Z`: Reverse direction
* `X`, `down arrow`: Slower
* `C`, `up arrow`: Faster
* `left arrow`: Step forward / next
* `right arrow`: Step backwards / previous
* `>`: Skip forward
* `<`: Skip backwards
* `/`: Fast forward
* `M`: Fast backward
* `V`: Reset speed
* `B`: Random jump
* `Enter / return`: Tap for beat matching

* `+` (plus): Increase opacity (fade in)
* `-` (minus): Decrease opacity (fade out)
* `mouse wheel`: Increase/decrease transition length

* `A`: Next sequence
* `1 - 9, 0`: Select sequence


## Under development features

These are barely working features, but have been used in performance. Use at your own risk.

### Image tags and neighbours

Each image can have multiple tags and a list of neighbours. This allows for selecting which tags are currently active. When combined with image nieghbours information you can continue to traverse the images by nearest neighbour even with an active subset of the total images. The default algorithm tries to avoid repetition of images while still choosing nearby neighbours.

Image tag file format is simple:
```
tagA,tagB,tagC
tagD
```
Where image #1 in the image pack (the first image) would be tagged with tagA, tagB, and tagC while the second image would have tagD.

Image neighbours file format:
```
[1,2,3]
[2,5,6]
etc...
```
Where each line is an array of other image indexes. The array should be sorted by closest to further in similarity and I have found that approximately 10-20% of the size of the entire image pack seems to work, but hasn't been thoroughly tested.

Note that neighbours info can be used without tags (i.e. no sequence file loaded, just nieghbours), but tags require neighbours to work (because there is no single sequence for any subset).

Tags can be activated by using shift-<letter> where <letter> is the first letter of the tag. When more than one tag share starting letters subsequent letters will be use, avoiding vowels.


### Midi control

There is very hacky and basic support for midi control, but requires hacking on the code to set up for your controller. See `midi_controller.gd`. 


### Auto Ken Burns effect

Images will slowly pan and zoom to give a bit more movement. This can be controlled but currently is done automatically.


### Custom transitions

The transition between images can be any shader but defaults to alpha blend. See `clock` and `shaders/clock.gdshader` for an exmaple of how to add your own. 


### Manual transition timing

You can control the transition manually now, but is currently only hooked up to the midi controls (you'll want some sort of input that smoothly ranges from 0 to 1). "Rocking" the input back and forth will control the forward progression and transitions.


## Known Issues

* transitions don't start immediately and have weird interactions with skipping/stepping forward/backwards


## TODO

* [ ] improved usability and UI
* [ ] bring back and improve sequence editing in app
* [ ] save all info into an image pack or create a "scene" save file with all settings
* [ ] add strech, frameskip, movement to animation information
  * [ ] auto-detect stretch (if all images are the same size then no stretch)
* [ ] user adjustable input mappings
  * [ ] user adjustable midi mappings
