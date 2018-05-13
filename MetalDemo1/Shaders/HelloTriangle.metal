//
//  HelloTriangle.metal
//  MetalDemo1
//
//  Created by v.q on 2018/5/7.
//  Copyright © 2018年 v.q. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[position]];
    float4 color;
};

vertex Vertex vertex_triangle(device Vertex *vertices [[buffer(0)]],
                              uint vid [[vertex_id]])
{
    return vertices[vid];
}

fragment float4 fragment_triangle(Vertex inVertex [[stage_in]])
{
    return inVertex.color;
}
