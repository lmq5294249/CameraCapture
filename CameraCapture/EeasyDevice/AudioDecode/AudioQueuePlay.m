//
//  AudioQueuePlay.m
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/2.
//

#import "AudioQueuePlay.h"
#define MIN_SIZE_PER_FRAME 2048
#define QUEUE_BUFFER_SIZE 3      //队列缓冲个数

@interface AudioQueuePlay() {
    
    AudioQueueRef audioQueue;                                 //音频播放队列
    AudioStreamBasicDescription _audioDescription;
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE]; //音频缓存
    BOOL audioQueueBufferUsed[QUEUE_BUFFER_SIZE];             //判断音频缓存是否在使用
    NSLock *sysnLock;
    NSMutableData *tempData;
    OSStatus osState;
    
    SInt16 * _outData;
}
@property (nonatomic, assign) BOOL isRuning;
@end

@implementation AudioQueuePlay

- (instancetype)init
{
    self = [super init];
    if (self) {
        sysnLock = [[NSLock alloc]init];
        _outData = (SInt16 *)calloc(4096 * 2, sizeof(SInt16));
    }
    return self;
}

- (void)setAudioPlayerSampleRate:(unsigned int)sampleRate mChannelsPerFrame:(unsigned int)channels
{
    // 播放PCM使用
    if (_audioDescription.mSampleRate <= 0) {
        //设置音频参数
        _audioDescription.mSampleRate = (Float64)sampleRate;//采样率
        _audioDescription.mFormatID = kAudioFormatLinearPCM;
        // 下面这个是保存音频数据的方式的说明，如可以根据大端字节序或小端字节序，浮点数或整数以及不同体位去保存数据
        _audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        //1单声道 2双声道
        _audioDescription.mChannelsPerFrame = (UInt32)channels;
        //每一个packet一侦数据,每个数据包下的桢数，即每个数据包里面有多少桢
        _audioDescription.mFramesPerPacket = 1;
        //每个采样点16bit量化 语音每采样点占用位数
        _audioDescription.mBitsPerChannel = 16;
        _audioDescription.mBytesPerFrame = (_audioDescription.mBitsPerChannel / 8) * _audioDescription.mChannelsPerFrame;
        //每个数据包的bytes总数，每桢的bytes数*每个数据包的桢数
        _audioDescription.mBytesPerPacket = _audioDescription.mBytesPerFrame * _audioDescription.mFramesPerPacket;
    }
    
    // 使用player的内部线程播放 新建输出
    AudioQueueNewOutput(&_audioDescription, AudioPlayerAQInputCallback, (__bridge void * _Nullable)(self), nil, 0, 0, &audioQueue);
    
    // 设置音量
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    
    // 初始化需要的缓冲区
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        audioQueueBufferUsed[i] = false;
        
        osState = AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);
        
        printf("第 %d 个AudioQueueAllocateBuffer 初始化结果 %d (0表示成功)", i + 1, osState);
    }
    
    osState = AudioQueueStart(audioQueue, NULL);
    if (osState != noErr) {
        printf("AudioQueueStart Error");
    }
}

- (void)resetPlay {
    if (audioQueue != nil) {
        AudioQueueReset(audioQueue);
    }
}

- (void)startPlay
{
    AudioQueueStart(audioQueue, NULL);
}

- (void)pausePlay
{
    AudioQueuePause(audioQueue);
}

- (void)stopPlay
{
    AudioQueueStop(audioQueue, true);
}

// 播放相关
-(void)playWithData:(NSData *)data {
    
    [sysnLock lock];
    
    tempData = [NSMutableData new];
    [tempData appendData: data];
//    NSMutableData *recData = [[NSMutableData alloc] initWithData:data];
//    tempData  = [recData subdataWithRange:NSMakeRange(0, MIN_SIZE_PER_FRAME)];
    // 得到数据
    NSUInteger len = tempData.length;
    Byte *bytes = (Byte*)malloc(len);
    [tempData getBytes:bytes length: len];
    
    int i = 0;
    while (true) {
        if (!audioQueueBufferUsed[i]) {
            audioQueueBufferUsed[i] = true;
            NSLog(@"打印i = %d",i);
            break;
        }else {
            i++;
            if (i >= QUEUE_BUFFER_SIZE) {
                i = 0;
            }
        }
    }
    
    audioQueueBuffers[i] -> mAudioDataByteSize =  (unsigned int)len;
    // 把bytes的头地址开始的len字节给mAudioData
    memcpy(audioQueueBuffers[i] -> mAudioData, bytes, len);
    
    //
    free(bytes);
    AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffers[i], 0, NULL);
    
    printf("本次播放数据大小: %lu", len);
    [sysnLock unlock];
}

// ************************** 回调 **********************************

// 回调回来把buffer状态设为未使用
static void AudioPlayerAQInputCallback(void* inUserData,AudioQueueRef audioQueueRef, AudioQueueBufferRef audioQueueBufferRef) {
    
    AudioQueuePlay* player = (__bridge AudioQueuePlay*)inUserData;
    [player fillBuf:audioQueueBufferRef];
}

- (void)fillBuf:(AudioQueueBufferRef)audioQueueBufferRef
{
//    if (_outputBlock != nil) {
//        for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
//            if (audioQueueBufferRef == audioQueueBuffers[i]) {
//                //audioQueueBufferUsed[i] = false;
//                NSLog(@"填充数据i = %d",i);
//                //填充数据
//            }
//        }
//    }
    
//    NSLog(@"%@ : 填充音频数据",NSStringFromClass([self class]));
    UInt32 inNumberFrames = 512;
    UInt32 channelNum = 2;
    _outputBlock(_outData, inNumberFrames, channelNum);
    audioQueueBufferRef -> mAudioDataByteSize =  (unsigned int)(inNumberFrames * channelNum * sizeof(SInt16));
    memcpy(audioQueueBufferRef -> mAudioData, _outData, inNumberFrames * channelNum * sizeof(SInt16));
    AudioQueueEnqueueBuffer(audioQueue, audioQueueBufferRef, 0, NULL);
}

//**************************/添加静音包  当来源音频数据不足的时候 往里面添加静音包**********************************
- (void)fillNullData{
    _isRuning = YES;
    if(_isRuning) {
        BOOL isNull =YES;
        for(int i =0; i<QUEUE_BUFFER_SIZE; i++) {
            BOOL used = audioQueueBufferUsed[i];
            if(used) {
                isNull =NO;
            }
            
        }
        if(isNull) {
            //填空数据包
        //  NSLog(@"填空数据包");
            NSMutableData *tmpData = [[NSMutableData alloc] init];
            for(int i=0; i<600; i++) {
                [tmpData appendBytes:"\0X00"length:1];
                
            }
            //开始往AudioQueueBuffer填充空包确保开始播放
            for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
                [self playWithData:tmpData];
            }
        }
    }
}



// ************************** 内存回收 **********************************

- (void)dealloc {
    
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue,true);
    }
    
    audioQueue = nil;
    sysnLock = nil;
    
    free(_outData);
}
@end
