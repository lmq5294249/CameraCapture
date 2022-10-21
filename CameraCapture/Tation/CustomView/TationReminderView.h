//
//  TationReminderView.h
//  Hohem Pro
//
//  Created by jolly on 2020/4/12.
//  Copyright © 2020 jolly. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TationReminderView : UIView

@property (nonatomic, strong) void(^confirmBlock)(void);
@property (nonatomic, strong) void(^cancelBlock)(void);

- (instancetype)initWithTitle:(nullable NSString *)title message:(NSString *)message confirm:(nullable NSString *)confirm cancel:(nullable NSString *)cancel showCancel:(BOOL)showCancel confirmBlock:(nullable void(^)(void))confirmBlock cancelBlock:(nullable void(^)(void))cancelBlock;

@end

NS_ASSUME_NONNULL_END
