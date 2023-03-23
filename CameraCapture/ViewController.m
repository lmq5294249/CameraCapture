//
//  ViewController.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/24.
//

#import "ViewController.h"
#import "EeasyDEV.h"
#import "TationToolManager.h"
#import "CameraSocketManager.h"
#import "MediaTableView.h"
#import "VLCPlayerView.h"
#import "UpgradeSocketManager.h"
#import "McuSocketManager.h"
#import "MQLogInfo.h"
#import "MBProgressHUD.h"
#import "MQVideoPreview.h"
#import "RtspPlayerViewController.h"

#define FirmwarePath   [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Firmware.bundle/version"]

@interface ViewController ()<UITextFieldDelegate,DeviceDataDelegate,MediaButtonDelegate>
{
    MBProgressHUD *progressHud;
}
@property (nonatomic, strong) MQVideoPreview *videoPreview;
@property (nonatomic, strong) RtspPlayerViewController *rtspPlayer;
@property (nonatomic, strong) UIImageView *imgBackGround;
@property (nonatomic, strong) EeasyDEV *cameraDev;

@property (nonatomic, strong) UIButton *startDevBtn;
@property (nonatomic, strong) UIButton *takePhotoBtn;
@property (nonatomic, strong) UIButton *videoRecordBtn;
@property (nonatomic, strong) UIButton *photoListBtn;
@property (nonatomic, strong) UIButton *videoListBtn;
@property (nonatomic, strong) UIButton *stopPlaybackBtn;
@property (nonatomic, strong) UIButton *flipPreviewBtn;
@property (nonatomic, strong) UIButton *mirrorPreviewBtn;
@property (nonatomic, strong) UIButton *wifiBtn;
@property (nonatomic, strong) UIButton *upgradeBtn;
@property (nonatomic, strong) UIButton *formatBtn;

@property (nonatomic, strong) UIButton *leftCtrlBtn;
@property (nonatomic, strong) UIButton *rightCtrlBtn;
@property (nonatomic, strong) UIButton *stopBtn;

@property (nonatomic, strong) MediaTableView *mediaTableView;
@property (nonatomic, strong) VLCPlayerView *vlcPlayer;

@property (nonatomic, strong) CameraSocketManager *cameraSocket;
@property (nonatomic, strong) McuSocketManager *mcuSocket;
@property (nonatomic, strong) UpgradeSocketManager *upgradeClient;

@property (nonatomic, strong) UIView *wifiSettingView;
@property (nonatomic, strong) UILabel *wifiNameLabel;
@property (nonatomic, strong) UITextField *wifiNameTextField;
@property (nonatomic, copy) NSString *wifiNameStr;
@property (nonatomic, strong) UILabel *wifiPSWLabel;
@property (nonatomic, strong) UITextField *wifiPSWTextField;
@property (nonatomic, copy) NSString *wifiPSWStr;
@property (nonatomic, assign) BOOL isNextStep;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *confirmBtn;

@property (nonatomic, strong) UITextView *logTextView;

@property (nonatomic, assign) BOOL isXPhone;

