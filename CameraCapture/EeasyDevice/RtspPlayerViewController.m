//
//  RtspPlayerViewController.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/29.
//

#import "RtspPlayerViewController.h"
#import "MediaDecoder.h"
#import "MQVideoPreview.h"

@interface RtspPlayerViewController ()

@property (nonatomic, strong) UIView *headView;
@property (nonatomic, strong) MediaDecoder *mediaDecoder;
@property (nonatomic, strong) MQVideoPreview *videoPreview;
@property (nonatomic, strong) UIButton *backBtn;

@end

@implementation RtspPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.view addSubview:self.videoPreview];
    
    [self.view addSubview:self.headView];
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = CGRectGetWidth(self.view.frame);
    CGFloat h = 60;
    self.headView.frame = CGRectMake(x, y, w, h);
    self.headView.hidden = YES;
    
    [self.headView addSubview:self.backBtn];
    x = CGRectGetWidth(self.view.frame) - (16 + 44);
    y = 0;
    w = 60;
    h = 60;
    self.backBtn.frame = CGRectMake(x, y, w, h);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //开始播放
    [self startDev];
}

- (void)viewDidDisappear:(BOOL)animated
{
    
    self.videoPlayCancelBlock();
    [super viewDidDisappear:animated];
}

- (void)didClickBackBtn:(UIButton *)btn
{
    [self stopDev];
    self.mediaDecoder = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)startDev
{
    if (!self.mediaDecoder) {
        self.mediaDecoder = [[MediaDecoder alloc] init];
    }
    
    //修改播放器的播放地址
    //self.mediaDecoder.rtspString = @"rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4";
    self.mediaDecoder.rtspString = @"rtsp://192.168.2.1/live3";
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

#pragma mark - Touch
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    _headView.hidden = !_headView.hidden;
}

#pragma mark - 懒加载
- (UIView *)headView
{
    if (!_headView) {
        _headView = [[UIView alloc] init];
        _headView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.85];
    }
    return _headView;
}

- (MQVideoPreview *)videoPreview
{
    if (!_videoPreview) {
        _videoPreview = [[MQVideoPreview alloc] initWithFrame:self.view.frame];
        [_videoPreview.backgroundView setImage:nil];
        _videoPreview.backgroundView.backgroundColor = [UIColor blackColor];
    }
    return _videoPreview;
}

- (UIButton *)backBtn
{
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"HH.BootView.Cancel"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(didClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (void)dealloc
{
    NSLog(@"%s",__func__);
}

@end
