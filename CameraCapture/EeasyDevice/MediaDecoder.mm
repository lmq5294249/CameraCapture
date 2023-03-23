//
//  MediaDecoder.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/29.
//

#import "MediaDecoder.h"
#import "Decoder.h"
#import "KxMovieDecoder.h"
#import "AudioQueuePlay.h"
#import "CarEyeAudioPlayer.h"
#include "FFmpegAudioDecoder.h"
#include "AACDecoder.h"
#include <set>
#include <string.h>
#include <vector>
#include <pthread.h>

struct FrameInfo {
    FrameInfo() : pBuf(NULL), frameLen(0), type(0), timeStamp(0), width(0), height(0){}
    
    unsigned char *pBuf;
    int frameLen;
    int type;
    CGFloat timeStamp;
    int width;
    int height;
};


@interface MediaDecoder ()
{
    RtspFrameInfo frameInfo;
    FFmpegAudioHandle *_audioDecHandle;  // 音频解码句柄
    RtspMediaInfo *_mediaInfo;   // 媒体信息
    std::multiset<FrameInfo *> audioFrameSet;
    NSMutableArray <KxAudioFrame *> *_audioFrames;
    NSUInteger _currentAudioFramePos;
    NSData *_currentAudioFrameSamples;
    CGFloat _moviePosition;
    // 互斥锁
    pthread_mutex_t mutexAudioFrame;
    void *_videoDecHandle;  // 视频解码句柄
    CGFloat lastFrameTimeStamp;
    NSTimeInterval beforeDecoderTimeStamp;
    NSTimeInterval afterDecoderTimeStamp;
    
    AudioQueuePlay *audioPlayer;
}
@property (nonatomic, strong) Decoder *h264Decoder;
@property (nonatomic, readwrite) BOOL running;
@property (nonatomic, strong) NSThread *audioThread;
@property (nonatomic, assign) BOOL audioPlaying;

@end

@implementation MediaDecoder

- (instancetype)init
{
    if (self = [super init]) {
        [self initVideoDecoder];
        [self initAudioDecoder];
        [self initFrameParameter];
    }
    return self;
}

- (void)initVideoDecoder
{
//    self.rtspString = @"rtsp://192.168.2.1/live2";
//    self.rtspString = @"rtsp://192.168.1.100:554/live";
    self.rtspString = @"rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4";
    [RtspConnection sharedRtspConnection].delegate = self;
    //初始化解码，设置刷图层
    self.h264Decoder = [[Decoder alloc]init];
}

- (void)initAudioDecoder
{
    // 动态方式是采用pthread_mutex_init()函数来初始化互斥锁
    pthread_mutex_init(&mutexAudioFrame, 0);
    _audioDecHandle = NULL;
    self.enableAudio = YES;
    _audioFrames = [NSMutableArray array];
    [self initFrameParameter];
}

- (void)initFrameParameter
{
    //目前只能手动配置录音的相关参数u，后续可通过packet数据包解析参数
    frameInfo.codec = RTSP_AUDIO_CODE_AAC;
    frameInfo.type = 0;
    frameInfo.sample_rate = 8000;
    frameInfo.channels = 1;
    frameInfo.bits_per_sample = 16;
    
//    frameInfo.sample_rate = 12000;
//    frameInfo.channels = 2;
//    frameInfo.bits_per_sample = 16;
}

#pragma mark - 播放控制
- (void)startVideo
{
    if (!self.isOpenTheVideoStream) {
        [self connectRtsp];
        self.isOpenTheVideoStream = YES;
    }
}

- (void)stopVideo
{
    if ([[RtspConnection sharedRtspConnection] isConnecting] && !self.isCameraBroken)
    {
        [[RtspConnection sharedRtspConnection] close_rtsp_client];
    }
}

- (void)connectRtsp {
    [RtspConnection sharedRtspConnection].delegate = self;
    [[RtspConnection shareStore] start_rtsp_session:NO rtspAddress:self.rtspString];
    NSLog(@"开启rtsp");
}