@property (nonatomic) dispatch_source_t timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initAttribute];
    [self setupUI];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self CheckXPhone];
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = CGRectGetWidth(self.view.frame);
    CGFloat h = CGRectGetHeight(self.view.frame);
    self.imgBackGround.frame = CGRectMake(x, y, w, h);
    
    CGFloat x_offset = 0;
    if (self.isXPhone) {
        x_offset = 40;
    }
    
    x = x_offset + Tation_AutoFitWithX(16);
    y = Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.startDevBtn.frame = CGRectMake(x, y, w, h);
    
    y = CGRectGetMaxY(self.startDevBtn.frame) + Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.takePhotoBtn.frame = CGRectMake(x, y, w, h);

    y = CGRectGetMaxY(self.takePhotoBtn.frame) + Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.videoRecordBtn.frame = CGRectMake(x, y, w, h);
    
    y = CGRectGetMaxY(self.videoRecordBtn.frame) + Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.photoListBtn.frame = CGRectMake(x, y, w, h);
    
    y = CGRectGetMaxY(self.photoListBtn.frame) + Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.videoListBtn.frame = CGRectMake(x, y, w, h);
    
    y = CGRectGetMaxY(self.videoListBtn.frame) + Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.stopPlaybackBtn.frame = CGRectMake(x, y, w, h);
    
    //---------------------------------------------------------------------------------------
    x = CGRectGetWidth(self.view.frame) - Tation_AutoFitWithX(16) - Tation_AutoFitWithX(80);
    y = Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.flipPreviewBtn.frame = CGRectMake(x, y, w, h);
    
    x = CGRectGetWidth(self.view.frame) - Tation_AutoFitWithX(16) - Tation_AutoFitWithX(80);
    y = CGRectGetMaxY(self.flipPreviewBtn.frame) + Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.mirrorPreviewBtn.frame = CGRectMake(x, y, w, h);
    
    x = CGRectGetWidth(self.view.frame) - Tation_AutoFitWithX(16) - Tation_AutoFitWithX(80);
    y = CGRectGetMaxY(self.mirrorPreviewBtn.frame) + Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.wifiBtn.frame = CGRectMake(x, y, w, h);
    
    x = CGRectGetWidth(self.view.frame) - Tation_AutoFitWithX(16) - Tation_AutoFitWithX(80);
    y = CGRectGetMaxY(self.wifiBtn.frame) + Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.upgradeBtn.frame = CGRectMake(x, y, w, h);
    
    x = CGRectGetWidth(self.view.frame) - Tation_AutoFitWithX(16) - Tation_AutoFitWithX(80);
    y = CGRectGetMaxY(self.upgradeBtn.frame) + Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.formatBtn.frame = CGRectMake(x, y, w, h);
    
    //---------------------------------------------------------------------------------------
    x = CGRectGetMaxY(self.startDevBtn.frame) + Tation_AutoFitWithX(16) + Tation_AutoFitWithX(80)*2;
    y = CGRectGetMaxY(self.videoListBtn.frame) + Tation_AutoFitWithX(16);
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.leftCtrlBtn.frame = CGRectMake(x, y, w, h);
    
    x = CGRectGetMaxY(self.startDevBtn.frame) + Tation_AutoFitWithX(16)*2 + Tation_AutoFitWithX(80)*3;
    y = CGRectGetMaxY(self.videoListBtn.frame) + Tation_AutoFitWithX(16);;
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.stopBtn.frame = CGRectMake(x, y, w, h);
    
    x = CGRectGetMaxY(self.startDevBtn.frame) + Tation_AutoFitWithX(16)*3 + Tation_AutoFitWithX(80)*4;
    y = CGRectGetMaxY(self.videoListBtn.frame) + Tation_AutoFitWithX(16);;
    w = Tation_AutoFitWithX(80);
    h = Tation_AutoFitWithX(44);
    self.rightCtrlBtn.frame = CGRectMake(x, y, w, h);
    
    //---------------------------------------------------------------------------------------
    w = CGRectGetWidth(self.view.frame) * 0.6;
    h = 200;
    x = CGRectGetWidth(self.view.frame) * 0.2;
    y = 60;
    self.wifiSettingView.frame = CGRectMake(x, y, w, h);
    w = 100;
    h = 24;
    x = 16;
    y = 16;
    self.wifiNameLabel.frame = CGRectMake(x, y, w, h);
    w = 180;
    h = 24;
    x = CGRectGetMaxX(self.wifiNameLabel.frame);
    y = 16;
    self.wifiNameTextField.frame = CGRectMake(x, y, w, h);
    w = 100;
    h = 24;
    x = 16;
    y = CGRectGetMaxY(self.wifiNameLabel.frame) + 16;
    self.wifiPSWLabel.frame = CGRectMake(x, y, w, h);
    w = 180;
    h = 24;
    x = CGRectGetMaxX(self.wifiNameLabel.frame);
    y = CGRectGetMaxY(self.wifiNameLabel.frame) + 16;
    self.wifiPSWTextField.frame = CGRectMake(x, y, w, h);
    w = 120;
    h = 44;
    x = 40;
    y = CGRectGetHeight(self.wifiSettingView.frame) - 44 - h;
    self.cancelBtn.frame = CGRectMake(x, y, w, h);
    w = 120;
    h = 44;
    x = CGRectGetWidth(self.wifiSettingView.frame) - w - 40;
    y = CGRectGetHeight(self.wifiSettingView.frame) - 44 - h;
    self.confirmBtn.frame = CGRectMake(x, y, w, h);
    
    //---------------------------------------------------------------------------------------
    w = CGRectGetWidth(self.view.frame) * 0.7;
    h = CGRectGetHeight(self.view.frame)- 64.0;
    x = (CGRectGetWidth(self.view.frame) - w)/2;
    y = 64.0;
    self.logTextView.frame = CGRectMake(x, y, w, h);
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //MARK:相册权限-PHPhotoLibrary
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        if (@available(iOS 14, *)) {
            if (status == PHAuthorizationStatusLimited || status == PHAuthorizationStatusAuthorized) {
                
            }
        } else {
            // Fallback on earlier versions
            if (status == PHAuthorizationStatusDenied) {
                //NSLog(@"status:%ld",(long)status);
            } else if (status == PHAuthorizationStatusNotDetermined) {
                //NSLog(@"status:%ld",(long)status);
            } else if (status == PHAuthorizationStatusRestricted) {
                //NSLog(@"status:%ld",(long)status);
            } else if (status == PHAuthorizationStatusAuthorized) {
                //NSLog(@"status:%ld",(long)status);
                
            }
        }
    }];
    
    
    NSLog(@"viewDidAppear");
    //读取和写入文件测试
//    [MQLogInfo writeToFileWithString:@"192.168.2.1\n" fileName:@"test"];
//    NSString *readStr = [MQLogInfo readFileName:@"test"];
//    self.logTextView.text = readStr;
//
//    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
//    hud.tintColor = [UIColor whiteColor];
//    hud.contentColor = [UIColor whiteColor];
//    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
//    hud.bezelView.backgroundColor = [UIColor blackColor];
//    hud.mode = MBProgressHUDModeText;
//    hud.label.text = @"下载成功，已保存到相册";
//    [hud showAnimated:YES];
//    //[hud hideAnimated:YES afterDelay:5.5];
//    hud.removeFromSuperViewOnHide = YES;
//    [self.view addSubview:hud];
    
    {
        //测试rtsp播放器
//        self.rtspPlayer = [[RtspPlayerViewController alloc] init];
//        [self presentViewController:self.rtspPlayer animated:YES completion:nil];
    }
    
    {
        //校验时间
        [_cameraSocket connectToServer];
        [_cameraSocket sendSetupCameraSystemTimeCmd];
    }
    {
        [self.cameraDev connectToSocket:YES];
    }
}

