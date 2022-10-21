//
//  MediaDecoder.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/29.
//

#import <Foundation/Foundation.h>
#import "RtspConnection.h"

@interface MediaDecoder : NSObject<rtspDeleagte>

@property (nonatomic, strong) NSString *rtspString;

@property (nonatomic, assign) BOOL enableAudio;

@property (nonatomic, assign) BOOL isCameraBroken;

@property (nonatomic, assign) BOOL isOpenTheVideoStream;

- (void)startVideo;

- (void)stopVideo;

- (void)startAudio;

- (void)stopAudio;

@end

