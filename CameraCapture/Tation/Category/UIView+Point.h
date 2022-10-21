//
//  UIView+Point.h
//  Hohem Pro
//
//  Created by Jolly on 2020/11/10.
//  Copyright © 2020 jolly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Point)

//X轴中心点
- (CGFloat)getCenterX;
//Y轴中心点
- (CGFloat)getCenterY;

@end

NS_ASSUME_NONNULL_END
