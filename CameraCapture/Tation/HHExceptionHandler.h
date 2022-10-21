//
//  HohemCrashManager.h
//  Hohem Pro
//
//  Created by jolly on 2020/4/3.
//  Copyright © 2020 jolly. All rights reserved.
//  异常处理

#import <Foundation/Foundation.h>

#define HH_kSharedExceptionHandler [HHExceptionHandler sharedExceptionHandler]
#define HH_kNotificationException @"HH_kNotificationException"

NS_ASSUME_NONNULL_BEGIN

@interface HHExceptionHandler : NSObject

@property (nonatomic, assign) BOOL isRecord;//当前录像中

+ (instancetype)sharedExceptionHandler;

@end

NS_ASSUME_NONNULL_END
