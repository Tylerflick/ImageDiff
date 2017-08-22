# ImageDiff
A small command line app that generates a diff between two images using Apple's Metal SDK, along with other approaches.

## Overview
ImageDiff is a small sample project to demonstrate the effeciancy of Metal over CPU bound algorithms for determining if two images are different.

## Purpose
Writing unit tests in the areas of 2d/3d rendering and image processing can be difficult. An alternative to writing unit tests is to create a set of baseline images to compare against. Any changeset in the codebase would render the same set of output images for comparison with the baseline set.

As your baseline set grows, your testing time grows liniear to the sum of pixels in the baseline set. It is not possible to reduce the time complexity of the comparison below O(n). You can however, take advantage of the hardware on the running sytem to speed it up.

## Contents
### MetalDiffer
Uses a Metal compute shader for a pixel by pixel comparison between two images. If there are any differences between the two images, the output is written to the output location, with black pixels representing diffs.

Advantages:  
- Generates the output image at the same time as determining if there are any differences.  

Disadvantages:  
- Complexity of setup. The overhead of transfering the image data from system memory to GPU memory may not be worth the penalty in all situations.

### CoreImageDiffer
Uses CoreImage to generate a difference between the two images. *Documentation In Progress*

## Benchmarks
*Documentation In Progress*
