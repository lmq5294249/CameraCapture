//
//  UpgradeSocketManager.m
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/14.
//

#define writePingCmdTag 100
#define writeCmdTag 101

#define readCmdHeadTag 301
#define readFirewareInfoTag 302
#define readFirewareDataTag 303
#define readFirewareUpgradeTag 304

#import "UpgradeSocketManager.h"
#import "FirmwareTool.h"
#import <CommonCrypto/CommonCrypto.h>
#import "MQLogInfo.h"

const static NSString *firmwareMD5Str = @"30613161656365666261636166323937";

@interface UpgradeSocketManager ()
{
    int recDatalength;
    long fileSize;
    int numPkt;
    
    BOOL readFileEnd;
    char *md5code;
}
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *md5Str;
@property (nonatomic, strong) NSData *fileData;
@end

@implementation UpgradeSocketManager

- (instancetype)init
{
    if (self = [super init]) {
        self.host = @"192.168.2.1";
        self.port = 9887;
        self.queueName = "FirmwareUpgradeQueue";
        self.client = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create(self.queueName, nil)];
        self.client.delegate = self;
    }
    return self;
}

- (void)connectToServer
{
    [self.client connectToHost:self.host onPort:self.port error:nil];
    self.client.delegate = self;
}

- (void)sendGetCameraFirmwareInfoCmd
{
    NSData *data = [DataUtil buildGetCameraFirmwareInfoPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendUpgradeCameraFirmwareCmd
{
    NSData *data = [DataUtil buildUpgradeCameraFirmwareCmdPack];
    [self.client writeData:data withTimeout:-1 tag:writeCmdTag];
}

- (void)sendCameraFirmwareFile:(NSString *)fileString
{
    md5code = [self stringFromHexString:firmwareMD5Str];
    self.fileData = [NSData dataWithContentsOfFile:fileString];
    fileSize = self.fileData.length;
    NSLog(@"文件大小: %d",(unsigned int)fileSize);
    //重置计数
    numPkt = -1;
    readFileEnd = NO;
    [self sendCameraFirmwareData];
}

- (void)sendCameraFirmwareData
{
    NSData *data = [self getNextFirewareData];
    NSData *packData = [DataUtil buildCameraFirmwareDataCmdPack:data fileMd5:md5code pktSeq:numPkt sendPktComplete:readFileEnd];
    [self.client writeData:packData withTimeout:-1 tag:writeCmdTag];
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    [super socket:sock didConnectToHost:host port:port];
    [self.client readDataToLength:32 withTimeout:-1 tag:readCmdHeadTag];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [super socket:sock didReadData:data withTag:tag];
    
    if (tag == readCmdHeadTag) {
        [self decodeCmdData:data withTag:tag];
    }
    else{
        [self decodePackData:data withTag:tag];
        [self.client readDataToLength:32 withTimeout:-1 tag:readCmdHeadTag];
    }
}

- (void)decodeCmdData:(NSData *)data withTag:(long)tag
{
    //头命令解析
    if (data.length == 32) {
        //NSLog(@"打印出数字：%@",headData);
        T_HHUPSDKHeader recHeadData;
        [data getBytes:&recHeadData length:data.length];

        recDatalength = recHeadData.dataLen;
        NSLog(@"后面接收数据大小 : %d",recDatalength);
        Size restSize = recDatalength;
        
        if (recHeadData.cmdId == 10004 && recHeadData.cmdType == 2)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readFirewareInfoTag]; //读取指定的字节数
        }
        else if (recHeadData.cmdId == 10001 && recHeadData.cmdType == 2)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readFirewareDataTag]; //读取指定的字节数
        }
        else if (recHeadData.cmdId == 10002 && recHeadData.cmdType == 2)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readFirewareUpgradeTag]; //读取指定的字节数
        }
    }
}

