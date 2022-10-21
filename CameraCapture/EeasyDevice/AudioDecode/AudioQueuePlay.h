//
//  AudioQueuePlay.h
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/2.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


typedef void (^AudioPlayerOutputBlock)(SInt16 *outData, UInt32 numFrames, UInt32 numChannels);

@interface AudioQueuePlay : NSObject

@property (nonatomic, copy) AudioPlayerOutputBlock outputBlock;

//MARK:- (instancetype)init 包含开启播放等待数据进入

- (void)setAudioPlayerSampleRate:(unsigned int)sampleRate mChannelsPerFrame:(unsigned int)channels;

// 播放并顺带附上数据
- (void)playWithData: (NSData *)data;

- (void)fillNullData;

- (void)startPlay;

- (void)pausePlay;

- (void)stopPlay;

- (void)resetPlay;

@end