- (void)initAttribute
{
    self.cameraDev = [[EeasyDEV alloc] init];
    
    self.cameraSocket = [[CameraSocketManager alloc] initWithHost:@"192.168.1.100" Port:8886 QueueName:"CameraSocketQueue"];
    self.cameraSocket.delegate = self;
}

- (void)setupUI
{
    [self.view addSubview:self.imgBackGround];
    [self initPreview];
    
    [self.view addSubview:self.startDevBtn];
    self.startDevBtn.layer.masksToBounds = YES;
    self.startDevBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.takePhotoBtn];
    self.takePhotoBtn.layer.masksToBounds = YES;
    self.takePhotoBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.videoRecordBtn];
    self.videoRecordBtn.layer.masksToBounds = YES;
    self.videoRecordBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.photoListBtn];
    self.photoListBtn.layer.masksToBounds = YES;
    self.photoListBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.videoListBtn];
    self.videoListBtn.layer.masksToBounds = YES;
    self.videoListBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.stopPlaybackBtn];
    self.stopPlaybackBtn.layer.masksToBounds = YES;
    self.stopPlaybackBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.flipPreviewBtn];
    self.flipPreviewBtn.layer.masksToBounds = YES;
    self.flipPreviewBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.mirrorPreviewBtn];
    self.mirrorPreviewBtn.layer.masksToBounds = YES;
    self.mirrorPreviewBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.wifiBtn];
    self.wifiBtn.layer.masksToBounds = YES;
    self.wifiBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.upgradeBtn];
    self.upgradeBtn.layer.masksToBounds = YES;
    self.upgradeBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.formatBtn];
    self.formatBtn.layer.masksToBounds = YES;
    self.formatBtn.layer.cornerRadius = 8;
    
    //wifi改名和密码修改
    [self.view addSubview:self.wifiSettingView];
    self.wifiSettingView.hidden = YES;
    self.wifiSettingView.layer.masksToBounds = YES;
    self.wifiSettingView.layer.cornerRadius = 20;
    [self.wifiSettingView addSubview:self.wifiNameLabel];
    [self.wifiSettingView addSubview:self.wifiNameTextField];
    [self.wifiSettingView addSubview:self.wifiPSWLabel];
    [self.wifiSettingView addSubview:self.wifiPSWTextField];
    [self.wifiSettingView addSubview:self.cancelBtn];
    self.cancelBtn.layer.masksToBounds = YES;
    self.cancelBtn.layer.cornerRadius = 8;
    [self.wifiSettingView addSubview:self.confirmBtn];
    self.confirmBtn.layer.masksToBounds = YES;
    self.confirmBtn.layer.cornerRadius = 8;
    
    //---------------------------------------------------------------------------------------
    [self.view addSubview:self.logTextView];
    self.logTextView.layer.masksToBounds = YES;
    self.logTextView.layer.cornerRadius = 20;
    self.logTextView.hidden  = YES;
    
    //---------------------------------------------------------------------------------------
    
    [self.view addSubview:self.leftCtrlBtn];
    self.leftCtrlBtn.layer.masksToBounds = YES;
    self.leftCtrlBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.stopBtn];
    self.stopBtn.layer.masksToBounds = YES;
    self.stopBtn.layer.cornerRadius = 8;
    
    [self.view addSubview:self.rightCtrlBtn];
    self.rightCtrlBtn.layer.masksToBounds = YES;
    self.rightCtrlBtn.layer.cornerRadius = 8;
}

- (void)initPreview
{
    self.videoPreview = [[MQVideoPreview alloc] initWithFrame:self.view.frame];
    [self.view insertSubview:self.videoPreview aboveSubview:self.imgBackGround];
}

- (void)initVLCPlayer
{
    [self.vlcPlayer = [VLCPlayerView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    [self.view addSubview:self.vlcPlayer];
}

- (void)initTimer
{
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t timerQueue = dispatch_queue_create("TimerSource", 0);
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue);
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{

            NSString *logText = [MQLogInfo readFileName:@"Upgrade"];
            if (weakSelf.logTextView.contentSize.height <= (weakSelf.logTextView.contentOffset.y + CGRectGetHeight(weakSelf.logTextView.frame))) {
                self.logTextView.text = logText;
                [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.text.length, 1)];
            }else {
                self.logTextView.text = logText;
            }
        });
    });
    dispatch_resume(self.timer);
}
#pragma mark - 方法
- (void)didClickStartPreviewBtn:(UIButton *)btn
{
    btn.selected = !btn.selected;
    if (btn.selected) {
        [self.cameraDev startDev];
        _startDevBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:0.5];
    }
    else{
        [self.cameraDev stopDev];
        _startDevBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
    }
}

