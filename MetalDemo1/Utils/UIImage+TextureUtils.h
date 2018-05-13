//
//  UIImage+TextureUtils.h
//  MetalDemo1
//
//  Created by v.q on 2018/5/13.
//  Copyright © 2018年 v.q. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol MTLTexture, MTLDevice;

@interface UIImage (TextureUtils)

- (id<MTLTexture>)vq_textureForDevice:(id<MTLDevice>)device;

+ (UIImage *)vq_imageWithMTLTexture:(id<MTLTexture>)texture;

@end
