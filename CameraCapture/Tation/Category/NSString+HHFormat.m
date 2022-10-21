//
//  NSString+HHFormat.m
//  Hohem Pro
//
//  Created by Jolly on 2021/2/23.
//  Copyright © 2021 jolly. All rights reserved.
//

#import "NSString+HHFormat.h"

@implementation NSString (HHFormat)

/**
 去除首位多余字符
 */
+ (NSString *)getCorrectStr:(NSString *)targetStr preStr:(NSString *)preStr {
    
    while ([targetStr hasPrefix:preStr]) {
        
        targetStr = [targetStr substringFromIndex:1];
    }
    
    return targetStr;
}

/**
 补位为固定长度字符串
 */
+ (NSString *)getFixedLengthStr:(NSString *)targetStr fillStr:(NSString *)fillStr length:(NSInteger)length {
    
    if (targetStr.length >= length) return targetStr;
    
    NSMutableString *mtStr = [NSMutableString stringWithString:targetStr];
    while (mtStr.length < length) {
        
        [mtStr insertString:fillStr atIndex:0];
    }
    
    return mtStr.copy;
}

@end
