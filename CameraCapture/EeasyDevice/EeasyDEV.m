//
//  EeasyDEV.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/24.
//

#import "EeasyDEV.h"
#import "MediaDecoder.h"
#import "McuSocketManager.h"

@interface EeasyDEV ()

@property (nonatomic, strong) MediaDecoder *mediaDecoder;

@property (nonatomic, strong) McuSocketManager *ctrlClient;

@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation EeasyDEV


-(instancetype)init{
    if (self = [super init]) {
        self.host = @"192.168.2.1";
        self.ctrlPort = 8887;
        self.cmdPort = 8886;
        
        [self initMCUControlDataSocket];
    }
    return self;
}

- (void)initMCUControlDataSocket
{
    self.ctrlClient = [[McuSocketManager alloc] init];
    
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t heartQueue = dispatch_queue_create("HeartQueue", 0);
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, heartQueue);
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer, ^{
        
        if (weakSelf.ctrlClient.isConnected) {
            [weakSelf.ctrlClient sendPingHeartPack];
        }
        else{
            [weakSelf.ctrlClient connectToServer];
        }
        
    });
    
}

- (void)startDev
{
    if (!self.mediaDecoder) {
        self.mediaDecoder = [[MediaDecoder alloc] init];
    }
    //默认开始时没有开启接收视频流
    self.mediaDecoder.isOpenTheVideoStream = NO;
    
    [self.mediaDecoder startVideo];

    [self.mediaDecoder startAudio];
}

- (void)stopDev
{
    [self.mediaDecoder stopVideo];
    
    [self.mediaDecoder stopAudio];
}


- (void)connectToSocket:(BOOL)isON
{
    if (isON) {
        dispatch_resume(self.timer);
        [self.ctrlClient connectToServer];
    }
    else{
        dispatch_suspend(self.timer);
    }
}

- (void)disconnectSocket
{
    [self.ctrlClient disConnected];
    dispatch_suspend(self.timer);
}

- (void)sendCtrlData:(NSData *)data
{
    NSLog(@"data:%@",data);
    [self.ctrlClient sendData:data];
}







@end
