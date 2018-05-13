//
//  ModelRendering.metal
//  MetalDemo1
//
//  Created by v.q on 2018/5/10.
//  Copyright © 2018年 v.q. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    float4 position [[attribute(0)]];
    float4 color [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
    float occlusion [[attribute(3)]];
};

struct Uniforms
{
    float4x4 modelViewProjectionMatrix;
};

struct VertexOut
{
    float4 position [[position]];
    float4 color;
    float2 texCoords;
    float occlusion;
};

vertex VertexOut modelRenderVertex(const VertexIn vertices [[stage_in]],
                                   constant Uniforms &uniforms [[buffer(1)]],
                                   uint vid [[vertex_id]])
{
    float4x4 mvpMatrix = uniforms.modelViewProjectionMatrix;
    float4 position = vertices.position;
    VertexOut out;
    out.position = mvpMatrix * position;
    out.color = float4(1);
    out.texCoords = vertices.texCoords;
    out.occlusion = vertices.occlusion;
    return out;
};

fragment half4 modelRenderFragment(VertexOut inFrag [[stage_in]],
                                   texture2d<float> textures [[texture(0)]])
{
    float4 baseColor = inFrag.color;
    float4 occlusion = inFrag.occlusion;
    constexpr sampler samplers;
    float4 texture = textures.sample(samplers, inFrag.texCoords);
    
    return half4(baseColor * occlusion * texture);
};