- (void)decodePackData:(NSData *)data withTag:(long)tag
{
    NSMutableData *recData = [NSMutableData dataWithData:data];
    if (tag == readFirewareInfoTag)
    {
        if (recDatalength == recData.length) {
            //判断是否满足返回数据的大小
            /*
             "cmd":"getFwInfoRsp", //返回指令
              "FwInfo":{ //当前固件信息
              "PName":"EyePic", //设备产品名称
              "Date":”20220913111112”, //固件生成日期，具体到秒
              "Version": "V1.0" //固件版本号
              }
             */
            NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
            if ([[cmdDic objectForKey:@"cmd"] isEqual:@"getFwInfoRsp"]) {
                NSDictionary *fwDic = [cmdDic objectForKey:@"FwInfo"];
                NSLog(@"打印字典信息：%@",fwDic);
            }
        }
    }
    else if (tag == readFirewareDataTag)
    {
        NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
        if ([[cmdDic objectForKey:@"cmd"] isEqual:@"sendUpPkgRsp"]) {
            if ([[cmdDic objectForKey:@"staCode"] intValue] == 0) {
                if ([[cmdDic objectForKey:@"staMsg"] containsString:@"recvOnePkgOk"]) {
                    NSLog(@"发送固件数据成功 numPacket = %d",numPkt);
                    if (numPkt == 0) {
//                        NSString *infoStr = [NSString stringWithFormat:@"发送固件数据成功 numPacket = %d\n",numPkt];
//                        [MQLogInfo writeToFileWithString:infoStr fileName:@"Upgrade"];
                        [self.delegate didUpgradeFirmwareProgress:1 completed:NO];
                    }
                    [self sendCameraFirmwareData];
                }
                else if ([[cmdDic objectForKey:@"staMsg"] containsString:@"recvAllPkgOk"]){
                    NSLog(@"===========所有的包接收完毕=========");
                    [self sendUpgradeCameraFirmwareCmd];
                }
                else{
                    NSLog(@"**********升级包接收错误***********");
                }
            }
            else{
                if (readFileEnd) {
                    NSLog(@"**********升级包错误需要重发***********");
                }
                else{
                    NSLog(@"-----前一包需要重发数据-----");
                    numPkt--;
                    [self sendCameraFirmwareData];
                }
            }
        }
    }
    else if (tag == readFirewareUpgradeTag)
    {
        NSDictionary *cmdDic = [NSJSONSerialization JSONObjectWithData:recData options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"cmdDic:\n%@",cmdDic);
        if ([[cmdDic objectForKey:@"cmd"] isEqual:@"FwUpgradeRsp"]) {
            if ([[cmdDic objectForKey:@"staCode"] intValue] == 0) {
                NSLog(@"========成功正在升级并重启系统=======");
                NSString *infoStr = [NSString stringWithFormat:@"========成功正在升级并重启系统======="];
                [MQLogInfo writeToFileWithString:infoStr fileName:@"Upgrade"];
                [self.delegate didUpgradeFirmwareProgress:100 completed:YES];
            }
            else{
                NSLog(@"失败打印cmdDic：%@",cmdDic);
            }
        }
    }
    
}

#pragma mark - 固件数据
- (NSData *)getNextFirewareData
{
    numPkt ++;
    NSLog(@"文件大小: %d",numPkt);
    //获取文件数据 2048字节
    int nextIndex = numPkt * 2048;
    static int readBytes = 2048;
    if (nextIndex + 2048 > fileSize) {
        readBytes = (int)fileSize - nextIndex;
    }
    else{
        readBytes = 2048;
    }
    if (readBytes > 2048) {
        return nil;
    }
    NSData *tempData = [self.fileData subdataWithRange:NSMakeRange(nextIndex, readBytes)];
    if ((numPkt+1) * 2048 > fileSize && numPkt*2048 < fileSize) {
        readFileEnd = YES;
    }
    return tempData;
}

// 十六进制转换为普通字符串的。
- (char *)stringFromHexString:(NSString *)hexString
{
    if(hexString.length % 2 != 0)
    {
        return nil;
    }
    char *myBuffer = (char *)malloc((int)[hexString length] / 2 + 1);
    bzero(myBuffer, [hexString length] / 2 + 1);
    for (int i = 0; i < [hexString length] - 1; i += 2)
    {
        unsigned int anInt;
        NSString * hexCharStr = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner * scanner = [[NSScanner alloc] initWithString:hexCharStr];
        [scanner scanHexInt:&anInt];
        myBuffer[i / 2] = (char)anInt;
    }
    NSString *unicodeString = [NSString stringWithCString:myBuffer encoding:NSUTF8StringEncoding];
    NSLog(@"打印字符串size = %d",strlen(myBuffer));
    //验证数据
//    int8_t result[16];
//    for (int i = 0; i < 16; i++) {
//        result[i] = myBuffer[i];
//    }
//    NSMutableString *ret = [NSMutableString stringWithCapacity:16*2];//准备一个字符串,用来把字节数组转成字符串
//    for(int i = 0; i<16; i++) {
//        [ret appendFormat:@"%02x",result[i]];
//        NSLog(@"%@",ret);
//    }
    return myBuffer;
}

@end
