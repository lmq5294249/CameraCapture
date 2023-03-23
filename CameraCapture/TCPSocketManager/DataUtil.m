//
//  DataUtil.m
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/1.
//

#import "DataUtil.h"

@implementation DataUtil

#pragma mark - Header头命令
+(NSData *)buildHeadPackWithU32Type:(UInt32)typeValue Id:(UInt32)idValue dataPackLength:(NSUInteger)length
{
    CamHeadData headData;
    headData.u32Size = 32 + length;
    headData.u32Type = typeValue;
    headData.u32Status = 0;
    headData.u32Channel = 0;
    headData.u32Time = 0;
    headData.u32Data = 0;
    headData.u32Id = idValue;
    headData.u32Level = 0;
    int sizeOfData = sizeof(headData);
    NSMutableData *data = [NSMutableData dataWithBytes:&headData length:sizeOfData];
    
    return data;
}

//MARK:心跳包
+(NSData *)buildPingHeartPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *dic = @{@"cmd":@"AppHeartBitReq"};
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2027 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//MARK:云台透传数据包
+(NSData *)buildYunTaiDataPack:(NSData *)data
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    UartCmd_T uartCmd_T;
    [data getBytes:&uartCmd_T.cCmdData length:data.length];
    uartCmd_T.iCmdLen = sizeof(data);
    NSData *cmdData = [[NSData alloc] initWithBytes:&uartCmd_T length:sizeof(uartCmd_T)];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2024 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

+(NSData *)unPackYunTaiData:(NSData *)data
{
    NSMutableData *recData = [[NSMutableData alloc] initWithData:data];
    UartCmd_T uartCmd_T;
    int length = 64;
    [recData getBytes:&uartCmd_T.cCmdData length:length];
    //算出有效data的大小
    NSData *sizeData = [recData subdataWithRange:NSMakeRange(64, 4)];
    [sizeData getBytes:&uartCmd_T.iCmdLen length:sizeData.length];
    NSData *resultData = [recData subdataWithRange:NSMakeRange(0, uartCmd_T.iCmdLen)];
    return resultData;
}

#pragma mark - Pack
//实时视频翻转镜像设置
+(NSData *)buildFlipRealTimeVideoCmdPack:(NSDictionary *)dic
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    NSMutableDictionary *flipDic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"VideoMirrFlipSetReq",@"cmd", nil];
//    NSDictionary *flipDic = @{@"cmd":@"VideoMirrFlipSetReq",
//                              @"mirror":@0,
//                              @"flip":@0
//    };
    if (dic) {
        [flipDic addEntriesFromDictionary:dic];
    }
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:flipDic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2057 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    return packData;
}

+(NSData *)buildTakePhotoCmdPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *takePhotoDic = @{@"cmd":@"CaptureReq"};
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:takePhotoDic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2022 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

+(NSData *)buildStartRecordCmdPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *startRecordDic = @{@"cmd":@"startSdRecordReq",
                                   @"recordType":@"mp4"
    };
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:startRecordDic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2035 Id:0x3A5A5A5A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

