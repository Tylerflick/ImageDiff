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

extern "C" {
    namespace coreimage {
    
        float4 naiveDiff(sample_t first, sample_t second);

        float4 naiveDiff(sample_t first, sample_t second) {
            const float4 same = float4(255, 255, 255, 255);
            const float4 diff = float4(0, 0, 0, 255);
            return (first.r != second.r || first.g != second.g || first.b != second.b || first.a != second.a) ? diff : same;
        }
    }
}
