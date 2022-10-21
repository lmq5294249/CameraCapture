//
//  Decoder.m
//  H264Demo
//
//  Created by 林漫钦 on 16/10/27.
//  Copyright © 2016年 lin. All rights reserved.

#import "MP4Helper.h"
#import "FZJPhotoTool.h"
#import "Util.h"

#if TARGET_IPHONE_SIMULATOR
#else
    #import "mp4v2.h"
#endif
#import "Util.h"

typedef enum
{
    STATE_closed = 0,
    STATE_data
}STATE;

typedef enum
{
    OPERATION_START = 0,
    OPERATION_CLOSE
}OPERATION;

@interface MP4Helper ()
{
#if TARGET_IPHONE_SIMULATOR
#else
    //mp4v2
    MP4FileHandle fileHandle;
    MP4TrackId video;
#endif

    NSString *_fileName;
    dispatch_queue_t _encode_queue;
    
    uint8_t *_sps;
    uint8_t *_pps;
    int _spsSize;
    int _ppsSize;
    
    int _width;
    int _height;
    BOOL isFirstKeyFrame;
    BOOL _needShare;//用以标记是否要分享
}
@property(atomic,assign)STATE state;
@property(atomic,strong)NSMutableArray *operationQueue;
@property(nonatomic,copy)ShareVideoCallBackBlock block;
//@property (strong, nonatomic) MergeVideoAndMusic *mergrVideoMusic;
@end
@implementation MP4Helper

-(instancetype)init
{
    self = [super init];
    if (self) {
        _operationQueue = [[NSMutableArray alloc] init];
        _state = STATE_closed;
//        _encdoer = [[FfmpegEncoder alloc] init];
        _encode_queue = dispatch_get_global_queue(0, 0);
        
        //mp4v2

    }
    return self;
}


-(BOOL)isRecording
{
    if (_state == STATE_data) {
        return YES;
    }
    else return NO;
}

-(void)closeFile
{
    if (_state == STATE_closed) {
        return;
    }
    OPERATION operation = OPERATION_CLOSE;
    [_operationQueue addObject:[NSNumber numberWithInt:operation]];
}

-(void)startRecord:(NSString*)fileName Width:(int)width Height:(int)height
{
    if (_state != STATE_closed) {
        return;
    }
    _fileName = fileName;
    OPERATION operation = OPERATION_START;
    [_operationQueue addObject:[NSNumber numberWithInt:operation]];
    
    _width = width;
    _height = height;
}


//-(void)startRecord:(const char *)fileName Width:(int)width Height:(int)height
//{
//    if (_state != STATE_closed) {
//        return;
//    }
//    _fileName = [NSString stringWithUTF8String:fileName];
//    OPERATION operation = OPERATION_START;
//    [_operationQueue addObject:[NSNumber numberWithInt:operation]];
//    
//    _width = width;
//    _height = height;
//}

-(void)doRunloop:(uint8_t *)buffer Size:(int)size
{
//    dispatch_sync(_encode_queue, ^{
    
        if (_operationQueue.count == 0) {
            
            if (_state == STATE_data) {
                
                NSLog(@"写数据");
                [self writeVideoStream:buffer Size:size];
            }
            return;
        }
        OPERATION operation;
        operation = [[_operationQueue objectAtIndex:0] intValue];
        //检查写文件头
        if (operation == OPERATION_START) {
            if (_state == STATE_closed) {
                NSLog(@"test -- 1");
                [self mp4init:_fileName Width:_width Height:_height];
                _state = STATE_data;
                NSLog(@"写头");
            }
        }
        else if (operation == OPERATION_CLOSE)
        {
            if (_state == STATE_data) {
                NSLog(@"test -- 3");
                _state = STATE_closed;
                [self mp4Close];
                [self saveToSystemLib];
                NSLog(@"写尾");
            }
        }
        if (_operationQueue.count) {
            [_operationQueue removeObjectAtIndex:0];
        }
    
//    });
}

