//
//  CameraSocketManager.h
//  NoviceGuideOperation
//
//  Created by 林漫钦 on 2022/9/1.
//

#import "MMTCPSocket.h"
#import <UIKit/UIKit.h>
#import "DataUtil.h"
#import "DeviceDataDelegate.h"
NS_ASSUME_NONNULL_BEGIN



@interface CameraSocketManager : MMTCPSocket

@property (nonatomic, weak) id<DeviceDataDelegate> delegate;

- (void)sendSetVideoFlipCmd:(NSInteger)flipValue mirrorFlag:(NSInteger)mirrorValue;
//拍照指令
- (void)sendTakePhotoCmd;
- (void)sendStartRecordVideoCmd;
- (void)sendStopRecordVideoCmd;
- (void)sendGetSDCardPhotoListCmd;
- (void)sendGetSDCardVideoListCmd;
- (void)sendDownloadSDCardPhotoCmd:(NSString *)fileName;
- (void)sendDownloadSDCardVideoCmd:(NSString *)fileName;
- (void)sendDeleteSDCardPhotoCmd:(NSString *)fileName;
- (void)sendDeleteSDCardVideoCmd:(NSString *)fileName;
- (void)sendStartPlaySDCardVideoCmd:(NSString *)fileName;
- (void)sendStopPlaySDCardVideoCmd;
- (void)sendSetupCameraSystemTimeCmd;
- (void)sendGetCameraSystemTimeCmd;
- (void)sendGetSDCardPhotoThumbListCmd:(NSArray *)array;
- (void)sendGetSDCardVideoThumbListCmd:(NSArray *)array;
//格式化SD卡请求
- (void)sendFormatSDCardCmd;
//设置相机wifi名字和密码
- (void)sendSetCameraWifiNameCmd:(NSString *)wifiName wifiPasswordKey:(NSString *)password;

@end

NS_ASSUME_NONNULL_END