- (void)didClickTakePhotoBtn:(UIButton *)btn
{
    [_cameraSocket connectToServer];
    [_cameraSocket sendTakePhotoCmd];
}

- (void)didClickVideoRecordBtn:(UIButton *)btn
{
    btn.selected = !btn.selected;
    if (btn.selected) {
        [_cameraSocket connectToServer];
        [_cameraSocket sendStartRecordVideoCmd];
        _videoRecordBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:0.5];
    }
    else{
        [_cameraSocket connectToServer];
        [_cameraSocket sendStopRecordVideoCmd];
        _videoRecordBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
    }
}

- (void)didGetPhotoListBtn:(UIButton *)btn
{
    self.mediaTableView = [[MediaTableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    [self.view addSubview:self.mediaTableView];
    self.mediaTableView.delegate = self;
    //停止预览
    if (_startDevBtn.selected) {
        [self.startDevBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    
    [_cameraSocket connectToServer];
    [_cameraSocket sendGetSDCardPhotoListCmd];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSArray *fileArray = [NSArray array];
//        [_cameraSocket connectToServer];
//        [_cameraSocket sendGetSDCardPhotoThumbListCmd:fileArray];
//    });
    
    
    //MARK:2022-12测试缩略图刷新逻辑
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        //图像
//        NSMutableArray *mediaArray = [NSMutableArray array];
//        for (int i = 0; i< 30; i++) {
//            MediaModel *model = [[MediaModel alloc] init];
//            model.fileName = [NSString stringWithFormat:@"photo_%d.jpg",i];
//            model.filePath = [NSString stringWithFormat:@"/aaa/bbb/ccc/photo_%d.jpg",i];
//            model.fileSize = 2000;
//            model.mediaType = MediaTypePhoto;
//            [mediaArray addObject:model];
//        }
//        self.mediaTableView.curMediaType = MediaTypePhoto;
//        [self.mediaTableView setDataArray:mediaArray];
//    });
}

- (void)didGetVideoListBtn:(UIButton *)btn
{
    self.mediaTableView = [[MediaTableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    [self.view addSubview:self.mediaTableView];
    self.mediaTableView.delegate = self;
    //停止预览
    if (_startDevBtn.selected) {
        [self.startDevBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    
    [_cameraSocket connectToServer];
    [_cameraSocket sendGetSDCardVideoListCmd];
}

- (void)didStopSDCardVideoPlaybackBtn:(UIButton *)btn
{
    [_cameraSocket connectToServer];
    [_cameraSocket sendStopPlaySDCardVideoCmd];
}

- (void)didClickFlipPreviewBtn:(UIButton *)btn
{
    btn.selected = !btn.selected;
    if (btn.selected ) {
        [_cameraSocket connectToServer];
        [_cameraSocket sendSetVideoFlipCmd:1 mirrorFlag:0];
    }
    else{
        [_cameraSocket connectToServer];
        [_cameraSocket sendSetVideoFlipCmd:0 mirrorFlag:0];
    }
}

- (void)didClickMirrorPreviewBtn:(UIButton *)btn
{
    btn.selected = !btn.selected;
    if (btn.selected ) {
        [_cameraSocket connectToServer];
        [_cameraSocket sendSetVideoFlipCmd:0 mirrorFlag:1];
    }
    else{
        [_cameraSocket connectToServer];
        [_cameraSocket sendSetVideoFlipCmd:0 mirrorFlag:0];
    }
}

- (void)didClickShowWifiSettingBtn:(UIButton *)btn
{
    self.wifiSettingView.hidden = NO;
}

- (void)didClickCancelWifiSetingBtn:(UIButton *)btn
{
    self.wifiSettingView.hidden = YES;
}

- (void)didClickSetWifiBtn:(UIButton *)btn
{
    if (self.wifiNameStr.length == 0) {
        self.wifiNameStr = @"Hohem-AI-Camera";
    }
    if (self.wifiPSWStr.length < 8) {
        self.wifiPSWStr = @"12345678";
    }
    [_cameraSocket connectToServer];
    [_cameraSocket sendSetCameraWifiNameCmd:self.wifiNameStr wifiPasswordKey:self.wifiPSWStr];
    
    self.wifiSettingView.hidden = YES;
}

- (void)didClickFormatSDCardBtn:(UIButton *)btn
{

    [_cameraSocket connectToServer];
    [_cameraSocket sendFormatSDCardCmd];
    _formatBtn.enabled = NO;
}

- (void)didClickLeftCtrlBtn:(UIButton *)btn
{

    Byte ctrl[10] = {0x55,0x55,0x01,0x02,0x7d,0x00,0x00,0x00,0x00,0x2a};
    NSData *data = [NSData dataWithBytes:ctrl length:sizeof(ctrl)];
    [self.cameraDev sendCtrlData:data];
}

- (void)didClickStopCtrlBtn:(UIButton *)btn
{

    Byte ctrl[10] = {0x55,0x55,0x01,0x02,0x00,0x00,0x00,0x00,0x00,0xad};
    NSData *data = [NSData dataWithBytes:ctrl length:sizeof(ctrl)];
    [self.cameraDev sendCtrlData:data];
}

- (void)didClickRightCtrlBtn:(UIButton *)btn
{
    Byte ctrl[10] = {0x55,0x55,0x01,0x02,0x83,0x00,0x00,0x00,0x00,0x30};
    NSData *data = [NSData dataWithBytes:ctrl length:sizeof(ctrl)];
    [self.cameraDev sendCtrlData:data];
}

#pragma mark - 测试固件升级
- (void)testCameraFirmwareUpgrade:(UIButton *)btn
{
    //停止其他连接
    [self.cameraDev disconnectSocket];
    
    [MQLogInfo deleteFileName:@"Upgrade"];
    //停止预览
    if (_startDevBtn.selected) {
        [self.startDevBtn sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    
    _upgradeClient = [[UpgradeSocketManager alloc] init];
    _upgradeClient.delegate = self;
    [_upgradeClient connectToServer];
    //[_upgradeClient sendGetCameraFirmwareInfoCmd];
    [self testSendFirmwareUpgradeCMD];
    
    //[self initTimer];
    self.logTextView.hidden = NO;
    btn.enabled = NO;
}

- (void)testSendFirmwareUpgradeCMD
{
    NSError * error;
    NSArray * contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:FirmwarePath error:&error];
    NSString *localFirmware = [[[contents lastObject] lastPathComponent] stringByDeletingPathExtension];
    NSLog(@"固件名字：%@",localFirmware);
    NSString *filePath = [NSString stringWithFormat:@"%@/%@",FirmwarePath,[contents lastObject]];
    [_upgradeClient sendCameraFirmwareFile:filePath];
}


#pragma mark - DeviceDataDelegate
- (void)getMeidaList:(NSArray *)array mediaType:(int)type
{
    NSMutableArray *mediaArray = [NSMutableArray array];
    if (type == 0) {
        //图像
        for (NSDictionary *fileDic in array) {
            MediaModel *model = [[MediaModel alloc] init];
            model.fileName = [[fileDic objectForKey:@"file_name"] lastPathComponent];
            model.filePath = [fileDic objectForKey:@"file_name"];
            model.fileSize = [[fileDic objectForKey:@"file_size"] intValue];
            model.mediaType = MediaTypePhoto;
            [mediaArray addObject:model];
        }
        self.mediaTableView.curMediaType = MediaTypePhoto;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mediaTableView setDataArray:mediaArray];
        });
    }
    else if (type == 1)
    {
        //视频
        for (NSDictionary *fileDic in array) {
            MediaModel *model = [[MediaModel alloc] init];
            model.fileName = [[fileDic objectForKey:@"file_name"] lastPathComponent];
            model.filePath = [fileDic objectForKey:@"file_name"];
            model.mediaType = MediaTypeVideo;
            [mediaArray addObject:model];
        }
        self.mediaTableView.curMediaType = MediaTypeVideo;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mediaTableView setDataArray:mediaArray];
        });
    }
    //获取列表后，再获取前5的缩略图
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *fileArray = [NSMutableArray array];
        for (int i = 0; i < mediaArray.count; i++) {
            MediaModel *model = mediaArray[i];
            NSDictionary *dict = @{@"file_name":model.filePath};
            [fileArray addObject:dict];
            if (i >= 4) {
                break;
            }
        }
        NSLog(@"缩略图请求.......");
        [_cameraSocket connectToServer];
        if (type == 1) {
            [_cameraSocket sendGetSDCardVideoThumbListCmd:fileArray];
        }
        else{
            [_cameraSocket sendGetSDCardPhotoThumbListCmd:fileArray];
        }
    });
}

- (void)startVideoPlayback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rtspPlayer = [[RtspPlayerViewController alloc] init];
        __weak typeof(self) weakSelf = self;
        self.rtspPlayer.videoPlayCancelBlock = ^{
            [weakSelf didStopSDCardVideoPlaybackBtn:nil];
        };
        [self presentViewController:self.rtspPlayer animated:YES completion:nil];
    });
}