-(void)saveToSystemLib
{
    FZJPhotoTool *tool = [FZJPhotoTool sharedFZJPhotoTool];
    // [tool saveVideoIntoCustomeCollectionFromUrl:[NSURL URLWithString:[self pathForName:_fileName]] resultBlock:^(NSError *error,NSString *filePath)
    NSString *mp4FilePatch = [_fileName stringByAppendingString:@".mp4"];
    
    //全景录像通知反馈
//    UIImage *thumb = [Util getThumb:mp4FilePatch];
//    NSDictionary *dict = [[NSDictionary alloc]initWithObjectsAndKeys:mp4FilePatch,@"VideoPath",nil];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"GETVIDEOTHUMB" object:thumb userInfo:dict];
//    });
//    
//    _mergrVideoMusic = [MergeVideoAndMusic shareInstance];
//    _mergrVideoMusic.videoUrl = [NSURL fileURLWithPath:mp4FilePatch];
//    if (_mergrVideoMusic.isMergeMode) {
//        [_mergrVideoMusic mergeAction];
//    }
//    else{
        [tool saveVideoIntoCustomeCollectionFromUrl:[NSURL URLWithString:mp4FilePatch] resultBlock:^(NSError *error,NSString *filePath) {
                
                if (_needShare) {
                    self.block(filePath);
                    return;
                }
                
        //        else {
        //            if (error == nil) {
        //                //可以删除document里面保存的MP4
        //                NSFileManager *manager = [NSFileManager defaultManager];
        //                if ([manager fileExistsAtPath:filePath])
        //                {
        //                    [manager removeItemAtPath:filePath error:nil];
        //                }
        //            }
        //        }
            }];
//    }

}

#pragma mark - share
- (void)startShareVideoAndCallBackWithBlock:(ShareVideoCallBackBlock)block {
    _needShare = YES;
    self.block = block;
}
- (void)closeShareVideo {
    _needShare = NO;
}

-(NSString *)pathForName:(NSString *)fileName
{
    NSString *pathCache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES) firstObject];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:pathCache]) {
        [fileManager createDirectoryAtPath:pathCache withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [pathCache stringByAppendingPathComponent:fileName];
}

//mp4v2

-(void)gotSps:(uint8_t *)sps Pps:(uint8_t *)pps SpsSize:(int)spsSize PpsSize:(int)ppsSize
{
    if (_sps || _pps) {
        free(_sps);
        _sps = nil;
        free(_pps);
        _pps = nil;
    }
    _spsSize = spsSize;
    _ppsSize = ppsSize;
    
    _sps = malloc(_spsSize);
    _pps = malloc(_ppsSize);
    memcpy(_sps, sps, _spsSize);
    memcpy(_pps, pps, _ppsSize);
}

-(Boolean)mp4init:(NSString *)fileName Width:(int)width Height:(int)height
{
#if TARGET_IPHONE_SIMULATOR
#else
    //传过来的文件名已包含存储地址Path
    fileName = [fileName stringByAppendingString:@".mp4"];
    fileHandle = MP4Create([fileName UTF8String], 0);
//    fileHandle = MP4Create([[self pathForName:fileName] UTF8String], 0);
    if(fileHandle == MP4_INVALID_FILE_HANDLE)
    {
        return false;
    }
    //设置mp4文件的时间单位
    MP4SetTimeScale(fileHandle, 90000);
    //创建视频track //根据ISO/IEC 14496-10 可知sps的第二个，第三个，第四个字节分别是 AVCProfileIndication,profile_compat,AVCLevelIndication     其中90000/20  中的20>是fps
    for (int i = 0; i<4; i++) {
        NSLog(@"%x",_sps[i]);
    }
    video = MP4AddH264VideoTrack(fileHandle, 90000, 90000 / 30, width, height, _sps[1], _sps[2], _sps[3], 3);
    if(video == MP4_INVALID_TRACK_ID)
    {
        MP4Close(fileHandle, 0);
        return false;
    }
    
    //设置sps和pps
    MP4AddH264SequenceParameterSet(fileHandle, video, _sps, _spsSize);
    MP4AddH264PictureParameterSet(fileHandle, video, _pps, _ppsSize);
    MP4SetVideoProfileLevel(fileHandle, 0x7F);
    
    isFirstKeyFrame = YES;

#endif

    return true;
}

int getVopType(const void *p) {
    
    uint8_t *temp = (uint8_t *)p;
    return (temp[4] == 0x65)?0:1;
}

-(void)writeVideoStream:(uint8_t *)buffer Size:(int)size
{
    int iskeyframe = getVopType(buffer);  //0为i帧
    if (iskeyframe != 0 && isFirstKeyFrame) {
        return;
    }

    uint32_t nalSize = (uint32_t)(size - 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    //转换字节序
    buffer[0] = *(pNalSize + 3);
    buffer[1] = *(pNalSize + 2);
    buffer[2] = *(pNalSize + 1);
    buffer[3] = *(pNalSize);
#if TARGET_IPHONE_SIMULATOR
#else
    MP4WriteSample(fileHandle, video, buffer, size, MP4_INVALID_DURATION, 0, !iskeyframe);
#endif
    isFirstKeyFrame = NO;
}
//视频录制结束调用
-(void)mp4Close
{
#if TARGET_IPHONE_SIMULATOR
#else
    if (fileHandle != MP4_INVALID_FILE_HANDLE)
    {
        MP4Close(fileHandle,0);
        fileHandle = MP4_INVALID_FILE_HANDLE;
        isFirstKeyFrame = YES;
    }
#endif
}



@end
