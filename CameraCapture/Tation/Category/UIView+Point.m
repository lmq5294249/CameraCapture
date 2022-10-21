//
//  UIView+Point.m
//  Hohem Pro
//
//  Created by Jolly on 2020/11/10.
//  Copyright © 2020 jolly. All rights reserved.
//

#import "UIView+Point.h"

@implementation UIView (Point)

//X轴中心点
- (CGFloat)getCenterX {
    
    return (CGRectGetMinX(self.frame) + CGRectGetMaxX(self.frame)) / 2;
}

//Y轴中心点
- (CGFloat)getCenterY {
    
    return (CGRectGetMinY(self.frame) + CGRectGetMaxY(self.frame)) / 2;
}

@end
