//
//  UILabel+TationLableSize.h
//  Hohem Pro
//
//  Created by jolly on 2020/5/12.
//  Copyright © 2020 jolly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UILabel (TationLableSize)

+ (CGFloat)getHeightByWidth:(CGFloat)width title:(NSString *)title font:(UIFont*)font;

+ (CGFloat)getWidthWithTitle:(NSString *)title font:(UIFont *)font;

@end

NS_ASSUME_NONNULL_END
