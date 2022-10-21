//
//  HohemBaseLabel.h
//  Hohem Pro
//
//  Created by jolly on 2020/6/30.
//  Copyright © 2020 jolly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HohemBaseLabelTextVertical) {
    
    HohemBaseLabelTextVertical_Normal = 0,
    HohemBaseLabelTextVertical_Up = 1,
    HohemBaseLabelTextVertical_Down = 2
};

@interface HohemBaseLabel : UILabel

@property (nonatomic, assign) HohemBaseLabelTextVertical verticalAlignment;//垂直摆放

- (void)setInsets:(UIEdgeInsets)insets;

@end

NS_ASSUME_NONNULL_END
