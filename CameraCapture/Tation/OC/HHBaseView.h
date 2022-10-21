//
//  HHBaseView.h
//  Hohem Pro
//
//  Created by jolly on 2020/7/3.
//  Copyright © 2020 jolly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HHBaseView : UIView

- (void)initAttribute;
- (void)setUpUI;
- (void)updateOrientation:(UIInterfaceOrientation)interfaceOrientation angle:(CGFloat)angle;

@end

NS_ASSUME_NONNULL_END
