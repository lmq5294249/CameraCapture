//
//  TationToolManager+Authority.h
//  Hohem Pro
//
//  Created by Jolly on 2022/5/18.
//  Copyright © 2022 jolly. All rights reserved.
//  权限检测

#import "TationToolManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TationToolManager (Authority)

//检测摄像头权限
+ (void)checkCameraService:(void(^)(BOOL isOpen))block;
//检测麦克风权限
+ (void)checkMikeService:(void(^)(BOOL isOpen))block;
//检测相册权限
+ (void)checkAlbumService:(void(^)(BOOL isOpen))block;
//检测定位权限
+ (void)checkLocalitionService:(void(^)(BOOL isOpen))block;
//权限申请
+ (void)showAlertRequestAuthority:(nullable NSString *)title message:(NSString *)message agreeStr:(nullable NSString *)agreeStr agree:(nullable void(^)(void))agree cancelStr:(nullable NSString *)cancelStr cancel:(nullable void(^)(void))cancel;

@end

NS_ASSUME_NONNULL_END
