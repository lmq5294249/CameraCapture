//
//  PGQCAEAGLLayer.h
//  H264DecodingDemoPGQ
//
//  Created by Lois_pan on 16/5/18.
//  Copyright © 2016年 Lois_pan. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>

@interface PGQCAEAGLLayer : CAEAGLLayer
@property CVPixelBufferRef pixelBuffer;

- (id)initWithFrame:(CGRect)frame;
- (void)resetRenderBuffer;
-(UIImage *)currentImg;
@end
