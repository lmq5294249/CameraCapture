//
//  RTPConfigParam.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/10/17.
//

#import <Foundation/Foundation.h>
#import "RTSPClientAPI.h"

typedef enum _SamplingFrequency
{
    SamplingFrequency_96000 = 0,
    SamplingFrequency_88200,
    SamplingFrequency_64000,
    SamplingFrequency_48000,
    SamplingFrequency_44100,
    SamplingFrequency_32000,
    SamplingFrequency_24000,
    SamplingFrequency_22050,
    SamplingFrequency_16000,
    SamplingFrequency_12000,
    SamplingFrequency_11025,
    SamplingFrequency_8000,
    SamplingFrequency_7350,
    SamplingFrequency_Custom,
}SamplingFrequency;

typedef struct _AudioParam
{
    unsigned audioObjectType        : 5;
    unsigned samplingFrequencyIndex : 4;
    unsigned channelConfiguration   : 4;
    unsigned reservedBits : 3;
}AudioParam;

typedef struct _BitsParam
{
    unsigned bit0 : 1;
    unsigned bit1 : 1;
    unsigned bit2 : 1;
    unsigned bit3 : 1;
    unsigned bit4 : 1;
    unsigned bit5 : 1;
    unsigned bit6 : 1;
    unsigned bit7 : 1;
}BitsParam;

typedef struct _ThreeBits
{
    unsigned bit0 : 1;
    unsigned bit1 : 1;
    unsigned bit2 : 1;
}ThreeBits;

typedef struct _FourBits
{
    unsigned bit0 : 1;
    unsigned bit1 : 1;
    unsigned bit2 : 1;
    unsigned bit3 : 1;
}FourBits;

typedef struct _FiveBits
{
    unsigned bit0 : 1;
    unsigned bit1 : 1;
    unsigned bit2 : 1;
    unsigned bit3 : 1;
    unsigned bit4 : 1;
}FiveBits;

@interface RTPConfigParam : NSObject

+ (RtspFrameInfo)analyticLive555RTPConfigString:(const char *)configString;

+ (AudioParam)analyticBytes:(nullable const void *)bytes;

+ (int)getAudioSamplingFrequencyFromIndex:(NSInteger)index;

@end

