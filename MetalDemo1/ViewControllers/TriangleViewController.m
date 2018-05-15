//
//  TriangleViewController.m
//  MetalDemo1
//
//  Created by v.q on 2018/5/7.
//  Copyright © 2018年 v.q. All rights reserved.
//

#import "TriangleViewController.h"
#import "MathUtils.h"
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

static const Vertex vertices[] = {
    { .position = {  0.0,  0.5, 0, 1 }, .color = { 1, 0, 0, 1 } },
    { .position = { -1.0, -0.5, 0, 1 }, .color = { 0, 1, 0, 1 } },
    { .position = {  1.0, -0.5, 0, 1 }, .color = { 0, 0, 1, 1 } }
};

@interface TriangleViewController ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) CAMetalLayer *metalLayer;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@end

@implementation TriangleViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self makeDevice];
    [self makePipeline];
    [self makeBuffers];
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(gameLoop)];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.displayLink invalidate];
    self.displayLink = nil;
}

#pragma mark - Metal Setup

- (void)makeDevice {
    self.device = MTLCreateSystemDefaultDevice();
    
    self.commandQueue = [self.device newCommandQueue];
    
    self.metalLayer = [CAMetalLayer layer];
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    self.metalLayer.framebufferOnly = YES;
    self.metalLayer.frame = self.view.layer.frame;
    
    CGFloat scale = [self.view.window.screen scale];
    CGSize drawableSize = self.view.bounds.size;
    drawableSize.width *= scale;
    drawableSize.height *= scale;
    
    self.metalLayer.drawableSize = drawableSize;
    
    [self.view.layer addSublayer:self.metalLayer];
}

- (void)makePipeline {
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_triangle"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_triangle"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    
    NSError *error = nil;
    self.pipeline = [self.device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!self.pipeline) {
        NSLog(@"Error: create render pipeline state failed, %@", error);
        abort();
    }
}

- (void)makeBuffers {
    self.vertexBuffer = [self.device newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceOptionCPUCacheModeDefault];
}

#pragma mark - Render

- (void)render {
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    id<MTLTexture> framebufferTexture = drawable.texture;
    
    if (!drawable) { return; }
    
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    passDescriptor.colorAttachments[0].texture = framebufferTexture;
    passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.7, 0.7, 0.7, 1.0);
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
    [commandEncoder setRenderPipelineState:self.pipeline];
    [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [commandEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)gameLoop {
    @autoreleasepool {
        [self render];
    }
}

@end

