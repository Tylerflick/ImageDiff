//
//  CoreImageKernels.metal
//  ImageDiff
//
//  Created by Tyler Hoeflicker on 7/21/17.
//  Copyright © 2017 Tyler Hoeflicker. All rights reserved.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;
using namespace coreimage;

float4 simpleDiff(sample_t first, sample_t second);

float4 simpleDiff(sample_t first, sample_t second) {
    const float4 same = float4(255, 255, 255, 255);
    const float4 diff = float4(0, 0, 0, 255);
    const float4 colorAtPixel = (first[0] != second[0] || first[1] != second[1] ||
                                 first[2] != second[2] || first[3] != second[3]) ? diff : same;
    return colorAtPixel;
}
