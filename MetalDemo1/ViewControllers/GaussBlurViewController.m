//
//  GaussBlurViewController.m
//  MetalDemo1
//
//  Created by v.q on 2018/5/7.
//  Copyright © 2018年 v.q. All rights reserved.
//

#import "GaussBlurViewController.h"
#import "UIImage+TextureUtils.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface GaussBlurViewController () <MTKViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UISlider *blurRadiusSlider;
@property (nonatomic, weak) IBOutlet UIView *container;
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) MTKTextureLoader *loader;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) id<MTLTexture> texture;

@end

@implementation GaussBlurViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configureNavigationBar];
    [self makeDevice];
    [self makeMTKView];
    [self loadAssets];
}

#pragma mark - Private Method

- (void)configureNavigationBar {
    UIButton *exportButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [exportButton setTitle:@"Export" forState:UIControlStateNormal];
    [exportButton addTarget:self action:@selector(onExportButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [exportButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:exportButton];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)makeDevice {
    self.device = MTLCreateSystemDefaultDevice();
    if (!self.device) {
        NSLog(@"MTL Error: cannot create system default device");
        abort();
    }
    
    self.commandQueue = [self.device newCommandQueue];
}

- (void)makeMTKView {
    NSString *imagePath = [NSBundle.mainBundle pathForResource:@"AllenIverson" ofType:@"jpg"];
    self.image = [UIImage imageWithContentsOfFile:imagePath];
    self.imageView.image = self.image;
    CGSize imageSize = self.image.size;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:scrollView belowSubview:self.container];
    self.scrollView = scrollView;
    
    scrollView.contentSize = self.image.size;
    self.mtkView = [[MTKView alloc] initWithFrame:(CGRect){.origin = CGPointZero, .size = imageSize} device:self.device];
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(1, 1, 1, 1);
    self.mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.mtkView.framebufferOnly = NO;
    self.mtkView.autoResizeDrawable = NO;
    self.mtkView.drawableSize = self.image.size;
    [scrollView addSubview:self.mtkView];
}

- (void)loadAssets {
    self.loader = [[MTKTextureLoader alloc] initWithDevice:self.device];
    
    NSError *error = nil;
    self.texture = [self.loader newTextureWithCGImage:self.image.CGImage options:@{ MTKTextureLoaderOptionSRGB: @(NO) } error:&error];
    if (error) {
        NSLog(@"MTL Error: load texture failed, %@", error);
        abort();
    }
    NSLog(@"self.texture.pixelFormat: %@", @(self.texture.pixelFormat).stringValue);
}

#pragma mark - Button Action

- (void)onExportButtonPressed:(UIButton *)sender {
    // TODO: 这个方法可能会出现白屏
    id<MTLTexture> lastDrawableDisplayed = self.mtkView.currentDrawable.texture;
    UIImage *getImage = [UIImage vq_imageWithMTLTexture:lastDrawableDisplayed];
    
    self.imageView.image = getImage;
    self.scrollView.hidden = YES;
}

#pragma mark - MTKView Delegate

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size { }

- (void)drawInMTKView:(MTKView *)view {
    @autoreleasepool {
        if (view.isHidden) {
            return;
        }
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        id<MTLTexture> drawingTexture = view.currentDrawable.texture;
        
        MPSImageGaussianBlur *filter = [[MPSImageGaussianBlur alloc] initWithDevice:self.device sigma:self.blurRadiusSlider.value];
        [filter encodeToCommandBuffer:commandBuffer sourceTexture:self.texture destinationTexture:drawingTexture];
        
        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }
}

@end
