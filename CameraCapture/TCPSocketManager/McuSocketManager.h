//
//  McuSocketManager.h
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/1.
//

#import "MMTCPSocket.h"
#import "DataUtil.h"
NS_ASSUME_NONNULL_BEGIN

@interface McuSocketManager : MMTCPSocket

- (void)sendPingHeartPack;
- (void)sendData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