- (void)didFinishMediaDownloadOperation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"下载成功，已保存到相册";
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:1.0];
        [self.view addSubview:hud];
    });
}

- (void)didUpgradeFirmwareProgress:(NSInteger)progress completed:(BOOL)finish
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!progressHud) {
            progressHud = [[MBProgressHUD alloc] initWithView:self.view];
            progressHud.mode = MBProgressHUDModeIndeterminate;
            progressHud.label.text = @"等待固件上传中...";
            [progressHud showAnimated:YES];
            [self.view addSubview:progressHud];
        }
        if (finish) {
            progressHud.mode = MBProgressHUDModeText;
            progressHud.label.text = @"上传成功,更新固件";
            [progressHud hideAnimated:YES afterDelay:3.0];
        }
    });
}

- (void)didFinishFormatSDCard
{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"SDCard格式化完成";
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:3.0];
        [self.view addSubview:hud];
        self.formatBtn.enabled = YES;
    });
}

- (void)didGetThumbList:(NSArray *)array
{
    //将获取的数组中的缩略图重新建立一个字典索引机制（将文件名作为key值，内容作为键值）
    NSMutableDictionary *thumbDictionary = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < array.count; i++) {
        NSDictionary *dict = array[i];
        [thumbDictionary setObject:[dict objectForKey:@"image"] forKey:[dict objectForKey:@"thumName"]];
    }
    //刷新界面
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mediaTableView.thumbDict addEntriesFromDictionary:thumbDictionary];
        [self.mediaTableView reloadData];
    });
}

