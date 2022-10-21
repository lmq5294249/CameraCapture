//
//  McuSocketManager.m
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/1.
//

#define writePingCmdTag 100
#define writeCmdTag 101

#define readCmdHeadTag 201
#define readPingDataTag 202
#define readYunTaiDataTag 203

#import "McuSocketManager.h"

@interface McuSocketManager ()
{
    int recDatalength;
}
@end

@implementation McuSocketManager

- (instancetype)init
{
    if (self = [super init]) {
        self.host = @"192.168.2.1";
        self.port = 8887;
        self.queueName = "MCUCtrlDataQueue";
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

- (void)sendPingHeartPack
{
    NSData *data = [DataUtil buildPingHeartPack];
    [self.client writeData:data withTimeout:-1 tag:writePingCmdTag];
}

- (void)sendData:(NSData *)data
{
    NSData *packData = [DataUtil buildYunTaiDataPack:data];
    [self.client writeData:packData withTimeout:-1 tag:writeCmdTag];
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
    
    if (tag == readCmdHeadTag) {
        [self decodeCmdData:data withTag:tag];
    }
    else{
        [self decodePackData:data withTag:tag];
        [self.client readDataToLength:32 withTimeout:-1 tag:readCmdHeadTag];
    }
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
        
        if (recHeadData.u32Type == 0x2028 || recHeadData.u32Type == 0x2025)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readPingDataTag]; //读取指定的字节数
        }
        else if (recHeadData.u32Type == 0x2026)
        {
            [self.client readDataToLength:restSize withTimeout:-1 tag:readYunTaiDataTag]; //读取指定的字节数
        }
    }
}

- (void)decodePackData:(NSData *)data withTag:(long)tag
{
    NSMutableData *recData = [NSMutableData dataWithData:data];
    if (tag == readYunTaiDataTag)
    {
        if (recDatalength == recData.length) {
            //判断是否满足返回数据的大小
            /*
             typedef struct UartCmd{
             char cCmdData[64]; //存放指令内容 64字节
             int iCmdLen; //指令长度 4字节
             }UartCmd_T;
             */
            if (recData.length == 68) {
                NSData *yunData = [DataUtil unPackYunTaiData:recData];
            }
        }
    }
    else if (tag == readPingDataTag)
    {
        
    }
}

@end
