# ImageDiff
A small command line app that generates a diff between two images using Apple's Metal SDK, along with other approaches.

## Overview
ImageDiff is a small sample project to demonstrate the effeciancy of Metal over CPU bound algorithms for determining if two images are different.

## Purpose
Writing unit tests in the areas of 2d/3d rendering and image processing can be difficult. An alternative to writing unit tests is to create a set of baseline images to compare against. Any changeset in the codebase would render the same set of output images for comparison with the baseline set.

As your baseline set grows, your testing time grows liniear to the sum of pixels in the baseline set. It is not possible to reduce the time complexity of the comparison below O(n). You can however, take advantage of the hardware on the running sytem to speed it up.

## Using ImageDiff
### Inputs
TODO

### Outputs
When using MetalDiffer & SoftwareDiffer the return code of the process represents the number of pixel differences between the two input images. If there are differences, the output image will be saved to the specified location.

When using CoreImageDiffer, there is a limitation around the function signature required for CoreImage kernels. Rather than slow the differ down with a second CPU pass on the output image to scan for differneces, the differ returns 0 differnces and always saves it's output image. This is simply a limitation of this technology.

## Contents
### MetalDiffer
Uses a Metal compute shader for a pixel by pixel comparison between two images. If there are any differences between the two images, the output is written to the output location, with black pixels representing diffs.

Advantages:  
- Generates the output image at the same time as determining if there are any differences.  

Disadvantages:  
- Complexity of setup. The overhead of transfering the image data from system memory to GPU memory may not be worth the penalty in all situations.

### CoreImageDiffer
Uses CoreImage to generate a difference between the two images.

Advantages:
- Initial benchmarks show it the fastest of the three approaches. Ease of setup compared with Metal.

Disadvantages:
- Due to the limitation of the CoreImageKernel signature, only generating an output image in the shader is possible. Regestering if there was a difference still must done on a pass with the CPU.


### SoftwareDiffer
Pure CPU bound linear scan of both images.

Advantages:
- Simpilest of all three differs. Can track sum of differences since the differ has direct access to each image buffer.

Disadvantages:
- Slow, log O(N) slow.


## Benchmarks
*Documentation In Progress*

## Building
TODO

## Contributing
TODO