- (void)startAudio {
    self.audioPlaying = YES;
    self.running = YES;
    self.audioThread = [[NSThread alloc] initWithTarget:self selector:@selector(runloopForAudio) object:nil];
    [self.audioThread start];
    
//    [CarEyeAudioPlayer sharedInstance].sampleRate = frameInfo.sample_rate;
//    [CarEyeAudioPlayer sharedInstance].channel = frameInfo.channels;
//    [CarEyeAudioPlayer sharedInstance].source = self;
//    [CarEyeAudioPlayer sharedInstance].outputBlock = ^(SInt16 *outData, UInt32 numFrames, UInt32 numChannels){
//        [weakSelf pushAudioData:outData numFrames:numFrames numChannels:numChannels];
//    };
//    [[CarEyeAudioPlayer sharedInstance] play];
}

- (void)stopAudio {
//    if ([CarEyeAudioPlayer sharedInstance].source == self) {
//        [[CarEyeAudioPlayer sharedInstance] stop];
//        [CarEyeAudioPlayer sharedInstance].outputBlock = nil;
//    }
    [audioPlayer stopPlay];
    
    self.audioPlaying = NO;
    self.running = NO;
    self.audioThread = nil;
    [self.audioThread cancel];
}


#pragma mark - rtspdelegate
//MARK:设置音频解码
-(void)setAudioFrameDecodeInfo:(RtspFrameInfo)audioFameInfo
{
    //根据live555解析数据获取音频解码信息
    if (audioFameInfo.sample_rate) {
        frameInfo.codec = audioFameInfo.codec;
        frameInfo.type = 0;
        frameInfo.sample_rate = audioFameInfo.sample_rate;
        frameInfo.channels = audioFameInfo.channels;
        frameInfo.bits_per_sample = audioFameInfo.bits_per_sample;
        NSLog(@"%@ : 音频采样率 = %d",NSStringFromClass([self class]),frameInfo.sample_rate);
        NSLog(@"%@ : 音频通道数 = %d",NSStringFromClass([self class]),frameInfo.channels);
        NSLog(@"%@ : 音频采样位数 = %d",NSStringFromClass([self class]),frameInfo.bits_per_sample);
        
        __weak typeof(self) weakSelf = self;
        audioPlayer = [[AudioQueuePlay alloc] init];
        [audioPlayer setAudioPlayerSampleRate:frameInfo.sample_rate mChannelsPerFrame:frameInfo.channels];
        audioPlayer.outputBlock = ^(SInt16 *outData, UInt32 numFrames, UInt32 numChannels) {
            [weakSelf pushAudioData:outData numFrames:numFrames numChannels:numChannels];
        };
        [audioPlayer fillNullData];//需要填充空包后才开始播放
        [audioPlayer startPlay];
    }
}


-(void)decodeNalu:(uint8_t *)buffer Size:(int)size
{
    int startCodeData = (buffer[0] & 0xFF);
    if (startCodeData == 0x00) {
        uint8_t *temp_data;
//        NSData *data1 = [NSData dataWithBytes:buffer length:size];
        temp_data =(uint8_t *) malloc(size-4);
        memcpy(temp_data, buffer + 4, size - 4);
//        NSData *data2 = [NSData dataWithBytes:temp_data length:size - 4];
        [_h264Decoder parseAndDecodeH264Nalu:buffer withSize:size withoutStartCode:temp_data];
        free(temp_data);
        temp_data = nil;
    }
    else{
        uint8_t *temp_data;
        temp_data =(uint8_t *) malloc(size+4);
        uint8_t startCode[] = {0x00, 0x00, 0x00, 0x01};
        memcpy(temp_data, startCode, sizeof(startCode));
        memcpy(temp_data+sizeof(startCode), buffer, size);
        //    if (_mp4Helper) {
        //        [_mp4Helper doRunloop:temp_data Size:size+4];
        //    }
        
        [_h264Decoder decodeNalu:temp_data withSize:size+4 withoutStartCode:buffer];
        
        free(temp_data);
        temp_data = nil;
    }

    if (_isCameraBroken) {
        _isCameraBroken = NO;
    }
}

