# Seek

Godot-based image sequencer for artists. Designed for large image datasets and real-time performances. 


## News

* ### 2022-Oct-11: First prototype made available: 
    * supports basic creating and loading of images and real-time playback
    * requires Godot 4.0 beta 2
    * machine learning aspects not released yet


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

1. Download Godot 4.0 (beta 2): https://downloads.tuxfamily.org/godotengine/4.0/beta2/
2. Clone the repo
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

Sequences can be viewed and modified very basically using the `i` or `e` key, but this functionality is mostly placeholder at the moment.

### Controls

* `esc`: Toggle help menu
* `F`:Toggle fullscreen

#### Editing / sequencing controls

* `I`: Image grid

#### VJ Controls

* `Space`: Pause / resume
* `Z`: Reverse direction
* `X`, `down arrow`: Slower
* `C`, `up arrow`: Faster
* `>`, `left arrow`: Skip forward / next
* `<`, `right arrow`: Skip backwards / previous
* `/`: Fast forward
* `M`: Fast backward
* `V`: Reset speed
* `B`: Random jump
* `Left mouse button`: Forwards / backwards speed
* `Right mouse button`: Go to frame based on position
* `Enter / return`: Tap for beat matching

* `+` (plus): Increase opacity (fade in)
* `-` (minus): Decrease opacity (fade out)
* `mouse wheel`: Increase/decrease transition length

* `A`: Next sequence
* `1 - 9, 0`: Select sequence

* `D`: Duplicate layer
* `Ctrl / Cmd + 1 - 3`: Set active layer(s)

Note: For selecting the active layers, the Ctrl / Cmd key plus one or more of the number keys activates those layers, and when you release the Ctrl / Cmd key any layer that you didn't activate will be deactivated. Thus you can do: press Ctrl, press and release 1, press and release 2, release Ctrl, and layers 1 and 2 will be active and layer 3 will be deactivated (if it was previously active). Input will now affect both layers 1 and 2.

## Known Issues

* Godot v4.0-beta3 builds of Seek have some issues on some machines when making duplicate layers. Releases currently use beta2 which should avoid this problem.
