//
//  CameraSocketManager.m
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/1.
//

#define writePingCmdTag 100
#define writeCmdTag 101

#define readCmdHeadTag 201
#define readPingDataTag 202
#define readTakePhotoCmdHeadTag 203
#define readTakePhotoPackTag 204
#define readGetSDCardPhotoListTag 205
#define readDeleteSDCardPhotoTag 206
#define readStartSDRecordVideoTag 207
#define readStopSDRecordVideoTag 208
#define readGetSDCardVideoListTag 209
#define readDeleteSDCardVideoTag 210
#define readDownloadSDCardVideoTag 211
#define readSetCameraSystemTimeTag 212
#define readGetCameraSystemTimeTag 213
#define readSetCameraWifiTag 214
#define readSetVideoDirectionTag 215
#define readStartPlaySDCardVideoTag 216
#define readStopPlaySDCardVideoTag 217
#define readGetSDCardThumbListTag 218

#import "CameraSocketManager.h"
#import <Photos/Photos.h>
#import "MQLogInfo.h"

const static NSString *GetPhotoStart = @"start";
const static NSString *GetPhotoContinue = @"ing";
const static NSString *GetPhotoEnd = @"end";

@interface CameraSocketManager ()
{
    int recDatalength;
    NSString *savePhotoStr;
    NSString *curPhotoNameStr;
    NSMutableData *keepPhotoData;
    
    NSMutableData *videoData;
    BOOL isDownVideoComplete;
    BOOL isVideoThumbType;
}

@property (nonatomic, strong) NSString *filePath;

@end

@implementation CameraSocketManager

- (void)connectToServer
{
    [self.client connectToHost:self.host onPort:self.port error:nil];
    self.client.delegate = self;
}

- (void)sendData:(NSData *)data
{
    [self.client writeData:data withTimeout:-1 tag:0];
}
//设置实时视频的方向
/*
 "mirror":1, // ISP 镜像（左右），翻转角度：0（0 度）、1（180 度）。
 "flip":0 // ISP 翻转（上下），翻转角度：0（0 度）、1（180 度）。
 */
