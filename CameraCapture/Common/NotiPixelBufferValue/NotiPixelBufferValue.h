//
//  NotiPixelBufferValue.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/24.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
NS_ASSUME_NONNULL_BEGIN

@interface NotiPixelBufferValue : NSObject

@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

+ (NotiPixelBufferValue *)valueWithCVPixelBuffer:(CVPixelBufferRef)buffer;

@end

NS_ASSUME_NONNULL_END
