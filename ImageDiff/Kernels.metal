//
//  Kernels.metal
//  ImageDiff
//
//  Created by Tyler Hoeflicker on 7/6/17.
//  Copyright © 2017 Tyler Hoeflicker. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

kernel void kernel_metalDiff(texture2d<float, access::read> inTextureOne [[texture(0)]],
                              texture2d<float, access::read> inTextureTwo [[texture(1)]],
                              texture2d<float, access::write> outTexture [[texture(2)]],
                              uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x > outTexture.get_width() - 1 || gid.y > outTexture.get_height() - 1) {
        return;
    }
    
    const float4 same = float4(255, 255, 255, 255);
    const float4 diff = float4(0, 0, 0, 255);
    const float4 first = inTextureOne.read(gid);
    const float4 second = inTextureTwo.read(gid);
    const float4 colorAtPixel = (first[0] != second[0] || first[1] != second[1] ||
                                 first[2] != second[2] || first[3] != second[3]) ? diff : same;
    outTexture.write(colorAtPixel, gid);
}
