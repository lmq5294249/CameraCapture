//
//  TationVideoPlayerView.m
//  Hohem Pro
//
//  Created by jolly on 2019/11/28.
//  Copyright © 2019 jolly. All rights reserved.
//

#import "TationVideoPlayerView.h"

@interface TationVideoPlayerView()

@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) dispatch_queue_t progressQueue;
@end

@implementation TationVideoPlayerView

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    [self initAttribute];
    [self setUpUI];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    
    self = [super initWithCoder:coder];
    
    [self initAttribute];
    [self setUpUI];
    
    return self;
}

- (void)dealloc {
    
    NSLog(@"%s",__FUNCTION__);
}

- (void)initAttribute {
    
    
}

- (void)setUpUI {
    
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.playerLayer) {
        
        self.playerLayer.frame = self.bounds;
    }
}

- (void)updateVideoUrl:(NSURL *)videoUrl {
    
    self.videoUrl = videoUrl;
}

- (void)startPlay {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.progressQueue = dispatch_queue_create("HohemPro.TationVideoPlayerView.progressQueue", DISPATCH_QUEUE_SERIAL);
        __weak TationVideoPlayerView *weakSelf = self;
        
        AVURLAsset *movieAsset = [AVURLAsset assetWithURL:self.videoUrl];
        AVPlayerItem *playItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        self.player = [[AVPlayer alloc]initWithPlayerItem:playItem];
        [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 30) queue:self.progressQueue usingBlock:^(CMTime time) {
            CGFloat progress = CMTimeGetSeconds(weakSelf.player.currentItem.currentTime) / CMTimeGetSeconds(weakSelf.player.currentItem.duration);
            
            if (progress == 1.0) {
                
                [weakSelf.player seekToTime:CMTimeMake(0, 30)];
                [weakSelf.player play];
            }
        }];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.layer addSublayer:self.playerLayer];
        self.playerLayer.frame = self.bounds;
        [self.player play];
    });
}

- (void)stopPlay {
    
    [self.player pause];
    [self.player seekToTime:CMTimeMake(0, 1)];
    self.player = nil;
}

@end
