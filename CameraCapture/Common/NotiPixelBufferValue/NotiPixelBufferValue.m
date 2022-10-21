//
//  NotiPixelBufferValue.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/24.
//

#import "NotiPixelBufferValue.h"

@implementation NotiPixelBufferValue

- (instancetype)initWithPointerValue:(CVPixelBufferRef)buffer
{
    self = [super init];
    if (self) {
        _pixelBuffer = buffer;
    }
    return self;
}

+ (NotiPixelBufferValue *)valueWithCVPixelBuffer:(CVPixelBufferRef)buffer{
   return [[self alloc] initWithPointerValue:buffer];
}

- (CVPixelBufferRef)pixelBuffer{
    return _pixelBuffer;
}

- (void)dealloc{
    if ([self pixelBuffer] != NULL) {
        CVPixelBufferRelease(_pixelBuffer);
    }
//#ifdef DEBUG
//    NSLog(@"------监听PixelBuffer数据释放------");
//#endif
}

@end