-(void)decodeAudioUnit:(uint8_t *)buffer Size:(int)size
{
    char *temp_data = (char *) malloc(size);
    memcpy(temp_data, buffer, size);
    NSData *rawAAC = [NSData dataWithBytes:temp_data length:size];
    NSLog(@"音频大小:%d",(int)size);
    RtspFrameFlag frameType = RTSP_AFRAME_FLAG;
    frameInfo.length = size;
    [self pushFrame:temp_data frameInfo:&frameInfo type:frameType];
    
    free(temp_data);
}

- (void)gotSps:(uint8_t *)sps SpsSize:(int)spsSize Pps:(uint8_t *)pps PpsSize:(int)ppsSize {
    
}


- (void)pushFrame:(char *)pBuf frameInfo:(RtspFrameInfo *)info type:(int)type {
    if (!_running || pBuf == NULL) {
        return;
    }
    
    FrameInfo *frameInfo = (FrameInfo *)malloc(sizeof(FrameInfo));
    frameInfo->type = type;
    frameInfo->frameLen = info->length;
    frameInfo->pBuf = new unsigned char[info->length];
    frameInfo->width = info->width;
    frameInfo->height = info->height;
    // 毫秒为单位(1秒=1000毫秒 1秒=1000000微秒)
    //    frame->timeStamp = info->timestamp_sec + (float)(info->timestamp_usec / 1000.0) / 1000.0;
    frameInfo->timeStamp = info->timestamp_sec * 1000 + info->timestamp_usec / 1000.0;
    
    memcpy(frameInfo->pBuf, pBuf, info->length);
    
    // 根据时间戳排序
    if (type == RTSP_AFRAME_FLAG) {
        pthread_mutex_lock(&mutexAudioFrame);    // 加锁
        audioFrameSet.insert(frameInfo);
        pthread_mutex_unlock(&mutexAudioFrame);  // 解锁
    }
}

#pragma mark - 子线程音频解码方法
- (void)setMediaInfo:(RtspMediaInfo *)mediaInfo {
    _mediaInfo = mediaInfo;
}
- (void)runloopForAudio {
    
    while (_running) {
        
        // ------------ 加锁mutexFrame ------------
        pthread_mutex_lock(&mutexAudioFrame);
        
        int count = (int) audioFrameSet.size();
        if (count == 0) {
            pthread_mutex_unlock(&mutexAudioFrame);
            usleep(5 * 1000);
            continue;
        }
        
        FrameInfo *frame = *(audioFrameSet.begin());
        audioFrameSet.erase(audioFrameSet.begin());
        
        pthread_mutex_unlock(&mutexAudioFrame);
        // ------------ 解锁mutexFrame ------------
        
        if (self.enableAudio) {
            [self decodeAudioFrame:frame];
        }
        
        delete []frame->pBuf;
        delete frame;
    }
    
    [self removeAudioFrameSet];
    
    if (_audioDecHandle != NULL) {
        FFmpegAudioDecodeClose(_audioDecHandle);
        _audioDecHandle = NULL;
    }
    
}

- (void)removeAudioFrameSet {
    pthread_mutex_lock(&mutexAudioFrame);
    
    std::set<FrameInfo *>::iterator it = audioFrameSet.begin();
    while (it != audioFrameSet.end()) {
        FrameInfo *frameInfo = *it;
        delete []frameInfo->pBuf;
        delete frameInfo;
        
        it++;   // 很关键, 主动前移指针
    }
    audioFrameSet.clear();
    
    pthread_mutex_unlock(&mutexAudioFrame);
}

