//
//  Decoder.m
//  H264Demo
//
//  Created by 林漫钦 on 16/10/27.
//  Copyright © 2016年 lin. All rights reserved.

#import <Foundation/Foundation.h>

typedef void (^ShareVideoCallBackBlock)(NSString *filepath);
@interface MP4Helper : NSObject

-(void)doRunloop:(uint8_t *)buffer Size:(int)size;

//-(void)startRecord:(const char *)fileName Width:(int)width Height:(int)height;
-(void)startRecord:(NSString*)fileName Width:(int)width Height:(int)height;

-(void)closeFile;

//mp4v2
-(void)gotSps:(uint8_t *)sps Pps:(uint8_t *)pps SpsSize:(int)spsSize PpsSize:(int)ppsSize;
-(Boolean)mp4init:(NSString *)fileName Width:(int)width Height:(int)height;
-(void)writeVideoStream:(uint8_t *)buffer Size:(int)size;
-(void)mp4Close;
- (void)startShareVideoAndCallBackWithBlock:(ShareVideoCallBackBlock)block;
- (void)closeShareVideo;
-(BOOL)isRecording;
@end
