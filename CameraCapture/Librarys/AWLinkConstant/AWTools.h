//
//  AWTools.h
//  MR100AerialPhotography
//
//  Created by xzw on 17/8/21.
//  Copyright © 2017年 AllWinner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AWTools : NSObject

//内存容量转换成文字显示
+ (NSString *)sizeToString:(unsigned long long)freeSpace;

//三个字节三个字节倒叙排列  113454->543411
+(void)swap24:(NSData *)data;

//当前设备可用内存(单位：MB)
+(NSString*)availableMemory;

//cpu占有率
+(float)cpu_usage;

//获取wifi路由器ip
+(NSString *)routerIp;

//获取wifi ip
+(NSString *)getIPAddress;

//字符串转字典
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

//将内容写入文件
+ (void)writefile:(NSData *)data;

@end