#pragma mark - MediaButtonDelegate
- (void)didLoadMediaWithModel:(MediaModel *)model
{
    if (model.mediaType == MediaTypePhoto) {
        [_cameraSocket connectToServer];
        [_cameraSocket sendDownloadSDCardPhotoCmd:model.filePath];
    }
    else
    {
        [_cameraSocket connectToServer];
        [_cameraSocket sendDownloadSDCardVideoCmd:model.filePath];
    }
}

- (void)didDeleteMediaWithModel:(MediaModel *)model
{
    if (model.mediaType == MediaTypePhoto) {
        [_cameraSocket connectToServer];
        [_cameraSocket sendDeleteSDCardPhotoCmd:model.filePath];
    }
    else
    {
        [_cameraSocket connectToServer];
        [_cameraSocket sendDeleteSDCardVideoCmd:model.filePath];
    }
}

- (void)didPlayMediaWithModel:(MediaModel *)model
{
//    NSString *path = [model.filePath stringByDeletingPathExtension];
//    NSString *fileStr = [NSString stringWithFormat:@"%@.Hh",path];
//    NSLog(@"打印视频地址%@",fileStr);
    [_cameraSocket connectToServer];
    [_cameraSocket sendStartPlaySDCardVideoCmd:model.filePath];
}