+(NSData *)buildStopRecordCmdPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *stopRecordDic = @{@"cmd":@"stopSdRecordReq"};
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:stopRecordDic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2037 Id:0x3A5A5A5A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//SD 卡图片列表获取请求
+(NSData *)buildGetSDCardPhotoListCmdPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *dic = @{@"cmd":@"getSdPicListReq"};
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2039 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//SD 卡图片缩略图列表获取请求
+(NSData *)buildGetSDCardPhotoThumbListCmdPack:(NSArray *)fileArray
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    NSNumber *fileNum = [NSNumber numberWithUnsignedInteger:fileArray.count];
//    NSArray *testArray = @[@{@"file_name":@"/media/photo/PHOTO_000000.jpg"},
//                              @{@"file_name":@"/media/photo/PHOTO_000001.jpg"},
//                              @{@"file_name":@"/media/photo/PHOTO_000002.jpg"},
//                              @{@"file_name":@"/media/photo/PHOTO_000003.jpg"},
//                              @{@"file_name":@"/media/photo/PHOTO_000004.jpg"}
//    ];
    NSDictionary *dic = @{@"cmd":@"getSdThumListReq",
                          @"type":@"picList",
                          @"reqListLen":fileNum,
                          @"reqList":fileArray
    };
    NSLog(@"打印字典:%@",dic);
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:cmdData encoding:NSUTF8StringEncoding];
    NSString *jsonString2 = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSString *jsonString3 = [jsonString2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    cmdData = [jsonString3 dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"打印字符转:%@",jsonString3);
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2010 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//SD 卡图片下载请求
+(NSData *)buildDownloadPhotoFromSDCardCmdPack:(NSString *)fileName
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *dic = @{@"cmd":@"sdPicDownloadReq",
                          @"file_name":fileName
    };
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:cmdData encoding:NSUTF8StringEncoding];
    NSString *jsonString2 = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSString *jsonString3 = [jsonString2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    cmdData = [jsonString3 dataUsingEncoding:NSUTF8StringEncoding];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2043 Id:0x3A5A5A5A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//SD 卡图片删除请求
+(NSData *)buildDeletePhotoFromSDCardCmdPack:(NSString *)fileName
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *dic = @{@"cmd":@"removePicFileReq",
                          @"file_name":fileName
    };
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:cmdData encoding:NSUTF8StringEncoding];
    NSString *jsonString2 = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSString *jsonString3 = [jsonString2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    cmdData = [jsonString3 dataUsingEncoding:NSUTF8StringEncoding];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2041 Id:0x3A5A5A5A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//SD 卡录像文件列表获取请求
+(NSData *)buildGetSDCardVideoListCmdPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *dic = @{@"cmd":@"getSdRecListReq"};
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2031 Id:0x3A5A5A5A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//SD 卡视频缩略图列表获取请求
+(NSData *)buildGetSDCardVideoThumbListCmdPack:(NSArray *)fileArray
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    NSNumber *fileNum = [NSNumber numberWithUnsignedInteger:fileArray.count];
    NSDictionary *dic = @{@"cmd":@"getSdThumListReq",
                          @"type":@"recList",
                          @"reqListLen":fileNum,
                          @"reqList":fileArray
    };
//    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:cmdData encoding:NSUTF8StringEncoding];
    NSString *jsonString2 = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSString *jsonString3 = [jsonString2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    cmdData = [jsonString3 dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"打印字符转:%@",jsonString3);
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2010 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//SD 卡录像文件删除请求
+(NSData *)buildDeleteVideoFromSDCardCmdPack:(NSString *)fileName
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *dic = @{@"cmd":@"removeMp4FileReq",
                          @"file_name":fileName
    };
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:cmdData encoding:NSUTF8StringEncoding];
    NSString *jsonString2 = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSString *jsonString3 = [jsonString2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    cmdData = [jsonString3 dataUsingEncoding:NSUTF8StringEncoding];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2029 Id:0x3A5A5A5A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//SD 卡录像文件下载请求
+(NSData *)buildDownloadVideoFromSDCardCmdPack:(NSString *)fileName
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *dic = @{@"cmd":@"sdRecDownloadReq",
                          @"file_name":fileName
    };
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:cmdData encoding:NSUTF8StringEncoding];
    NSString *jsonString2 = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSString *jsonString3 = [jsonString2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    cmdData = [jsonString3 dataUsingEncoding:NSUTF8StringEncoding];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2045 Id:0x3A5A5A5A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//SD 卡录像文件回放开始请求
+(NSData *)buildStartSDCardVideoPlayBackCmdPack:(NSString *)fileName
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *dic = @{@"cmd":@"sdRecRePlyStartReq",
                          @"file_name":fileName
    };
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:cmdData encoding:NSUTF8StringEncoding];
    NSString *jsonString2 = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSString *jsonString3 = [jsonString2 stringByReplacingOccurrencesOfString:@" " withString:@""];
    cmdData = [jsonString3 dataUsingEncoding:NSUTF8StringEncoding];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2033 Id:0x3A5A5A5A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//SD 卡录像文件回放停止请求
+(NSData *)buildStopSDCardVideoPlayBackCmdPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    NSDictionary *dic = @{@"cmd":@"sdRecRePlyStopReq"
    };
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2051 Id:0x3A5A5A5A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    
    return packData;
}

//时间设置请求
+(NSData *)buildSetCameraSystemTimeCmdPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    NSDictionary *cmdDic = @{@"cmd":@"setSystemTimeReq"};
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithDictionary:cmdDic];
    NSDictionary *dataDic = [self getCurrentSystemTime];
    [dic addEntriesFromDictionary:dataDic];
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2047 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    return packData;
}

//时间获取请求
+(NSData *)buildGetCameraSystemTimeCmdPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    NSDictionary *dic = @{@"cmd":@"getSystemTimeReq"};
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2049 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    return packData;
}

//名称和密码设置请求
+(NSData *)buildSetCameraWifiCmdPack:(NSString *)wifiName wifiPasswordKey:(NSString *)password
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    NSDictionary *contentDic = @{@"ssid":wifiName,
                                 @"psk":password,
                                 @"encryptKey":@"on"
    };
    NSDictionary *cmdDic = @{@"cmd":@"WifiApOpenReq",
                             @"content":contentDic
    };
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithDictionary:cmdDic];
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2053 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    return packData;
}

