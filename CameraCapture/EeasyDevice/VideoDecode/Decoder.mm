//
//  Decoder.m
//  H264Demo
//
//  Created by 林漫钦 on 16/10/27.
//  Copyright © 2016年 lin. All rights reserved.
//

#import "Decoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import "FZJPhotoTool.h"
#import "UIImage+Zoom.h"
#import "AWLinkConstant.h"
#import "AWTools.h"
#import "h264_stream.h"
#import "AppDelegate.h"
#import "NotiPixelBufferValue.h"

static void didFinishedDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

@interface Decoder ()
{
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    
    VTDecompressionSessionRef _decoderSession;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    
    int ret;
    CVPixelBufferRef cache;
    BOOL _needShare;//用以标记是否要分享
    uint8_t frameCount;
    
    h264_stream_t * _h;
    BOOL _isFrame_continuity;//是否是连续帧
    CIContext *temporaryContext;
    int detectCount;
    
    dispatch_queue_t followPICQueue;
    NSLock *followPICLock;
}
@property(nonatomic) dispatch_source_t timer;                  //
@property(nonatomic, copy) CollectImageComplete myImageBlock;          //添加完图片的block回调
@property(nonatomic, strong) NSMutableArray *shareImageArray;          //需要分享的图片数组

@end

@implementation Decoder

static int _lastFrameNum = -2;//上一帧帧序号

- (void)resetH264Decoder
{
    if(_decoderSession) {
        VTDecompressionSessionInvalidate(_decoderSession);
        CFRelease(_decoderSession);
        _decoderSession = NULL;
    }
    CFDictionaryRef attrs = NULL;
    const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
    //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
    //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
    uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
    attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = didFinishedDecompress;
    callBackRecord.decompressionOutputRefCon = NULL;
    if(VTDecompressionSessionCanAcceptFormatDescription(_decoderSession, _decoderFormatDescription))
    {
        
    }
    
    VTDecompressionSessionCreate(kCFAllocatorSystemDefault,
                                                   _decoderFormatDescription,
                                                   NULL, attrs,
                                                   &callBackRecord,
                                                   &_decoderSession);
    CFRelease(attrs);
}

-(id)init
{
    self = [super init];
    if (self) {
        //设置输出尺寸
        //  _vwidth = 1920;
        //  _vheight = 1080;
        
//        [self initCAShaper];
        
        _h = h264_new();
        
        _isFrame_continuity = YES;
        
        //手势识别初始化
//        NSString * configpath = [[NSBundle mainBundle] pathForResource:@"HandGesture_V1.0" ofType:@"ini"];
//        NSString * dataPath = [[NSBundle mainBundle] pathForResource:@"HandGesture_V1.1" ofType:@"dat"];
//
//        _mHandle = [ObjectDetect aw_ai_od_init_oc:[configpath UTF8String] DataPath:[dataPath UTF8String]];
//
//        _stImageData.mType = PIXEL_FORMAT_YUV_SEMIPLANAR_420;
//        _stImageData.mChannel = 3;
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self checkIsSuccess];
//        });
        followPICQueue = dispatch_queue_create("followME", DISPATCH_QUEUE_CONCURRENT);
        followPICLock  = [[NSLock alloc] init];
    }
    return self;
}

//-(void)checkIsSuccess
//{
//    int k = [ObjectDetect aw_gr_ecp];
//    _tcpMgr = [TcpManager defaultManager];
//    if([_tcpMgr tcpConnected]){
//        SEQ_CMD cmd = CMD_REQ_WIFI_DISPATCHER_SYS_PARAM_GET;
//        NSDictionary *dict = @{@"CMD":@(cmd), @"PARAM":@{@"K":@(k)}};
//        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
//        [_tcpMgr sendData:data Response:^(NSData *responseData) {
//            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
//            if ([dict[@"RESULT"] isEqual:@0])
//            {
//                NSDictionary * dic = dict[@"PARAM"];
//                int k = [dic[@"K"] intValue];
//                int result = [ObjectDetect aw_gr_dcp:k];
//                NSLog(@"---%d",result);
//            }
//        } Tag:0];
//    }
//}