- (void)sendSetVideoFlipCmd:(NSInteger)flipValue mirrorFlag:(NSInteger)mirrorValue
{
    NSDictionary *dic = @{@"mirror":[NSNumber numberWithUnsignedInteger:mirrorValue],
                          @"flip":[NSNumber numberWithUnsignedInteger:flipValue]
    };
    NSData *data = [DataUtil buildFlipRealTimeVideoCmdPack:dic];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendTakePhotoCmd
{
    NSData *data = [DataUtil buildTakePhotoCmdPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendStartRecordVideoCmd
{
    NSData *data = [DataUtil buildStartRecordCmdPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendStopRecordVideoCmd
{
    NSData *data = [DataUtil buildStopRecordCmdPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendGetSDCardPhotoListCmd
{
    NSData *data = [DataUtil buildGetSDCardPhotoListCmdPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendGetSDCardVideoListCmd
{
    NSData *data = [DataUtil buildGetSDCardVideoListCmdPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendDownloadSDCardPhotoCmd:(NSString *)fileName
{
    NSData *data = [DataUtil buildDownloadPhotoFromSDCardCmdPack:fileName];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendDownloadSDCardVideoCmd:(NSString *)fileName
{
    NSData *data = [DataUtil buildDownloadVideoFromSDCardCmdPack:fileName];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendDeleteSDCardPhotoCmd:(NSString *)fileName
{
    NSData *data = [DataUtil buildDeletePhotoFromSDCardCmdPack:fileName];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendDeleteSDCardVideoCmd:(NSString *)fileName
{
    NSData *data = [DataUtil buildDeleteVideoFromSDCardCmdPack:fileName];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendStartPlaySDCardVideoCmd:(NSString *)fileName
{
    NSData *data = [DataUtil buildStartSDCardVideoPlayBackCmdPack:fileName];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendStopPlaySDCardVideoCmd
{
    NSData *data = [DataUtil buildStopSDCardVideoPlayBackCmdPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendGetSDCardPhotoThumbListCmd:(NSArray *)array
{
    isVideoThumbType = NO;
    NSData *data = [DataUtil buildGetSDCardPhotoThumbListCmdPack:array];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendGetSDCardVideoThumbListCmd:(NSArray *)array
{
    isVideoThumbType = YES;
    NSData *data = [DataUtil buildGetSDCardVideoThumbListCmdPack:array];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

//设置相机端的系统时间
- (void)sendSetupCameraSystemTimeCmd
{
    NSData *data = [DataUtil buildSetCameraSystemTimeCmdPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}
//获取相机端的系统时间
- (void)sendGetCameraSystemTimeCmd
{
    NSData *data = [DataUtil buildGetCameraSystemTimeCmdPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}
//设置相机wifi名字和密码
- (void)sendSetCameraWifiNameCmd:(NSString *)wifiName wifiPasswordKey:(NSString *)password
{
    NSData *data = [DataUtil buildSetCameraWifiCmdPack:wifiName wifiPasswordKey:password];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}
//格式化SD卡请求
- (void)sendFormatSDCardCmd
{
    NSData *data = [DataUtil buildSDCardFormatCmdPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    [super socket:sock didConnectToHost:host port:port];
    [self.client readDataToLength:32 withTimeout:-1 tag:readCmdHeadTag];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    [super socketDidDisconnect:sock withError:err];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    [super socket:sock didWriteDataWithTag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [super socket:sock didReadData:data withTag:tag];
    
    NSLog(@"data:%@",data);
    NSLog(@"打印data size ：%lu",(unsigned long)data.length);
    
    if (tag == readCmdHeadTag) {
        [self decodeCmdData:data withTag:tag];
    }
    else{
        [self decodePackData:data withTag:tag];
        //每次读取完数据包就开始监听下一帧的数据头head
        [self.client readDataToLength:32 withTimeout:-1 tag:readCmdHeadTag];
    }
    
    //[self decodePhotoPackData:data withTag:(long)tag];
}


#pragma mark - DecodeData数据解析
- (void)decodeCmdData:(NSData *)data withTag:(long)tag
{
    //头命令解析
    if (data.length == 32) {
        //NSLog(@"打印出数字：%@",headData);
        CamHeadData recHeadData;
        [data getBytes:&recHeadData length:data.length];

        int dataLength = recHeadData.u32Size;
        recDatalength = dataLength - 32;
        NSLog(@"后面接收数据大小 : %d",recDatalength);

        Size restSize;
        restSize = recDatalength;
        
        if (recHeadData.u32Type == 0x2023 || recHeadData.u32Type == 0x2044)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readTakePhotoPackTag]; //读取指定的字节数
        }
        else if (recHeadData.u32Type == 0x2036)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readStartSDRecordVideoTag];
        }
        else if (recHeadData.u32Type == 0x2038)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readStopSDRecordVideoTag];
        }
        else if (recHeadData.u32Type == 0x2040)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readGetSDCardPhotoListTag];
        }
        else if (recHeadData.u32Type == 0x2032)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readGetSDCardVideoListTag];
        }
        else if (recHeadData.u32Type == 0x2046)
        {
            if (recHeadData.u32Status == 0) {
                isDownVideoComplete = YES;
            }
            else{
                isDownVideoComplete = NO;
            }
            [self.client readDataToLength:restSize withTimeout:-1 tag:readDownloadSDCardVideoTag]; //读取指定的字节数
        }
        else if (recHeadData.u32Type == 0x2042)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readDeleteSDCardPhotoTag];
        }
        else if (recHeadData.u32Type == 0x2030)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readDeleteSDCardVideoTag];
        }
        else if (recHeadData.u32Type == 0x2048)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readSetCameraSystemTimeTag];
        }
        else if (recHeadData.u32Type == 0x2050)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readGetCameraSystemTimeTag];
        }
        else if (recHeadData.u32Type == 0x2054)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readSetCameraWifiTag];
        }
        else if (recHeadData.u32Type == 0x2058)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readSetVideoDirectionTag];
        }
        else if (recHeadData.u32Type == 0x2034)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readStartPlaySDCardVideoTag];
        }
        else if (recHeadData.u32Type == 0x2011)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readGetSDCardThumbListTag];
        }
        else{
            [self.client readDataToLength:restSize withTimeout:-1 tag:0]; //读取指定的字节数
        }
    }
    else{
        //如果不符合要求的话重新读取
        [self.client readDataToLength:32 withTimeout:-1 tag:readCmdHeadTag];
    }
}