- (void)decodeAudioFrame:(FrameInfo *)audioInfo {
    if (_audioDecHandle == NULL) {
        RtspMediaInfo mediaInfo;
        mediaInfo.u32AudioCodec = frameInfo.codec;
        mediaInfo.u32AudioSamplerate = frameInfo.sample_rate;
        mediaInfo.u32AudioChannel = frameInfo.channels;
        mediaInfo.u32AudioBitsPerSample = frameInfo.bits_per_sample;
        _audioDecHandle = FFmpegAudioDecoderCreate(mediaInfo);
        //        _audioDecHandle = CarEyeAudioDecoder(self.mediaInfo->u32AudioCodec, self.mediaInfo->u32AudioSamplerate, self.mediaInfo->u32AudioChannel, 16);
    }
    if (_audioDecHandle == NULL) {
        return;
    }
    unsigned char pcmBuf[10 * 1024] = { 0 };
    int pcmLen = 0;
    int ret = FFmpegAudioDecode((FFmpegAudioHandle *)_audioDecHandle, audioInfo->pBuf, 0, audioInfo->frameLen, pcmBuf, &pcmLen);
    
    if (ret == 0) {
        @autoreleasepool {
            KxAudioFrame *frame = [[KxAudioFrame alloc] init];
            frame.samples = [NSData dataWithBytes:pcmBuf length:pcmLen];
            frame.position = audioInfo->timeStamp;
            //            NSData *pcmData = [NSData dataWithBytes:pcmBuf length:pcmLen];
//            NSLog(@"------音频解码成功PCM:%lu------",(unsigned long)frame.samples.length);
            [self pushFrame:frame];
        }
    }
}

- (void)pushFrame:(KxMovieFrame *)frame {
    if (frame.type == KxMovieFrameTypeAudio) {
        @synchronized(_audioFrames) {
            if (!self.audioPlaying) {
                [_audioFrames removeAllObjects];
                return;
            }
            
            [_audioFrames addObject:(KxAudioFrame *)frame];
        }
    }
}

- (void)pushAudioData:(SInt16 *)outData numFrames: (UInt32)numFrames numChannels: (UInt32)numChannels {
    @autoreleasepool {
        while (numFrames > 0) {
            if (_currentAudioFrameSamples == nil) {
                @synchronized(_audioFrames) {
                    NSUInteger count = _audioFrames.count;
                    if (count > 0) {
                        KxAudioFrame *frame = _audioFrames[0];
                        CGFloat differ = _moviePosition - frame.position;
                        
                        [_audioFrames removeObjectAtIndex:0];
                        
                        if (differ > 5 && count > 1) {
                            
                            NSLog(@"audio skip movPos = %.4f audioPos = %.4f", _moviePosition, frame.position);
                            continue;
                        }
                        if (count > 5) {
                            [_audioFrames removeObjectsInRange:NSMakeRange(0, count - 6)];
                            continue;
                        }
                        
                        NSLog(@"%@:未播放数组AudioFrame的数量: %lu",NSStringFromClass([self class]),(unsigned long)_audioFrames.count);
                        
                        _currentAudioFramePos = 0;
                        _currentAudioFrameSamples = frame.samples;
//                        NSLog(@"%@:currentAudioFrameSamples: %lu",NSStringFromClass([self class]),(unsigned long)_currentAudioFrameSamples.length);
                    }
                }
            }
            
            if (_currentAudioFrameSamples) {
                const void *bytes = (Byte *)_currentAudioFrameSamples.bytes + _currentAudioFramePos;
                const NSUInteger bytesLeft = (_currentAudioFrameSamples.length - _currentAudioFramePos);
                const NSUInteger frameSizeOf = numChannels * sizeof(SInt16);
                const NSUInteger bytesToCopy = MIN(numFrames * frameSizeOf, bytesLeft);
                const NSUInteger framesToCopy = bytesToCopy / frameSizeOf;
                
                memcpy(outData, bytes, bytesToCopy);
                numFrames -= framesToCopy;
                outData += framesToCopy * numChannels;
                if (bytesToCopy < bytesLeft) {
                    _currentAudioFramePos += bytesToCopy;
                } else {
                    _currentAudioFrameSamples = nil;
                }
            } else {
                memset(outData, 0, numFrames * numChannels * sizeof(SInt16));
                break;
            }
        }
    }
}


- (void)dealloc
{
    NSLog(@"%s",__func__);
}

@end
