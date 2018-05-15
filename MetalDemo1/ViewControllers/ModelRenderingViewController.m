//
//  ModelRenderingViewController.m
//  MetalDemo1
//
//  Created by v.q on 2018/5/7.
//  Copyright © 2018年 v.q. All rights reserved.
//

#import "ModelRenderingViewController.h"
#import "MathUtils.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>

// TODO: obj中很多纹理没有bake上

@interface ModelRenderingViewController () <MTKViewDelegate>

@property (nonatomic, copy) NSArray<MTKMesh *> *meshes;
@property (nonatomic, strong) id<MTLDevice> deviece;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) MTLVertexDescriptor *vertexDescriptor;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLDepthStencilState> depthStenciState;

@end

@implementation ModelRenderingViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.deviece = MTLCreateSystemDefaultDevice();
    if (!self.deviece) {
        self.view = [[UIView alloc] initWithFrame:self.view.frame];
        self.view.backgroundColor = [UIColor blackColor];
        NSLog(@"MTL Error: cannot create system default device");
        abort();
    }
    
    MTKView *mtkView = (MTKView *)self.view;
    mtkView.device = self.deviece;
    mtkView.delegate = self;
    mtkView.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0);
    mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    
    [self makePipeline];
    [self makeMatrixAndBuffers];
    [self loadAsset];
}

#pragma mark - Private Method

- (void)makePipeline {
    MTKView *mtkView = (MTKView *)self.view;
    
    self.commandQueue = [self.deviece newCommandQueue];
    self.commandQueue.label = @"Model Rendering";
    
    MTLDepthStencilDescriptor *depthDescriptor = [[MTLDepthStencilDescriptor alloc] init];
    depthDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    depthDescriptor.depthWriteEnabled = YES;
    self.depthStenciState = [self.deviece newDepthStencilStateWithDescriptor:depthDescriptor];
    
    id<MTLLibrary> library = [self.deviece newDefaultLibrary];
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"modelRenderVertex"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"modelRenderFragment"];
    
    self.vertexDescriptor = [MTLVertexDescriptor vertexDescriptor];
    self.vertexDescriptor.attributes[0].offset = 0;
    self.vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3; // position
    self.vertexDescriptor.attributes[1].offset = 12;
    self.vertexDescriptor.attributes[1].format = MTLVertexFormatUChar4; // color
    self.vertexDescriptor.attributes[2].offset = 16;
    self.vertexDescriptor.attributes[2].format = MTLVertexFormatHalf2; // texture
    self.vertexDescriptor.attributes[3].offset = 20;
    self.vertexDescriptor.attributes[3].format = MTLVertexFormatFloat; // occlusion
    self.vertexDescriptor.layouts[0].stride = 24;
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexDescriptor = self.vertexDescriptor;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
    pipelineDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
    
    NSError *error = nil;
    self.pipelineState = [self.deviece newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (error) {
        NSLog(@"MTL Error: create render pipeline state failed, %@", error);
        abort();
    }
}

- (void)makeMatrixAndBuffers {
    matrix_float4x4 scaled = matrix_float4x4_uniform_scale(1.0);
    matrix_float4x4 rotated = matrix_float4x4_rotation(simd_make_float3(0, 1, 0), 90);
    matrix_float4x4 translated = matrix_float4x4_translation(simd_make_float3(0, -10, 0));
    matrix_float4x4 modelMatrix = matrix_multiply(matrix_multiply(translated, rotated), scaled);
    simd_float3 cameraPosition = simd_make_float3(0, 0, -50);
    matrix_float4x4 viewMatrix = matrix_float4x4_translation(cameraPosition);
    
    MTKView *view = (MTKView *)self.view;
    CGFloat aspect = view.drawableSize.width / view.drawableSize.height;
    matrix_float4x4 projMatrix = matrix_float4x4_perspective(aspect, 1, 0.1, 100);
    
    matrix_float4x4 modelViewProjectionMatrix = matrix_multiply(projMatrix, matrix_multiply(viewMatrix, modelMatrix));
    Uniforms mvpMatrix = { modelViewProjectionMatrix };
    
    self.uniformBuffer = [self.deviece newBufferWithBytes:&mvpMatrix length:sizeof(mvpMatrix) options:MTLResourceOptionCPUCacheModeDefault];
    NSAssert(self.uniformBuffer != nil, @"Buffer cannot be created.");
};

