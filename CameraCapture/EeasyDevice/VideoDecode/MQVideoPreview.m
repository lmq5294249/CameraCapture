//
//  MQVideoPreview.m
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/29.
//

#import "MQVideoPreview.h"
#import "NotiPixelBufferValue.h"


@interface MQVideoPreview ()

@end

@implementation MQVideoPreview

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self setupVideoPreviewUI];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getPixelBufferData:) name:@"GETPIXELBUFFER" object:nil];
    }
    return self;
}

- (void)setupVideoPreviewUI
{
    self.backgroundView = [[UIImageView alloc] init];
    UIImage *image = [UIImage imageNamed:@"OF_Background.jpg"];
    if (image) {
        [self.backgroundView setImage:image];
    }
    else{
        self.backgroundColor = [UIColor blackColor];
    }
    [self addSubview:self.backgroundView];
    
    
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.backgroundView setFrame:self.frame];
    
    [self.backgroundView.layer addSublayer:self.previewView];
}

#pragma mark - 图像数据传入刷图Layer层
-(void)getPixelBufferData:(NSNotification *)noti{
    NSDictionary *dict = noti.object;
    NotiPixelBufferValue *dataPtr = [dict objectForKey:@"dataPtr"];
    CVPixelBufferRef buf = [dataPtr pixelBuffer];
    
    self.previewView.pixelBuffer = buf;
    
}


#pragma mark - 懒加载
-(PGQCAEAGLLayer *)previewView {
    if (_previewView == nil) {
        _previewView = [[PGQCAEAGLLayer alloc] initWithFrame:self.frame];
        _previewView.zPosition = -1;
        _previewView.backgroundColor = [[UIColor clearColor] CGColor];
    }
    return _previewView;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GETPIXELBUFFER" object:nil];
}

@end
