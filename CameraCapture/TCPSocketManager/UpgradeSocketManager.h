//
//  UpgradeSocketManager.h
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/14.
//

#import "MMTCPSocket.h"
#import "DataUtil.h"
#import "DeviceDataDelegate.h"


@interface UpgradeSocketManager : MMTCPSocket

@property (nonatomic, weak) id<DeviceDataDelegate> delegate;

- (void)sendGetCameraFirmwareInfoCmd;

- (void)sendUpgradeCameraFirmwareCmd;

- (void)sendCameraFirmwareFile:(NSString *)fileString;

@end