- (void)didRequestMediaThumbWith:(NSMutableArray *)array meidaType:(MediaType)type
{
    NSMutableArray *fileArray = [NSMutableArray array];
    for (int i = 0; i < array.count; i++) {
        MediaModel *model = array[i];
        NSDictionary *dict = @{@"file_name":model.filePath};
        [fileArray addObject:dict];
    }
    //这里需要做一个判断如果滚动过长数组数量过多，最多请求倒数最近的10条缩略图就行
    if (fileArray.count > 4) {
        NSRange removeRange = NSMakeRange(0, array.count - 4);
        [fileArray removeObjectsInRange:removeRange];
    }
    [array removeAllObjects];
    NSLog(@"缩略图请求.......");
    if (fileArray.count <= 0) {
        return;
    }
    [_cameraSocket connectToServer];
    if (type == MediaTypeVideo) {
        [_cameraSocket sendGetSDCardVideoThumbListCmd:fileArray];
    }
    else{
        [_cameraSocket sendGetSDCardPhotoThumbListCmd:fileArray];
    }
    
    //MARK:2022-12自动化测试返回缩略图数据
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
//        for (int i = 0; i < fileArray.count; i++) {
//            NSString *filename = fileArray[i];
//            [dict setObject:[UIImage imageNamed:@"thumb.jpg"] forKey:[filename lastPathComponent]];
//        }
//        [self.mediaTableView.thumbDict addEntriesFromDictionary:dict];
//        [self.mediaTableView reloadData];
//    });
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    if (textField.tag == 100) {
        self.wifiNameTextField = textField;
    }
    else if (textField.tag == 101)
    {
        self.wifiPSWTextField = textField;
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    
    [self updateRegisterBtnStatus];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if (textField.tag == 100) {
        self.wifiNameStr = textField.text;
    }
    else if (textField.tag == 101)
    {
        self.wifiPSWStr = textField.text;
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField.isFirstResponder) {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)updateRegisterBtnStatus {
    
    //NSLog(@"SMSTextField.text.length = %ld",self.SMSTextField.text.length);
    if (self.wifiPSWTextField.text.length >= 8 ) {
        self.isNextStep = YES;
        //self.nextBtn.backgroundColor = [UIColor colorWithHexString:@"#FF6501" alpha:1.0];
    }else{
        self.isNextStep = NO;
        //self.nextBtn.backgroundColor = [UIColor colorWithHexString:@"#FFB280" alpha:1.0];
    }
}

- (void)hideKeyboard {
    
    if (self.wifiNameTextField.isFirstResponder) {
        
        [self.wifiNameTextField resignFirstResponder];
    }
    
    if (self.wifiPSWTextField.isFirstResponder) {
        
        [self.wifiPSWTextField resignFirstResponder];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self hideKeyboard];
}

#pragma mark - 懒加载
- (UIImageView *)imgBackGround
{
    if (!_imgBackGround) {
        _imgBackGround = [[UIImageView alloc] init];
        [_imgBackGround setImage:[UIImage imageNamed:@"OF_Background.jpg"]];
    }
    return _imgBackGround;
}

- (UIButton *)startDevBtn
{
    if (!_startDevBtn) {
        _startDevBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_startDevBtn setTitle:@"开始预览" forState:UIControlStateNormal];
        [_startDevBtn setTitle:@"停止预览" forState:UIControlStateSelected];
        _startDevBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_startDevBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _startDevBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_startDevBtn addTarget:self action:@selector(didClickStartPreviewBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _startDevBtn;
}

- (UIButton *)takePhotoBtn
{
    if (!_takePhotoBtn) {
        _takePhotoBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_takePhotoBtn setTitle:@"拍照" forState:UIControlStateNormal];
        _takePhotoBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_takePhotoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _takePhotoBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_takePhotoBtn addTarget:self action:@selector(didClickTakePhotoBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _takePhotoBtn;
}

- (UIButton *)videoRecordBtn
{
    if (!_videoRecordBtn) {
        _videoRecordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_videoRecordBtn setTitle:@"开始录像" forState:UIControlStateNormal];
        [_videoRecordBtn setTitle:@"停止录像" forState:UIControlStateSelected];
        _videoRecordBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_videoRecordBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _videoRecordBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_videoRecordBtn addTarget:self action:@selector(didClickVideoRecordBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _videoRecordBtn;
}

- (UIButton *)photoListBtn
{
    if (!_photoListBtn) {
        _photoListBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_photoListBtn setTitle:@"照片列表" forState:UIControlStateNormal];
        _photoListBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_photoListBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _photoListBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_photoListBtn addTarget:self action:@selector(didGetPhotoListBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _photoListBtn;
}

- (UIButton *)videoListBtn
{
    if (!_videoListBtn) {
        _videoListBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_videoListBtn setTitle:@"视频列表" forState:UIControlStateNormal];
        _videoListBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_videoListBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _videoListBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_videoListBtn addTarget:self action:@selector(didGetVideoListBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _videoListBtn;
}

- (UIButton *)stopPlaybackBtn
{
    if (!_stopPlaybackBtn) {
        _stopPlaybackBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_stopPlaybackBtn setTitle:@"停止回放" forState:UIControlStateNormal];
        _stopPlaybackBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_stopPlaybackBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _stopPlaybackBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_stopPlaybackBtn addTarget:self action:@selector(didStopSDCardVideoPlaybackBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _stopPlaybackBtn;
}

- (UIButton *)flipPreviewBtn
{
    if (!_flipPreviewBtn) {
        _flipPreviewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flipPreviewBtn setTitle:@"上下翻转" forState:UIControlStateNormal];
        _flipPreviewBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_flipPreviewBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _flipPreviewBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_flipPreviewBtn addTarget:self action:@selector(didClickFlipPreviewBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _flipPreviewBtn;
}

- (UIButton *)mirrorPreviewBtn
{
    if (!_mirrorPreviewBtn) {
        _mirrorPreviewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_mirrorPreviewBtn setTitle:@"左右镜像" forState:UIControlStateNormal];
        _mirrorPreviewBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_mirrorPreviewBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _mirrorPreviewBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_mirrorPreviewBtn addTarget:self action:@selector(didClickMirrorPreviewBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _mirrorPreviewBtn;
}

- (UIButton *)wifiBtn
{
    if (!_wifiBtn) {
        _wifiBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_wifiBtn setTitle:@"WIFI设置" forState:UIControlStateNormal];
        _wifiBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_wifiBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _wifiBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_wifiBtn addTarget:self action:@selector(didClickShowWifiSettingBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _wifiBtn;
}

- (UIButton *)upgradeBtn
{
    if (!_upgradeBtn) {
        _upgradeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_upgradeBtn setTitle:@"固件升级" forState:UIControlStateNormal];
        _upgradeBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_upgradeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_upgradeBtn setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        _upgradeBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_upgradeBtn addTarget:self action:@selector(testCameraFirmwareUpgrade:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _upgradeBtn;
}

- (UIButton *)formatBtn
{
    if (!_formatBtn) {
        _formatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_formatBtn setTitle:@"格式化卡" forState:UIControlStateNormal];
        _formatBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_formatBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_formatBtn setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        _formatBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_formatBtn addTarget:self action:@selector(didClickFormatSDCardBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _formatBtn;
}

- (UIButton *)leftCtrlBtn
{
    if (!_leftCtrlBtn) {
        _leftCtrlBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftCtrlBtn setTitle:@"左转控制" forState:UIControlStateNormal];
        _leftCtrlBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_leftCtrlBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_leftCtrlBtn setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        _leftCtrlBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_leftCtrlBtn addTarget:self action:@selector(didClickLeftCtrlBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftCtrlBtn;
}

- (UIButton *)rightCtrlBtn
{
    if (!_rightCtrlBtn) {
        _rightCtrlBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightCtrlBtn setTitle:@"右转控制" forState:UIControlStateNormal];
        _rightCtrlBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_rightCtrlBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_rightCtrlBtn setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        _rightCtrlBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_rightCtrlBtn addTarget:self action:@selector(didClickRightCtrlBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightCtrlBtn;
}

- (UIButton *)stopBtn
{
    if (!_stopBtn) {
        _stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_stopBtn setTitle:@"停止控制" forState:UIControlStateNormal];
        _stopBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_stopBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_stopBtn setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        _stopBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
        [_stopBtn addTarget:self action:@selector(didClickStopCtrlBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopBtn;
}


- (UIView *)wifiSettingView
{
    if (!_wifiSettingView) {
        _wifiSettingView = [[UIView alloc] init];
        _wifiSettingView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.85];
    }
    return _wifiSettingView;
}

- (UILabel *)wifiNameLabel
{
    if (!_wifiNameLabel) {
        _wifiNameLabel = [[UILabel alloc] init];
        _wifiNameLabel.text = @"WiFi名:";
        _wifiNameLabel.textColor = [UIColor whiteColor];
        _wifiNameLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
        _wifiNameLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _wifiNameLabel;
}

- (UILabel *)wifiPSWLabel
{
    if (!_wifiPSWLabel) {
        _wifiPSWLabel = [[UILabel alloc] init];
        _wifiPSWLabel.text = @"密码:";
        _wifiPSWLabel.textColor = [UIColor whiteColor];
        _wifiPSWLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
        _wifiPSWLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _wifiPSWLabel;
}

- (UITextField *)wifiNameTextField {
    
    if (_wifiNameTextField == nil) {
        
        _wifiNameTextField = [[UITextField alloc]init];
        _wifiNameTextField.textColor = [UIColor whiteColor];
        _wifiNameTextField.textAlignment = NSTextAlignmentCenter;
        _wifiNameTextField.placeholder = @"Hohem-AI-Camera";
        _wifiNameTextField.tintColor = [UIColor whiteColor];
        _wifiNameTextField.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
        _wifiNameTextField.keyboardType = UIKeyboardTypeASCIICapable;
        _wifiNameTextField.returnKeyType = UIReturnKeyGo;
        _wifiNameTextField.tag = 100;
        _wifiNameTextField.delegate = self;
    }
    
    return _wifiNameTextField;
}

- (UITextField *)wifiPSWTextField {
    
    if (_wifiPSWTextField == nil) {
        
        _wifiPSWTextField = [[UITextField alloc]init];
        _wifiPSWTextField.textColor = [UIColor whiteColor];
        _wifiPSWTextField.textAlignment = NSTextAlignmentCenter;
        _wifiPSWTextField.placeholder = @"12345678";
        _wifiPSWTextField.tintColor = [UIColor whiteColor];
        _wifiPSWTextField.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
        _wifiPSWTextField.keyboardType = UIKeyboardTypeASCIICapable;
        _wifiPSWTextField.returnKeyType = UIReturnKeyGo;
        _wifiPSWTextField.tag = 101;
        _wifiPSWTextField.delegate = self;
    }
    
    return _wifiPSWTextField;
}

- (UIButton *)cancelBtn
{
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelBtn.backgroundColor = [UIColor darkGrayColor];
        [_cancelBtn addTarget:self action:@selector(didClickCancelWifiSetingBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _cancelBtn;
}

- (UIButton *)confirmBtn
{
    if (!_confirmBtn) {
        _confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_confirmBtn setTitle:@"设置" forState:UIControlStateNormal];
        _confirmBtn.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
        [_confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _confirmBtn.backgroundColor = [UIColor blueColor];
        [_confirmBtn addTarget:self action:@selector(didClickSetWifiBtn:) forControlEvents:UIControlEventTouchUpInside];

    }
    return _confirmBtn;
}

- (NSString *)wifiNameStr
{
    if (!_wifiNameStr) {
        _wifiNameStr = [[NSString alloc] init];
    }
    return _wifiNameStr;
}

- (NSString *)wifiPSWStr
{
    if (!_wifiPSWStr) {
        _wifiPSWStr = [[NSString alloc] init];
    }
    return _wifiPSWStr;
}

#pragma mark - UITextView
- (UITextView *)logTextView
{
    if (_logTextView == nil) {
        _logTextView = [[UITextView alloc] init];
        _logTextView.backgroundColor = [UIColor colorWithRed:39/255.0 green:40/255.0 blue:34/255.0 alpha:1.0];
        _logTextView.textColor = [UIColor whiteColor];
        _logTextView.font = [UIFont systemFontOfSize:14.0];
        _logTextView.editable = NO;
        _logTextView.layoutManager.allowsNonContiguousLayout = NO;
    }
    return _logTextView;
}


- (void)redirectNotificationHandle:(NSNotification *)nf{ // 通知方法
    NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      
    self.logTextView.text = [NSString stringWithFormat:@"%@\n\n%@",self.logTextView.text, str];// logTextView 就是要将日志输出的视图（UITextView）
    NSRange range;
    range.location = [self.logTextView.text length] - 1;
    range.length = 0;
    [self.logTextView scrollRangeToVisible:range];
    self.logTextView.layoutManager.allowsNonContiguousLayout = NO;
    [[nf object] readInBackgroundAndNotify];
}

- (void)redirectSTD:(int )fd{
    NSPipe * pipe = [NSPipe pipe] ;// 初始化一个NSPipe 对象
    NSFileHandle *pipeReadHandle = [pipe fileHandleForReading] ;
    dup2([[pipe fileHandleForWriting] fileDescriptor], fd) ;
      
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(redirectNotificationHandle:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandle]; // 注册通知
    [pipeReadHandle readInBackgroundAndNotify];
}


- (void)CheckXPhone
{
    UIEdgeInsets edgeInsets = UIApplication.sharedApplication.keyWindow.safeAreaInsets;
    NSLog(@"打印边距top = %f, bottom = %f, left = %f, right = %f",edgeInsets.top,edgeInsets.bottom,edgeInsets.left,edgeInsets.right);
    if (UIApplication.sharedApplication.keyWindow.safeAreaInsets.left > 20) {
        NSLog(@"是刘海屏");
        self.isXPhone = YES;
    } else {
        NSLog(@"不是刘海屏");
        self.isXPhone = NO;
    }
    
}

@end