-(BOOL)initH264Decoder  //创建会话
{
    if (_decoderSession) {
        return YES  ;
    }
    
    if (!_sps || !_pps || _spsSize == 0 || _ppsSize == 0) {
        return NO;
    }
    if (self.delegate) {
        [self.delegate gotSpsPps:_sps pps:_pps SpsSize:_spsSize PpsSize:_ppsSize];
    }
    
    const uint8_t * const parameter[2] = {_sps , _pps};
    const size_t parameterSetSizes[2] = {static_cast<size_t>(_spsSize) , static_cast<size_t>(_ppsSize)};  //size_t 即 unsigned int
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameter, parameterSetSizes,
                                                                          4, //startcode 占4字节
                                                                          &_decoderFormatDescription);
    if (status == noErr) {
        
        CFDictionaryRef attrs = NULL;
        const void * keys[] = {kCVPixelBufferPixelFormatTypeKey};
        //  kCVPixelFormatType_420YpCbCr8Planar is YUV420
        //  kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
        uint32_t yuv420 = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void *values[] = {CFNumberCreate(NULL, kCFNumberSInt32Type, &yuv420)};
        attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didFinishedDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        status = VTDecompressionSessionCreate(kCFAllocatorDefault,
                                              _decoderFormatDescription,
                                              NULL, attrs,
                                              &callBackRecord,
                                              &_decoderSession);
        CFRelease(attrs);
    }
    else return NO;
    
    return YES;
}

