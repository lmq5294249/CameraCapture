//
//  TationVideoPlayerView.h
//  Hohem Pro
//
//  Created by jolly on 2019/11/28.
//  Copyright © 2019 jolly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TationVideoPlayerViewDelegate;

@interface TationVideoPlayerView : UIView

- (void)updateVideoUrl:(NSURL *)videoUrl;
- (void)startPlay;
- (void)stopPlay;

@end

@protocol TationVideoPlayerViewDelegate <NSObject>

- (void)TationVideoPlayerViewDelegate:(TationVideoPlayerView *)playerView function:(NSString *)function value:(NSString *)value;

@end

NS_ASSUME_NONNULL_END
