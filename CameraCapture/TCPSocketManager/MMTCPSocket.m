//
//  MMTCPSocket.m
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/1.
//

#import "MMTCPSocket.h"

@interface MMTCPSocket ()

@end

@implementation MMTCPSocket

- (instancetype)initWithHost:(NSString *)host Port:(UInt16)port QueueName:(char *)queueName
{
    if (self = [super init]) {
        self.host = host;
        self.port = port;
        self.queueName = queueName;
        
        [self initGCDTCPSocket];
    }
    return self;
}

- (void)initGCDTCPSocket
{
    _client = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create(self.queueName, nil)];
    _client.delegate = self;
}

- (BOOL)isConnected
{
    if (_client.isConnected) {
        return YES;
    }
    return NO;
}

- (void)disConnected
{
    [_client disconnect];
}

- (void)connectToServer{

    [_client connectToHost:self.host onPort:self.port error:nil];
    
}

- (void)connectToServer:(dispatch_block_t)block
{
    [_client connectToHost:self.host onPort:self.port error:nil];
    self.executeBlock = block;
}

- (void)sendData:(NSData *)data tag:(long)tag
{
    [self.client writeData:data withTimeout:-1 tag:tag];
}

- (void)readDataWithtag:(long)tag
{
    [self.client readDataWithTimeout:-1 tag:tag];
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"*****TCP:连接成功*****");
    if (self.executeBlock) {
        self.executeBlock();
    }
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"*****TCP:断开连接*****");
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"---------------写数据---------------");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
}


@end
