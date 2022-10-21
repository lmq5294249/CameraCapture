//
//  RTPConfigParam.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/10/17.
//

#import "RTPConfigParam.h"

@implementation RTPConfigParam
int sthvalue(char c);
int strtohex(char *str, char *data);
int sthvalue(char c)
{
        int value;
        if((c >= '0') && (c <= '9'))
                value = 48;
        else if ((c >= 'a') && (c <='f'))
                value = 87;
        else if ((c >= 'A') && (c <='F'))
                value = 55;
        else {
                printf("invalid data %c",c);
                return -1;
        }
        return value;
}
/*转化函数，把字符串和一个数组当做参数，这个函数会把str的值，每两个组合成一个16进制的数*/
int strtohex(char *str, char *data)
{
        int len =0;
        int sum =0;
        int high=0;
        int low=0;
        int value=0;
        int j=0;
        len = strlen(str);//获取字符串的字符个数
        //char data[256] = {0};
        printf("%d\n", len);
        //在for循环中，从0开始，每两个数组成一个16进制，高4位和低4位，然后放技能数组中去
        for(int i=0; i<len; i++)
        {

//              printf("high-n:0x%02x\n", str[i]);
                value = sthvalue(str[i]);
                high = (((str[i]-value)&0xF)<<4);//获取数据，成为高4位
//              printf("high:0x%02x\n", high);
//              printf("low-n:0x%02x\n", str[i+1]);
                value = sthvalue(str[i+1]);
                low = ((str[i+1]-value)&0xF);//获取数据，成为低4位
//              printf("low:0x%02x\n", low);
                sum = high | low; //组合高低四位数，成为一byte数据
//              printf("sum:0x%02x\n", sum);
                j = i / 2; //由于两个字符组成一byte数，这里的j值要注意
                data[j] = sum;//把这byte数据放到数组中
                i=i+1; //每次循环两个数据，i的值要再+1
        }
        return len;
}

+ (RtspFrameInfo)analyticLive555RTPConfigString:(const char *)configString
{
    Byte audioParamBytes[2];
    char resultString[10];
    strncpy(resultString, configString, 4);
    int len = strtohex((char *)resultString, (char *)audioParamBytes);
    for (int i = 0; i < 2; i++) {
        printf("%d ", audioParamBytes[i]);
    }
    //NSData *data = [NSData dataWithBytes:&audioParamBytes length:2];
    
    AudioParam audioParam = [self analyticBytes:audioParamBytes];
    int audioSamplingFrequencyValue = [self getAudioSamplingFrequencyFromIndex:audioParam.samplingFrequencyIndex];
    
    RtspFrameInfo audioFrameInfo;
    if (audioParam.audioObjectType == 2) {
        audioFrameInfo.codec = RTSP_AUDIO_CODE_AAC; //参靠FFmpeg的AAC code值 0x15002,
    }
    audioFrameInfo.sample_rate = audioSamplingFrequencyValue;
    audioFrameInfo.channels = audioParam.channelConfiguration;
    audioFrameInfo.bits_per_sample = 16;
    
    return audioFrameInfo;
}

+ (AudioParam)analyticBytes:(nullable const void *)bytes
{
    AudioParam audioParam;
    //int bytesNum = sizeof(bytes);
    NSData *data = [NSData dataWithBytes:bytes length:2];
    BitsParam origialByte_1,origialByte_2;
    [data getBytes:&origialByte_1 range:NSMakeRange(0, 1)];
    [data getBytes:&origialByte_2 range:NSMakeRange(1, 1)];
    
    //NSLog(@"打印originalByte : 0x%X",origialByte_1);
    
    FiveBits fiveBits;
    fiveBits.bit0 = origialByte_1.bit7;
    fiveBits.bit1 = origialByte_1.bit6;
    fiveBits.bit2 = origialByte_1.bit5;
    fiveBits.bit3 = origialByte_1.bit4;
    fiveBits.bit4 = origialByte_1.bit3;
    int value = fiveBits.bit0 * 16 + fiveBits.bit1 * 8 + fiveBits.bit2 * 4 + fiveBits.bit3 * 2 + fiveBits.bit4 * 1;
    audioParam.audioObjectType = value;
    
    FourBits foutBits;
    foutBits.bit0 = origialByte_1.bit2;
    foutBits.bit1 = origialByte_1.bit1;
    foutBits.bit2 = origialByte_1.bit0;
    foutBits.bit3 = origialByte_2.bit7;
    value = foutBits.bit0 * 8 + foutBits.bit1 * 4 + foutBits.bit2 * 2 + foutBits.bit3 * 1;
    audioParam.samplingFrequencyIndex = value;

    foutBits.bit0 = origialByte_2.bit6;
    foutBits.bit1 = origialByte_2.bit5;
    foutBits.bit2 = origialByte_2.bit4;
    foutBits.bit3 = origialByte_2.bit3;
    value = foutBits.bit0 * 8 + foutBits.bit1 * 4 + foutBits.bit2 * 2 + foutBits.bit3 * 1;
    audioParam.channelConfiguration = value;
    
    ThreeBits threeBits;
    threeBits.bit0 = origialByte_2.bit2;
    threeBits.bit1 = origialByte_2.bit1;
    threeBits.bit2 = origialByte_2.bit0;
    value = threeBits.bit0 * 4 + threeBits.bit1 * 2 + threeBits.bit2 * 1;
    audioParam.reservedBits = value;

    return audioParam;
}


+ (int)getAudioSamplingFrequencyFromIndex:(NSInteger)index
{
    int audioFrequencyValue;
    switch (index) {
        case SamplingFrequency_96000:
            audioFrequencyValue = 96000;
            break;
        case SamplingFrequency_88200:
            audioFrequencyValue = 88200;
            break;
        case SamplingFrequency_64000:
            audioFrequencyValue = 64000;
            break;
        case SamplingFrequency_48000:
            audioFrequencyValue = 48000;
            break;
        case SamplingFrequency_44100:
            audioFrequencyValue = 44100;
            break;
        case SamplingFrequency_32000:
            audioFrequencyValue = 32000;
            break;
        case SamplingFrequency_24000:
            audioFrequencyValue = 24000;
            break;
        case SamplingFrequency_22050:
            audioFrequencyValue = 22050;
            break;
        case SamplingFrequency_16000:
            audioFrequencyValue = 16000;
            break;
        case SamplingFrequency_12000:
            audioFrequencyValue = 12000;
            break;
        case SamplingFrequency_11025:
            audioFrequencyValue = 11025;
            break;
        case SamplingFrequency_8000:
            audioFrequencyValue = 8000;
            break;
        case SamplingFrequency_7350:
            audioFrequencyValue = 7350;
            break;
            
        default:
            audioFrequencyValue = 0;
            break;
    }
    
    return audioFrequencyValue;
}

@end
