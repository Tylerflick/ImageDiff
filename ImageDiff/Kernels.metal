//
//  Kernels.metal
//  ImageDiff
//
//  Created by Tyler Hoeflicker on 7/6/17.
//  Copyright © 2017 Tyler Hoeflicker. All rights reserved.
//

#include <metal_stdlib>
#include <metal_atomic>

using namespace metal;

kernel void kernel_metalDiff(texture2d<float, access::read> in_texture_one [[texture(0)]],
                              texture2d<float, access::read> in_texture_two [[texture(1)]],
                              texture2d<float, access::write> out_texture [[texture(2)]],
                              volatile device atomic_uint *diff_cnt [[ buffer(0) ]],
                              uint2 gid [[thread_position_in_grid]]) {
    
    if (gid.x > out_texture.get_width() - 1 || gid.y > out_texture.get_height() - 1) {
        return;
    }
    
    const float4 same = float4(255, 255, 255, 255);
    const float4 diff = float4(0, 0, 0, 255);
    const float4 first = in_texture_one.read(gid);
    const float4 second = in_texture_two.read(gid);
    auto pixel_diff = (first[0] != second[0] || first[1] != second[1] || first[2] != second[2] || first[3] != second[3]);
    if (pixel_diff) {
        atomic_fetch_add_explicit(diff_cnt, 1, memory_order_relaxed);
    }
    const float4 colorAtPixel = pixel_diff ? diff : same;
    out_texture.write(colorAtPixel, gid);
}
