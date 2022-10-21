//
//  ZWTools.h
//  MR100AerialPhotography
//
//  Created by xzw on 2017/10/23.
//  Copyright © 2017年 AllWinner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZWTools : NSObject
//Toast消息提示框
+ (void)showToastWihtMessage:(NSString *)message;

//生成文件的MD5值
+(NSString*)getFileMD5WithPath:(NSString*)path;

@end
