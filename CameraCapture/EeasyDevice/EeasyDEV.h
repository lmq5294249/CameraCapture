//
//  EeasyDEV.h
//  CameraCapture
//
//  Created by 林漫钦 on 2022/9/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RtspConnection.h"

@interface EeasyDEV : NSObject

/** 目标设备ip地址 */
@property (nonatomic,strong) NSString *host;
/** 控制端口（udp）*/
@property (nonatomic,assign) int ctrlPort;
@property (nonatomic,assign) int cmdPort;

- (void)startDev;

- (void)stopDev;

- (void)connectToSocket:(BOOL)isON;

- (void)disconnectSocket;

- (void)sendCtrlData:(NSData *)data;

@end


