//
//  NSString+HHFormat.h
//  Hohem Pro
//
//  Created by Jolly on 2021/2/23.
//  Copyright © 2021 jolly. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (HHFormat)

/**
 去除首位多余字符
 */
+ (NSString *)getCorrectStr:(NSString *)targetStr preStr:(NSString *)preStr;

/**
 补位为固定长度字符串
 */
+ (NSString *)getFixedLengthStr:(NSString *)targetStr fillStr:(NSString *)fillStr length:(NSInteger)length;

@end

NS_ASSUME_NONNULL_END