//格式化SD 卡请求
+(NSData *)buildSDCardFormatCmdPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    NSDictionary *dic = @{@"cmd":@"sdCardFormatReq"};
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    long length = cmdData.length;
    //命令头
    NSData *headData = [self buildHeadPackWithU32Type:0x2055 Id:0x3A6A6A6A dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    return packData;
}

#pragma mark - unPack
+(NSData *)unPackDataPack:(NSData *)data
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    
    return packData;
}

+(NSDictionary *)unPackCmdPack:(NSData *)data
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    return dic;
}

#pragma mark - 固件升级指令
+(NSData *)buildUpgradeHeadPackWithIdentify:(UInt32)identifyValue
                                    U32Type:(UInt32)typeValue
                                         Id:(UInt32)idValue
                                    PktType:(UInt32)pktTypeValue
                                     PktSeq:(UInt32)pktSeqValue
                             dataPackLength:(UInt32)length
{
    T_HHUPSDKHeader headData;
    headData.identify = identifyValue;
    headData.cmdType = typeValue;
    headData.cmdId = idValue;
    headData.pktType = pktTypeValue;
    headData.pktSeq = pktSeqValue;
    headData.sessionID = 0;
    headData.status = 0;
    headData.dataLen = length;
    int sizeOfData = sizeof(headData);
    NSMutableData *data = [NSMutableData dataWithBytes:&headData length:sizeOfData];
    
    return data;
}

+(NSData *)buildGetCameraFirmwareInfoPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    NSDictionary *dic = @{@"cmd":@"getFwInfoReq"};
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    UInt32 length = (UInt32)cmdData.length;
    //命令头
    NSData *headData = [self buildUpgradeHeadPackWithIdentify:0x6ABABABA
                                   U32Type:1
                                        Id:10004
                                   PktType:0
                                    PktSeq:0
                            dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    return packData;
}

+(NSData *)buildUpgradeCameraFirmwareCmdPack
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    NSDictionary *dic = @{@"cmd":@"FwUpgradeReq"};
    NSData *cmdData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    UInt32 length = (UInt32)cmdData.length;
    //命令头
    NSData *headData = [self buildUpgradeHeadPackWithIdentify:0x6ABABABA
                                   U32Type:1
                                        Id:10002
                                   PktType:0
                                    PktSeq:0
                            dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    return packData;
}

+(NSData *)buildCameraFirmwareDataCmdPack:(NSData *)data fileMd5:(const char *)md5Code pktSeq:(UInt32)numPkt sendPktComplete:(BOOL)state
{
    NSMutableData *packData = [[NSMutableData alloc] init];
    T_UpPkgData_Info upPkgDataInfo;
    [data getBytes:&upPkgDataInfo.UpPkgData length:data.length];
    upPkgDataInfo.UpPkgDataSize = (uint32_t)data.length;
    for (int i = 0; i < 16; i++)
    {
        upPkgDataInfo.Md5Code[i] = md5Code[i];
    }
    NSData *cmdData = [[NSData alloc] initWithBytes:&upPkgDataInfo length:sizeof(upPkgDataInfo)];
    UInt32 length = (UInt32)cmdData.length;
    //命令头
    int type = 2;
    if (state == YES) {
        type = 1;
    }
    if (numPkt == 0) {
        type = 2;
    }
    NSData *headData = [self buildUpgradeHeadPackWithIdentify:0x6ABABABA
                                   U32Type:1
                                        Id:10001
                                   PktType:type
                                    PktSeq:numPkt
                            dataPackLength:length];
    [packData appendData:headData];
    [packData appendData:cmdData];
    return packData;
}

#pragma mark - Public
+(NSDictionary *)getCurrentSystemTime
{
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSInteger unitFlags =  NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday |
    NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *comps = [calendar components:unitFlags fromDate:date];
    NSInteger year = [comps year];
    NSInteger month = [comps month];
    NSInteger day = [comps day];
    NSInteger hour = [comps hour];
    NSInteger min = [comps minute];
    NSInteger sec = [comps second];
    NSDictionary *dic = @{@"year":[NSNumber numberWithInteger:year],
                          @"mon":[NSNumber numberWithInteger:month],
                          @"day":[NSNumber numberWithInteger:day],
                          @"hour":[NSNumber numberWithInteger:hour],
                          @"min":[NSNumber numberWithInteger:min],
                          @"sec":[NSNumber numberWithInteger:sec]
    };
    return dic;
}

+ (NSString *)base64Encode:(NSString *)str{
    NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

@end
