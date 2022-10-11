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
3. Open project in Godot