- (void)loadAsset {
    MDLVertexDescriptor *mdlVertexDesc = MTKModelIOVertexDescriptorFromMetal(self.vertexDescriptor);
    
    MDLVertexAttribute *attribute = mdlVertexDesc.attributes[0];
    attribute.name = MDLVertexAttributePosition;
    attribute = mdlVertexDesc.attributes[1];
    attribute.name = MDLVertexAttributeColor;
    attribute = mdlVertexDesc.attributes[2];
    attribute.name = MDLVertexAttributeTextureCoordinate;
    attribute = mdlVertexDesc.attributes[3];
    attribute.name = MDLVertexAttributeOcclusionValue;
    
    MTKMeshBufferAllocator *mtkBufferAllocator = [[MTKMeshBufferAllocator alloc] initWithDevice:self.deviece];
    
    NSURL *houseFileURL = [NSBundle.mainBundle URLForResource:@"Farmhouse" withExtension:@"obj"];
    
    MDLAsset *asset = [[MDLAsset alloc] initWithURL:houseFileURL vertexDescriptor:mdlVertexDesc bufferAllocator:mtkBufferAllocator];
    
    NSError *error = nil;
    
    MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:self.deviece];
    NSURL *textureURL = [NSBundle.mainBundle URLForResource:@"Farmhouse" withExtension:@"png"];
    self.texture = [loader newTextureWithContentsOfURL:textureURL options:nil error:&error];
    
    if (error) {
        NSLog(@"MTL Error: load texture failed, %@", error);
        abort();
    }
    
    id tmp = [asset objectAtIndex:0];
    if (!tmp || ![tmp isKindOfClass:[MDLMesh class]]) {
        NSLog(@"MTL Error: mesh not found");
        abort();
    }
    
    MDLMesh *mesh = (MDLMesh *)tmp;
    [mesh generateAmbientOcclusionVertexColorsWithQuality:1
          attenuationFactor:0.98
          objectsToConsider:@[mesh]
          vertexAttributeNamed:MDLVertexAttributeOcclusionValue];
    
    self.meshes = [MTKMesh newMeshesFromAsset:asset device:self.deviece sourceMeshes:nil error:&error];
    if (error) {
        NSLog(@"MTL Error: create meshes failed, %@", error);
        abort();
    }
}

#pragma mark - MTKView Delegate

- (void)drawInMTKView:(nonnull MTKView *)view {
    @autoreleasepool {
        id<CAMetalDrawable> drawable = view.currentDrawable;
        MTLRenderPassDescriptor *descriptor = view.currentRenderPassDescriptor;
        if (!drawable || !descriptor) {
            NSLog(@"MTL Error: the mtkview resource are not available");
            abort();
        }
        
        descriptor.colorAttachments[0].texture = drawable.texture;
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1);
        descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
        
        [commandEncoder setRenderPipelineState:self.pipelineState];
        [commandEncoder setDepthStencilState:self.depthStenciState];
        [commandEncoder setCullMode:MTLCullModeBack];
        [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [commandEncoder setVertexBuffer:self.uniformBuffer offset:0 atIndex:1];
        [commandEncoder setFragmentTexture:self.texture atIndex:0];
        
        MTKMesh *mesh = self.meshes.firstObject;
        if (!mesh) {
            NSLog(@"MTL Error: drawInMTKView failed, mesh not found");
            abort();
        }
        MTKMeshBuffer *vertexBuffer = mesh.vertexBuffers[0];
        [commandEncoder setVertexBuffer:vertexBuffer.buffer offset:vertexBuffer.offset atIndex:0];
        MTKSubmesh *submesh = mesh.submeshes.firstObject;
        if (!submesh) {
            NSLog(@"MTL Error: drawInMTKView failed, submesh not found");
            abort();
        }
        [commandEncoder drawIndexedPrimitives:submesh.primitiveType
                                   indexCount:submesh.indexCount
                                    indexType:submesh.indexType
                                  indexBuffer:submesh.indexBuffer.buffer
                            indexBufferOffset:submesh.indexBuffer.offset];
        
        [commandEncoder endEncoding];
        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size { }

@end
