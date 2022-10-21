//
//  MMTCPSocket.h
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/1.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
NS_ASSUME_NONNULL_BEGIN

@interface MMTCPSocket : NSObject<GCDAsyncSocketDelegate>

@property (nonatomic,strong) NSString *host;
@property (assign) UInt16 port;
@property (nonatomic,assign) char *queueName;
@property (nonatomic, strong) GCDAsyncSocket *client;
@property (nonatomic) dispatch_block_t executeBlock;

- (instancetype)initWithHost:(NSString *)host Port:(UInt16)port QueueName:(char *)queueName;

- (void)connectToServer;

- (void)connectToServer:(dispatch_block_t)block;

- (BOOL)isConnected;

- (void)disConnected;

- (void)sendData:(NSData *)data tag:(long)tag;

- (void)readDataWithtag:(long)tag;
@end

NS_ASSUME_NONNULL_END
