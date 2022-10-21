//
//  VLCPlayerView.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/26.
//

#import "VLCPlayerView.h"

@interface VLCPlayerView ()

@property(nonatomic,strong)UIView * videoView;
@property (nonatomic, strong) UIButton *backBtn;
//@property(nonatomic,strong)VLCMediaPlayer * player;

@end

@implementation VLCPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self addSubview:self.videoView];
        
        [self addSubview:self.backBtn];
        self.backBtn.frame = CGRectMake(CGRectGetWidth(frame) - 80, 0, 80, 80);
        
        //[self.player play];
    }
    return self;
}

- (void)didClickBackButton:(UIButton *)btn
{
    [self removeFromSuperview];
}

- (UIButton *)backBtn
{
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"HH.BootView.Cancel"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(didClickBackButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

-(UIView *)videoView{
    if (!_videoView) {
        _videoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        _videoView.backgroundColor = [UIColor blackColor];
    }
    return _videoView;
}
//-(VLCMediaPlayer *)player{
//    if (!_player) {
//        //缓存策略设置
//        //rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4
//        //rtsp://192.168.2.1/live2
//        NSDictionary * dict=@{@"network-caching":@"100"};
//        VLCMedia * media=[VLCMedia mediaWithURL:[NSURL URLWithString:@"rtsp://192.168.2.1/live2"]];
//        media.delegate = self;
//        [media addOptions:dict];
//        _player = [[VLCMediaPlayer alloc] init];
//        //设置硬件解码
//        //[_player setDeinterlaceFilter:@"blend"];
//        _player.media=media;
//        _player.drawable = self.videoView;
//        _player.media.delegate = self;
//    }
//    
//    return _player;
//}

@end