-(void)clearH264Deocder {
    if(_decoderSession) {
        VTDecompressionSessionInvalidate(_decoderSession);
        CFRelease(_decoderSession);
        _decoderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    free(_sps);
    free(_pps);
    _spsSize = _ppsSize = 0;
}

-(CVPixelBufferRef)decode:(uint8_t *)buffer BufferSize:(int)bufferSize {
    
    if (!_sps || !_pps || !_ppsSize || !_spsSize) {
        return nil;
    }
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          buffer, bufferSize,
                                                          kCFAllocatorNull,
                                                          NULL, 0, bufferSize,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        
        const size_t sampleSizeArray[] = {static_cast<size_t>(bufferSize)};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_decoderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
//                NSLog(@"IOS8VT: Invalid session, reset decoder session");
                [self resetH264Decoder];
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
//                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus); // decode failed status=-12911,一般是数据丢包，会产生绿色色块
            } else if(decodeStatus != noErr) {
//                NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}

#pragma mark -解码一帧数据
-(void)decodeNalu:(uint8_t *)frame withSize:(uint32_t)frameSize withoutStartCode:(uint8_t *)buffer
{
    //    NSLog(@">>>>>>>>>>开始解码");
    int nalu_type = (frame[4] & 0x1F);
    CVPixelBufferRef pixelBuffer = NULL;
    uint32_t nalSize = (uint32_t)(frameSize - 4);
    uint8_t *pNalSize = (uint8_t*)(&nalSize);
    //转换字节序
    frame[0] = *(pNalSize + 3);
    frame[1] = *(pNalSize + 2);
    frame[2] = *(pNalSize + 1);
    frame[3] = *(pNalSize);
    
    //丢帧处理
    read_nal_unit(_h, buffer, frameSize-4);
    
    //帧序号最大值计算
    int frame_num_max = pow(2, _h->sps->log2_max_frame_num_minus4+4);
    
    //传输的时候。关键帧不能丢数据 否则绿屏   B/P可以丢  这样会卡顿
    switch (nalu_type)
    {
        case 0x05:
        
//                       NSLog(@"nalu_type:%d Nal type is IDR frame",nalu_type);  //关键帧
            _lastFrameNum = _h->sh->frame_num;

            if([self initH264Decoder])
            {
//                if (frameCount>0) {
//                    NSLog(@"frameCount---%hhu",frameCount);//统计两个i帧之间的p帧数量
//                }
                frameCount = 0;
                pixelBuffer = [self decode:frame BufferSize:frameSize];
                _is_I_Frame = YES;
                _isFrame_continuity = YES;
            }
            else{
                _isFrame_continuity = NO;
            }
            break;
        case 0x07:
        {
//                       NSLog(@"nalu_type:%d Nal type is SPS",nalu_type);   //sps
            //保存分辨率
            if(((_h->sps->pic_height_in_map_units_minus1+1)*16) == k720){//720分辨率
                [[NSUserDefaults standardUserDefaults] setObject:@(0) forKey:@"720P"];
            }else if (((_h->sps->pic_height_in_map_units_minus1+1)*16) == k480){//480分辨率
                [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:@"720P"];
            }
            _spsSize = frameSize - 4;
            _sps = (uint8_t *) malloc(_spsSize);
            memcpy(_sps, &frame[4], _spsSize);
            NSData * sps = [[NSData alloc] initWithBytes:frame length:_spsSize];
            NSLog(@"sps---%@---%d",sps,_spsSize);
            break;
        }
        case 0x08:
        {
//                        NSLog(@"nalu_type:%d Nal type is PPS",nalu_type);   //pps
            _ppsSize = frameSize - 4;
            _pps = (uint8_t *) malloc(_ppsSize);
            memcpy(_pps, &frame[4], _ppsSize);
            NSData * pps = [[NSData alloc] initWithBytes:frame length:_ppsSize];
            NSLog(@"pps---%@---%d",pps,_ppsSize);
            break;
        }
        default:
        {
            if (_isOpenKCFTrack) {
                if([self initH264Decoder])
                {
                    pixelBuffer = [self decode:frame BufferSize:frameSize];
                }
            }
            else{
                //NSLog(@"Nal type is B/P frame");//其他帧
                if(_isFrame_continuity){
                                if(_h->sh->frame_num == _lastFrameNum+1)
                                {
                                    if([self initH264Decoder])
                                    {
                                        pixelBuffer = [self decode:frame BufferSize:frameSize];
                                        frameCount++;
                                    }
                                    _lastFrameNum =(int) _h->sh->frame_num;
                                    //NSLog(@"上一帧：%d",_lastFrameNum);
                                    if(_lastFrameNum == frame_num_max -1){
                                        _lastFrameNum = -1;
                                    }
                                }else
                                {
                                    _isFrame_continuity = NO;
                                    NSLog(@"丢失的一帧：%d",_lastFrameNum);
                                }
                            }
            }

            
            break;
        }
        
    }
    
    //截图保存图片
    if (pixelBuffer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NotiPixelBufferValue *dataPtr = [NotiPixelBufferValue valueWithCVPixelBuffer:pixelBuffer];
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:dataPtr,@"dataPtr",nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GETPIXELBUFFER" object:dict userInfo:nil];
        });
        
    }
    
    
}

//- (void)gotSpsPps:(uint8_t*)sps pps:(uint8_t*)pps SpsSize:(int)spsSize PpsSize:(int)ppsSize
//{
//    const char bytes[] = "\x00\x00\x00\x01";
//    size_t length = (sizeof bytes) - 1;
//    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
//    //发sps
//    NSMutableData *h264Data = [[NSMutableData alloc] init];
//    [h264Data appendData:ByteHeader];
//    [h264Data appendBytes:sps length:spsSize];
//    [self decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
//
////    NSLog(@"%@",h264Data);
//    //发pps
//    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
//    [h264Data setLength:0];
//    [h264Data appendData:ByteHeader];
//    [h264Data appendBytes:pps length:ppsSize];
////    NSLog(@"%@",h264Data);
//    [self decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
//}
#pragma mark -定时器，手势识别检测
//-(void)handRecognation:(CVPixelBufferRef)handPixelBuffer
//{
//    NSLog(@"thread--*--%@",[NSThread currentThread]);
//    if (handPixelBuffer) {
//        BOOL isHandRecognation = [self dataWithYUVPixelBuffer:handPixelBuffer];
//        if (isHandRecognation) {
//            if (_delegate && [_delegate respondsToSelector:@selector(takePhotos)]) {
//                [_delegate takePhotos];
//            }
//        }else
//        {
//            NSLog(@"未识别到手势...");
//        }
//        CVPixelBufferRelease(handPixelBuffer);
//    }
//}