- (void)decodePackData:(NSData *)data withTag:(long)tag
{
    NSMutableData *recData = [NSMutableData dataWithData:data];
    if (tag == readTakePhotoPackTag)
    {
        static int count = 0;

        if (recDatalength == recData.length) {
            NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];

                if ([[cmdDic valueForKey:@"errCode"] intValue] == -1) {
                    NSLog(@"报错Message:%@",[cmdDic valueForKey:@"errMsg"]);
                    return;
                }
                NSString *photoName = [cmdDic objectForKey:@"PicName"];
                NSLog(@"照片名字:%@",photoName);
                curPhotoNameStr = photoName;
                //long photoSize = [[cmdDic objectForKey:@"PicSize"] longValue];
                //NSLog(@"照片大小:%lu",photoSize);
                NSString *photoState = [cmdDic objectForKey:@"PicSendState"];
                if ([photoName isEqualToString:curPhotoNameStr]) {
                    NSString *string = [cmdDic objectForKey:@"PicData"];
                    NSData *data = [self base64Decode:string];
                    if (!keepPhotoData) {
                        keepPhotoData = [[NSMutableData alloc] init];
                    }
                    [keepPhotoData appendData:data];
                    NSLog(@"keepPhotoData保存数据大小：%lu",(unsigned long)keepPhotoData.length);
                    if ([photoState isEqualToString:GetPhotoEnd]) {
                        UIImage *image = [UIImage imageWithData:keepPhotoData];
                        NSLog(@"照片接收数据完毕，可以保存");
                        keepPhotoData = nil;
                        count = 0;
                        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
                        [self.delegate didFinishMediaDownloadOperation];
                    }
                    else{
                        count++;
                    }
                }
        }
        NSLog(@"*******数据拼接次数count ：%d********",count);
    }
    else if (tag == readStartSDRecordVideoTag)
    {
        if (recDatalength == recData.length) {
            NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
            if ([[cmdDic objectForKey:@"cmd"] isEqual:@"startSdRecordRsp"]) {
                if ([[cmdDic valueForKey:@"staCode"] intValue] == -1) {
                    NSLog(@"报错Message:%@",[cmdDic valueForKey:@"staMsg"]);
                    return;
                }
                NSLog(@"录像信息Message：%@",[cmdDic valueForKey:@"staMsg"]);
            }
        }
    }
    else if (tag == readStopSDRecordVideoTag)
    {
        if (recDatalength == recData.length) {
            NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
            if ([[cmdDic objectForKey:@"cmd"] isEqual:@"stopSdRecordRsp"]) {
                if ([[cmdDic valueForKey:@"staCode"] intValue] == -1) {
                    NSLog(@"报错Message:%@",[cmdDic valueForKey:@"staMsg"]);
                    return;
                }
                NSLog(@"录像信息Message：%@",[cmdDic valueForKey:@"staMsg"]);
            }
        }
    }
    else if (tag == readGetSDCardPhotoListTag)
    {
        if (recDatalength == recData.length) {
            NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
            if ([[cmdDic objectForKey:@"cmd"] isEqual:@"getSdPicListRsp"]) {
                if ([[cmdDic valueForKey:@"staCode"] intValue] == -1) {
                    NSLog(@"报错Message:%@",[cmdDic valueForKey:@"staMsg"]);
                    return;
                }
                int photoListNums = [[cmdDic objectForKey:@"picListsLen"] intValue];
                NSLog(@"SD卡图像列表返回的照片数量:%d",photoListNums);
                NSArray *photoListArray = [cmdDic objectForKey:@"picLists"];
                NSLog(@"SD卡返回的图像列表:%@",photoListArray);
                //图像数据处理
                [self.delegate getMeidaList:photoListArray mediaType:0];
            }
        }
    }
    else if (tag == readGetSDCardVideoListTag)
    {
        if (recDatalength == recData.length) {
            NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
            if ([[cmdDic objectForKey:@"cmd"] isEqual:@"getSdRecListRsp"]) {
                if ([[cmdDic valueForKey:@"staCode"] intValue] == -1) {
                    NSLog(@"报错Message:%@",[cmdDic valueForKey:@"staMsg"]);
                    return;
                }
                int photoListNums = [[cmdDic objectForKey:@"recListsLen"] intValue];
                NSLog(@"SD卡视频列表返回的视频数量:%d",photoListNums);
                NSArray *photoListArray = [cmdDic objectForKey:@"recLists"];
                NSLog(@"SD卡返回的视频列表:%@",photoListArray);
                //图像数据处理
                [self.delegate getMeidaList:photoListArray mediaType:1];
            }
        }
    }
    else if (tag == readDownloadSDCardVideoTag)
    {
        //MARK:视频下载
        if (recData.length > 1024) {
            NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
            if ([[cmdDic objectForKey:@"cmd"] isEqual:@"sdRecDownloadRsp"]) {
                if ([[cmdDic valueForKey:@"staCode"] intValue] == -1) {
                    NSLog(@"报错Message:%@",[cmdDic valueForKey:@"staMsg"]);
                    return;
                }
            }
        }
        //数据量大是视频数据
        Mp4DownloadInfo_T mp4DownloadInfo;
        [recData getBytes:&mp4DownloadInfo length:recData.length];
        //保存视频数据
        if (!videoData) {
            videoData = [[NSMutableData alloc] init];
        }
        
        //视频数据下载中
        NSUInteger dataSize = mp4DownloadInfo.mp4PktSize;
        int packageNum = mp4DownloadInfo.mp4PktSeq;
        [videoData appendData:[NSData dataWithBytes:&mp4DownloadInfo.mp4PktData length:dataSize]];
        NSLog(@"---序号%d 正在下载视频数据中:%lu---",packageNum,dataSize);
        
        if (isDownVideoComplete) {
            NSLog(@"---视频数据下载完成 : %lu---",videoData.length);
            //最后一步视频下载完成
            if (self.filePath) {
                [videoData writeToFile:self.filePath atomically:YES];
                UISaveVideoAtPathToSavedPhotosAlbum(self.filePath, self, @selector(videoPatch:didFinishSavingWithError:contextInfo:), nil);;
                videoData = nil;
                //验证Md5校验码
                NSLog(@"---视频保存完成---");
                [self.delegate didFinishMediaDownloadOperation];
            }
        }

    }
    else if (tag == readDeleteSDCardPhotoTag || tag == readDeleteSDCardVideoTag)
    {
        //删除SD卡文件
        NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
        if ([[cmdDic valueForKey:@"staCode"] intValue] == -1) {
            NSLog(@"报错Message:%@",[cmdDic valueForKey:@"errMsg"]);
            return;
        }
        else{
            NSLog(@"删除文件成功!!!");
        }
    }
    else if (tag == readSetVideoDirectionTag)
    {
        //删除SD卡文件
        NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
        if ([[cmdDic valueForKey:@"staCode"] intValue] == -1) {
            NSLog(@"报错Message:%@",[cmdDic valueForKey:@"errMsg"]);
            return;
        }
        else{
            NSLog(@"Message:设置视频方向成功!!!!!");
        }
    }
    else if (tag == readStartPlaySDCardVideoTag)
    {
        //播放sdcard视频信息
        NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
        if ([[cmdDic valueForKey:@"staCode"] intValue] == -1) {
            NSLog(@"报错Message:%@",[cmdDic valueForKey:@"errMsg"]);
            return;
        }
        else{
            NSLog(@"Message:设置开始回放SDCard视频 \n%@",cmdDic);
            [self.delegate startVideoPlayback];
        }
    }
    else if (tag == readGetSDCardThumbListTag)
    {
        //获取当前图片视频的缩略图
        NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
        if ([[cmdDic objectForKey:@"cmd"] isEqual:@"getSdThumListRsp"]) {
            
            NSArray *thumbArray = [cmdDic objectForKey:@"thumLists"];
            NSArray *array = [self parseThunmbData:thumbArray videoThumbType:isVideoThumbType];
            NSLog(@"缩略图:%lu",(unsigned long)array.count);
            [self.delegate didGetThumbList:array];
        }
    }
    else
    {
        NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
        if ([[cmdDic valueForKey:@"staCode"] intValue] == -1) {
            NSLog(@"报错Message:%@",[cmdDic valueForKey:@"errMsg"]);
        }
        else{
            
            if ([[cmdDic valueForKey:@"cmd"] isEqual:@"sdCardFormatRsp"]) {
                [self.delegate didFinishFormatSDCard];
            }
            
            NSLog(@"Message:设置成功!!!!! \n%@",cmdDic);
        }
    }

}

