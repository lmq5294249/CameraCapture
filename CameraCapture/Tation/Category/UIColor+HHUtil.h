//
//  UIColor+HHUtil.h
//  Hohem Pro
//
//  Created by Jolly on 2020/11/3.
//  Copyright © 2020 jolly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (HHUtil)

// 十六进制字符串获取颜色
+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