#pragma mark - share
- (void)startShareAndCollectImageDataWithBlock:(CollectImageComplete)block {
    self.myImageBlock = block;
    _needShare = YES;
}

- (void)closeShare {
    _needShare = NO;
    self.shareImageArray = nil;
}

-(void)costPic:(CVPixelBufferRef)pixelBuffer
{
    if (_takePhotosNum > 0) {
        
        UIImage *image = [self getImg:pixelBuffer];
        if (image) {
            [[FZJPhotoTool sharedFZJPhotoTool] saveImageIntoCustomeCollectionFromImageArr:@[image] resultBlock:nil];
            if (_needShare) {
                [self.shareImageArray addObject:image];
            }
            
            CVPixelBufferRelease(cache);
            _takePhotosNum--;
        }
    }
    
    if (_takePhotosNum == 0 && _needShare && (self.shareImageArray.count > 0)) {
        if (self.myImageBlock) {
            self.myImageBlock(self.shareImageArray);
        }
        self.shareImageArray = nil;
    }
}

-(UIImage *)getImg:(CVPixelBufferRef)pixelBuf
{
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuf];
    
    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
                             createCGImage:ciImage
                             fromRect:CGRectMake(0, 0,
                                                 CVPixelBufferGetWidth(pixelBuf),
                                                 CVPixelBufferGetHeight(pixelBuf))];
    
    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);
    return uiImage;
}

- (NSMutableArray *)shareImageArray {
    
    if (_shareImageArray == nil) {
        _shareImageArray = [NSMutableArray array];
    }
    return _shareImageArray;
}

- (dispatch_source_t)timer {

    if (_timer == nil) {
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_resume(_timer);
    }
    return _timer;
}


//the size of buffer has to be width * height * 1.5 (yuv)
- (void) copyDataFromYUVPixelBuffer:(CVPixelBufferRef)pixelBuffer toBuffer:(unsigned char*)buffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    if (CVPixelBufferIsPlanar(pixelBuffer)) {
        size_t w = CVPixelBufferGetWidth(pixelBuffer);
        size_t h = CVPixelBufferGetHeight(pixelBuffer);
        
        size_t d = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        unsigned char* src = (unsigned char*) CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        unsigned char* dst = buffer;
        
        for (unsigned int rIdx = 0; rIdx < h; ++rIdx, dst += w, src += d) {
            memcpy(dst, src, w);
        }
        
        d = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
        src = (unsigned char *) CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        
        h = h >> 1;
        for (unsigned int rIdx = 0; rIdx < h; ++rIdx, dst += w, src += d) {
            memcpy(dst, src, w);
        }
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}


- (void)dealloc
{
//    if (_mHandle) {
//        [ObjectDetect aw_ai_od_uninit:_mHandle];//释放资源
//    }
    h264_free(_h);//内存释放
}

int ConvertNV12toIYUV(uint8_t* nv12buf,uint32_t imgw,uint32_t imgh,uint8_t* yuv420)
{
    uint8_t* pPU = NULL;
    uint8_t* pPV = NULL;
    uint8_t* pPUV = NULL;
//    yuv420 = NULL;
    uint32_t i;
    
    if (nv12buf == NULL)
        return -1;
    pPUV = nv12buf + imgw*imgh;
//    yuv420 = (uint8_t*)malloc((imgw*imgh)>>1);
    if (yuv420 == NULL)
        
        return -1;
    pPU = yuv420;
    pPV = yuv420 + ((imgw*imgh)>>2);
    for (i=0;i<(imgw*imgh)>>1;i++)
    {
        if ((i % 2) == 0)
            *pPV++ = *(pPUV+i);
        else
            *pPU++ = *(pPUV+i);
    }
    memcpy(pPUV,yuv420,(imgw*imgh)>>1);
//    if (yuv420)
        free(nv12buf);
    return 0;
}

@end