- (void)decodePhotoPackData:(NSData *)data withTag:(long)tag
{
    NSMutableData *recData = [NSMutableData dataWithData:data];
    if (tag == readTakePhotoCmdHeadTag && recData.length >= 32) {
        NSData *headData = [recData subdataWithRange:NSMakeRange(0, 32)];
        //NSLog(@"打印出数字：%@",headData);
        CamHeadData recHeadData;
        [headData getBytes:&recHeadData length:headData.length];

        if (recHeadData.u32Type == 0x2023)
        {
            NSData *resultData = [recData subdataWithRange:NSMakeRange(32, recData.length - 32)];
            NSLog(@"接收头数据Data:%@",resultData);
            int dataLength = recHeadData.u32Size;
            recDatalength = dataLength - 32;
            NSLog(@"后面接收数据大小 : %d",recDatalength);

            Size restSize;
            restSize = dataLength - recData.length;
            [self.client readDataToLength:restSize withTimeout:-1 tag:readTakePhotoPackTag]; //读取指定的字节数
        }
    }
    else if (tag == readTakePhotoPackTag)
    {
        static int count = 0;

        if (recDatalength == recData.length) {
            NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];

            if ([[cmdDic objectForKey:@"cmd"] isEqual:@"CaptureResp"]) {

                if ([[cmdDic valueForKey:@"errCode"] intValue] == -1) {
                    NSLog(@"报错Message:%@",[cmdDic valueForKey:@"errMsg"]);
                    return;
                }
                
                NSString *photoName = [cmdDic objectForKey:@"PicName"];
                NSLog(@"照片名字:%@",photoName);
                curPhotoNameStr = photoName;

                long photoSize = [[cmdDic objectForKey:@"PicSize"] longValue];
                NSLog(@"照片大小:%lu",photoSize);

                NSString *photoState = [cmdDic objectForKey:@"PicSendState"];
                NSLog(@"照片大小:%lu",photoSize);

                if ([photoName isEqualToString:curPhotoNameStr]) {
                    NSString *string = [cmdDic objectForKey:@"PicData"];
                    NSData *data = [self base64Decode:string];
                    if (!keepPhotoData) {
                        keepPhotoData = [[NSMutableData alloc] init];
                    }
                    [keepPhotoData appendData:data];
                    NSLog(@"keepPhotoData保存数据大小：%lu",(unsigned long)keepPhotoData.length);
                    if ([photoState isEqualToString:GetPhotoEnd]) {
                        UIImage *image = [UIImage imageWithData:keepPhotoData];
                        NSLog(@"照片接收数据完毕，可以保存");
                        keepPhotoData = nil;
                        count = 0;
                        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
                    }
                    else{
                        count++;
                    }
                }
            }
        }
        [self.client readDataToLength:32 withTimeout:-1 tag:readTakePhotoCmdHeadTag]; //读取指定的字节数
        NSLog(@"*******数据拼接次数count ：%d********",count);
    }

}

