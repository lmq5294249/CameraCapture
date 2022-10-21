//
//  RtspConnection.m
//  WRJ_RTSP
//
//  Created by 林漫钦 on 16/10/27.
//  Copyright (c) 2016年 Lin. All rights reserved.

#import <Foundation/Foundation.h>
#include <string.h>
#import "Singleton.h"
#import "RTPConfigParam.h"

typedef struct _VIDEO_PARAM
{
    char codec[256];
    int width;
    int height;
    int colorbits;
    int framerate;
    int bitrate;
    char vol_data[256];
    int vol_length;
}VIDEO_PARAM;

typedef struct  _AUDIO_PARAM
{
    char codec[256];
    int samplerate;
    int bitspersample;
    int channels;
    int framerate;
    int bitrate;
}AUDIO_PARAM;

typedef struct  __STREAM_AV_PARAM
{
    unsigned char    ProtocolName[32];
    short  bHaveVideo;//0 表示没有视频参数
    short  bHaveAudio;//0 表示没有音频参数
    VIDEO_PARAM videoParam;//视频参数
    AUDIO_PARAM audioParam;//音频参数
    char        szUrlInfo[512];//注意长度
}STREAM_AV_PARAM;


//typedef struct  _StreamConfig
//{
//    unsigned audioObjectType       : 5;
//    unsigned sampligFrequencyIndex : 3;
//    unsigned channelConfiguration  : 4;
//    unsigned reserve               : 4;
//}StreamConfig;

//typedef struct  _StreamConfig
//{
//    uint16_t sampligFrequencyIndex2  : 4;
//    uint16_t sampligFrequencyIndex      : 4;
//    uint16_t audioObjectType2      : 3;
//    uint16_t audioObjectType       : 5;
//
//}StreamConfig;

@protocol rtspDeleagte <NSObject>

@required
-(void)setAudioFrameDecodeInfo:(RtspFrameInfo)audioFameInfo;

//解码一帧数据，frame为帧数据，size为帧数据大小。
-(void)decodeNalu:(uint8_t *)buffer Size:(int)size;

//获取h264编码的sps、pps信息。
-(void)gotSps:(uint8_t *)sps SpsSize:(int)spsSize Pps:(uint8_t *)pps PpsSize:(int)ppsSize;

-(void)decodeAudioUnit:(uint8_t *)buffer Size:(int)size;

@end

@interface RtspConnection : NSObject
singleton_interface(RtspConnection)

//开启rtsp通道，传输视频流数据，online参数填no即可 yes no 决定用h264_add还是online_play
-(void)start_rtsp_session:(BOOL)online rtspAddress:(NSString *)str;

//关闭rtsp通道
-(void)close_rtsp_client;

//单例
+(RtspConnection *)shareStore;

//判断rtsp连接状态
-(BOOL)isConnecting;

@property(assign,nonatomic)id <rtspDeleagte> delegate;
@property(nonatomic,assign) STREAM_AV_PARAM pAvParam;

@end
