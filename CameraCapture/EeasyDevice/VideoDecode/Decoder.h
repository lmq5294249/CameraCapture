//
//  Decoder.m
//  H264Demo
//
//  Created by 林漫钦 on 16/10/27.
//  Copyright © 2016年 lin. All rights reserved.

#import <Foundation/Foundation.h>
#import "PGQCAEAGLLayer.h"

@protocol decoderDelegare <NSObject>
- (void)gotSpsPps:(uint8_t*)sps pps:(uint8_t*)pps SpsSize:(NSInteger)spsSize PpsSize:(NSInteger)ppsSize;
- (void)takePhotos;
@end

typedef void (^CollectImageComplete)(NSArray<UIImage *> *arrImg);
@interface Decoder : NSObject
@property(nonatomic,assign)int vheight;
@property(nonatomic,assign)int vwidth;

@property(nonatomic,assign)bool isBranch;//将数据传到另一个界面

@property(assign,nonatomic)id <decoderDelegare> delegate;

@property(nonatomic,strong) PGQCAEAGLLayer *showLayer;

@property(atomic,assign) NSInteger takePhotosNum;

@property(atomic,assign) BOOL isTakephone;

@property (strong,nonatomic) NSString *filePath;

@property (nonatomic,assign) BOOL  is_I_Frame;//是否I帧

@property (nonatomic,assign) BOOL is_FaceBeauty;//开启美颜滤镜

//@property (nonatomic,assign) BOOL  isHandRecognition;//手势识别拍照

@property (nonatomic,assign) BOOL isOpenKCFTrack;

- (void)resetH264Decoder;
- (void)clearH264Deocder;
- (void)decodeNalu:(uint8_t *)frame withSize:(uint32_t)frameSize withoutStartCode:(uint8_t *)buffer;
- (void)gotSpsPps:(uint8_t*)sps pps:(uint8_t*)pps SpsSize:(int)spsSize PpsSize:(int)ppsSize;
- (void)startShareAndCollectImageDataWithBlock:(CollectImageComplete)block;
- (void)closeShare;
- (UIImage *)getImg:(CVPixelBufferRef)pixelBuf;

- (void)parseAndDecodeH264Nalu:(uint8_t *)frame withSize:(uint32_t)frameSize withoutStartCode:(uint8_t *)buffer;
@end
