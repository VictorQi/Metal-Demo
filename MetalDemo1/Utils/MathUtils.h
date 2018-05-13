//
//  MathUtils.h
//  MetalDemo1
//
//  Created by v.q on 2018/5/12.
//  Copyright © 2018年 v.q. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/simd.h>

typedef struct Vertex {
    vector_float4 position;
    vector_float4 color;
} Vertex;

typedef struct Uniforms {
    matrix_float4x4 modelViewProjectionMatrix;
} Uniforms;

matrix_float4x4 matrix_float4x4_translation(simd_float3 t);
matrix_float4x4 matrix_float4x4_uniform_scale(float scale);
matrix_float4x4 matrix_float4x4_rotation(simd_float3 axis, float angle);
matrix_float4x4 matrix_float4x4_perspective(float aspect, float fovy, float near, float far);
matrix_float3x3 matrix_float4x4_extract_linear(matrix_float4x4 m);