#pragma mark - 缩略图解析
- (NSArray *)parseThunmbData:(NSArray *)array videoThumbType:(BOOL)isVideoType
{
    NSMutableArray *thumbArray = [NSMutableArray array];
    int listNum = array.count;
    for (int i = 0; i < listNum; i++) {
        NSDictionary *dic = (NSDictionary *)array[i];
        NSMutableDictionary *thumbDic = [[NSMutableDictionary alloc] init];
        NSString *fileByName = [[[dic objectForKey:@"thumName"] lastPathComponent] stringByDeletingPathExtension];
        NSString *thumbName;
        //MARK:这里存在是否要加后缀来区分争议
        if (isVideoType) {
            thumbName = [NSString stringWithFormat:@"%@.mp4",fileByName];
        }
        else{
            thumbName = [NSString stringWithFormat:@"%@.jpg",fileByName];
        }
        NSString *thumbDataStr = [dic objectForKey:@"thumData"];
        NSData *data = [self base64Decode:thumbDataStr];
        UIImage *image = [UIImage imageWithData:data];
        //出现数据无法转成图像报错
        if (image) {
            [thumbDic setObject:thumbName forKey:@"thumName"];
            [thumbDic setObject:image forKey:@"image"];
            [thumbArray addObject:thumbDic];
        }
        else{
            NSLog(@"报错打印：获取缩略图失败!!!!!!!!!!");
        }
        
    }
    return thumbArray;
}


#pragma mark - 字符串解析base64EncodeOrDecode
- (NSString *)base64Encode:(NSString *)str{
    NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

- (NSData *)base64Decode:(NSString *)str{
    NSData *sData = [[NSData alloc]initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return sData;
}

- (NSString *)filePath
{
    if (!_filePath) {
        _filePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Video_2022.mp4"];
    }
    return _filePath;
}

-(void)videoPatch:(UIImage*)image didFinishSavingWithError:(id)error contextInfo:(id)info
{
    if (!error) {
        NSLog(@"保存相册成功");
    }else{
        NSLog(@"保存相册失败");
    }
}

@end
